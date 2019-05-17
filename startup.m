#include "app.h"
#import  <Cocoa/Cocoa.h>
#include <mach/mach_time.h>

typedef struct shadow_copy_s {
    float mouse_x;
    float mouse_y;
    float mouse_z;
    int timer_frequency;
    window_state_t window_state;
} shadow_copy_t;

static shadow_copy_t shadow_copy;
window_state_t window_state;

@interface Window : NSWindow {
@public
    dispatch_source_t timer;
}
- (void) setTimer: (int) frequency;
+ (Window*) create;
@end

static bool state_diff(int mask) {
    return (shadow_copy.window_state.style & mask) != (window_state.style & mask);
}

static void toggle_fullscreen(NSWindow* window) {
    bool app_full_screen = (window_state.style & WINDOW_STYLE_FULLSCREEN) != 0;
    bool win_full_screen = (window.styleMask & NSWindowStyleMaskFullScreen) != 0;
    if (app_full_screen != win_full_screen) {
        dispatch_async(dispatch_get_main_queue(), ^{
            bool full_screen = (window_state.style & WINDOW_STYLE_FULLSCREEN) != 0;
            window.hidesOnDeactivate = full_screen;
            [window toggleFullScreen: null]; // must be on the next dispatch otherwise update_state will be called from inside itself
            if (full_screen) {
                NSApplication.sharedApplication.presentationOptions |= NSApplicationPresentationAutoHideMenuBar;
            }
            if (!full_screen) {
                const NSApplicationPresentationOptions clear = NSApplicationPresentationAutoHideMenuBar | NSApplicationPresentationHideMenuBar | NSApplicationPresentationFullScreen;
                NSApplication.sharedApplication.presentationOptions &= ~(clear);
            }
        });
    }
}

static void hide_application(NSWindow* window, bool hide) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (hide) { // OSX hiding individual windows confuses Dock.app
            [NSApplication.sharedApplication hide: window];
        } else {
            [NSApplication.sharedApplication unhide: window];
        }
    });
}

static double seconds_since_boot() {
    static mach_timebase_info_data_t tb;
    double t = (double)mach_absolute_time() / NSEC_PER_SEC;
    if (tb.denom == 0) {
        mach_timebase_info(&tb);
    }
    t = t * tb.numer / tb.denom;
    return t;
}

static double seconds_since_start() {
    static double start_time;
    double t = seconds_since_boot();
    if (start_time == 0) { start_time = t; }
    return t - start_time;
}

static void update_state(NSWindow* window) {
    if (state_diff(WINDOW_STYLE_FULLSCREEN)) {
        shadow_copy.window_state.style = window_state.style; // in case update_state will be called recursively
        toggle_fullscreen(window);
    }
    if (state_diff(WINDOW_STYLE_HIDDEN)) {
        shadow_copy.window_state.style = window_state.style; // in case update_state will be called recursively
        hide_application(window, (window_state.style & WINDOW_STYLE_HIDDEN) != 0);
    }
    shadow_copy.window_state.style = window_state.style;
    if (window_state.x != shadow_copy.window_state.x || window_state.y != shadow_copy.window_state.y || window_state.w != shadow_copy.window_state.w || window_state.h != shadow_copy.window_state.h) {
        window.contentSize = NSMakeSize(window_state.w, window_state.h);
        [window setFrame: NSMakeRect(window_state.x, window_state.y, window_state.w, window_state.h) display: true animate: true];
        shadow_copy.window_state.x = window_state.x;
        shadow_copy.window_state.y = window_state.y;
        shadow_copy.window_state.w = window_state.w;
        shadow_copy.window_state.h = window_state.h;
    }
    if (app.timer_frequency != shadow_copy.timer_frequency) {
        [(Window*)window setTimer: app.timer_frequency];
        shadow_copy.timer_frequency = app.timer_frequency;
    }
    app.time = seconds_since_start();
}

static void reshape(NSWindow* window) {
    NSRect frame = window.frame;
    // shape() still has previous window position and size in `app` when called
    app.shape(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    shadow_copy.window_state.x = window_state.x = frame.origin.x;
    shadow_copy.window_state.y = window_state.y = frame.origin.y;
    shadow_copy.window_state.w = window_state.w = frame.size.width;
    shadow_copy.window_state.h = window_state.h = frame.size.height;
}

static int translate_type_to_button_number(int buttonNumber) {
    int button = 0;
    switch (buttonNumber) {
        case NSEventTypeLeftMouseUp:
        case NSEventTypeLeftMouseDown:   button = INPUT_MOUSE_LEFT_BUTTON;  break;
        case NSEventTypeRightMouseUp:
        case NSEventTypeRightMouseDown:  button = INPUT_MOUSE_RIGHT_BUTTON; break;
        case NSEventTypeOtherMouseUp:
        case NSEventTypeOtherMouseDown:  button = INPUT_MOUSE_OTHER_BUTTON; break;
        case NSEventTypeScrollWheel:     button = INPUT_MOUSE_SCROLL_WHEEL; break;
        case NSEventTypeTabletProximity: button = INPUT_TOUCH_PROXIMITY;    break;
        default: break; /* nothing */
    }
    return button;
}

static int translate_modifier_flags(NSEvent* e) {
    NSEventModifierFlags mf = e.modifierFlags;
    int flags = 0;
    if (NSEventModifierFlagCapsLock & mf)   { flags |= INPUT_CAPS; }
    if (NSEventModifierFlagShift & mf)      { flags |= INPUT_SHIFT; }
    if (NSEventModifierFlagControl & mf)    { flags |= INPUT_CONTROL; }
    if (NSEventModifierFlagOption & mf)     { flags |= INPUT_OPTION; }
    if (NSEventModifierFlagCommand & mf)    { flags |= INPUT_COMMAND; }
    if (NSEventModifierFlagNumericPad & mf) { flags |= INPUT_NUM; }
    if (NSEventModifierFlagFunction & mf)   { flags |= INPUT_FN; }
    if (NSEventModifierFlagHelp & mf)       { flags |= INPUT_HELP; }
    if (e.isARepeat) { flags |= INPUT_REPEAT; }
    return flags;
}

static void fill_mouse_coordinates(input_event_t* ie) {
    ie->x = shadow_copy.mouse_x;
    ie->y = shadow_copy.mouse_y;
    ie->z = shadow_copy.mouse_z;
}

static void keyboad_input(NSWindow* window, NSEvent* e, int mask) {
    unichar ch = [[e charactersIgnoringModifiers] characterAtIndex:0]; // 16 bits
    input_event_t ie = {0};
    ie.kind = INPUT_KEYBOARD;
    ie.flags = mask | translate_modifier_flags(e);
    ie.ch = (int)ch;
    ie.key = (int)e.keyCode;
    fill_mouse_coordinates(&ie);
    app.input(&ie);
    update_state(window);
}

static void mouse_input(NSEvent* e, int kind) {
    input_event_t ie = {0};
    if (kind == INPUT_MOUSE_UP && e.clickCount == 2) {
        kind = INPUT_MOUSE_DOUBLE_CLICK; // instead(!) of INPUT_MOUSE_UP
    }
    ie.kind = kind;
    ie.x = shadow_copy.mouse_x = e.locationInWindow.x;
    ie.y = shadow_copy.mouse_y = e.locationInWindow.y;
    ie.pressure = shadow_copy.mouse_z = e.pressure;
    ie.button = translate_type_to_button_number((int)e.type);
    app.input(&ie);
}

static void mouse_scroll_wheel(NSEvent* e) {
    input_event_t ie = {0};
    ie.kind = e.hasPreciseScrollingDeltas ? INPUT_SCROLL_WHEEL_POINTS : INPUT_SCROLL_WHEEL;
    ie.scrolling_delta_x = e.scrollingDeltaX;
    ie.scrolling_delta_y = e.scrollingDeltaY;
    ie.scrolling_delta_z = e.deltaZ; // because scrollingDeltaZ is absent
    ie.button = 0;   // not a INPUT_MOUSE_SCROLL_WHEEL because that is up/dw/double click on scrollwheel
    ie.momentum_phase = e.momentumPhase;
    app.input(&ie);
}

@implementation Window : NSWindow

+ (Window*) create {
    bool full_screen = (window_state.style & WINDOW_STYLE_FULLSCREEN) != 0;
    int w = maximum(window_state.w, window_state.min_w);
    int h = maximum(window_state.h, window_state.min_h);
    NSRect r = full_screen ? NSScreen.mainScreen.frame : NSMakeRect(0, 0, w > 0 ? w : 640, h > 0 ? h : 480);
    NSWindowStyleMask sm = NSWindowStyleMaskBorderless|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|
                           NSWindowStyleMaskResizable|NSWindowStyleMaskFullSizeContentView|NSWindowStyleMaskTitled;
    Window* window = [Window.alloc initWithContentRect: r styleMask: sm backing: NSBackingStoreBuffered defer: full_screen];
    window.opaque = true;
    window.hidesOnDeactivate = full_screen;
//  window.acceptsMouseMovedEvents = true;
    window.ignoresMouseEvents = false;
    window.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    window.titlebarAppearsTransparent  = true;
    window.titleVisibility = NSWindowTitleHidden;
    window.movable = true;
//  window.contentView = null;
    if (window_state.min_w > 0 && window_state.min_h > 0) {
        window.contentMinSize = NSMakeSize(window_state.min_w, window_state.min_h);
    }
    if (window_state.max_w > 0 && window_state.max_h > 0) {
        window.contentMaxSize = NSMakeSize(window_state.max_w, window_state.max_h);
    }
    // not sure next two lines are absolutely necessary but leave it as insurance against future Apple changes:
    window.contentView.translatesAutoresizingMaskIntoConstraints = false;
    window.contentView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    NSRect frame = window.frame;
    window_state.x = frame.origin.x;
    window_state.y = frame.origin.y;
    window_state.w = frame.size.width;
    window_state.h = frame.size.height;
    if (full_screen) { toggle_fullscreen(window); }
    return window;
}

- (void) sendEvent: (NSEvent*) e {
    if (e.type == NSEventTypeScrollWheel) { mouse_scroll_wheel(e); }
    if (e.type == NSEventTypePressure)    { mouse_input(e, INPUT_PRESSURE); }
    update_state(self);
    [super sendEvent: e];
}

- (void) setTimer: (int) frequency {
    assert(frequency > 0);
    uint64_t nanoseconds = frequency == 0 ? 0 : NSEC_PER_SEC / frequency;
    if (timer != null) {
        dispatch_cancel(timer);
    }
    timer = nanoseconds > 0 ? dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue()) : null;
    if (timer != null) {
        dispatch_source_set_event_handler(timer, ^{
            if (app.timer != null) { app.timer(); }
        });
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, nanoseconds), nanoseconds, 0);
        dispatch_resume(timer);
    }
}

- (BOOL) canBecomeKeyWindow { return true; } // https://stackoverflow.com/questions/11622255/keydown-not-being-called
- (BOOL) canBecomeMainWindow { return true; }
- (void) close { [super close]; startup.quit(); }
//  calling super.keyDown will play a keyboar input refused sound
- (void) keyDown: (NSEvent*) e { keyboad_input(self, e, INPUT_KEYDOWN); }
- (void) keyUp: (NSEvent*) e { keyboad_input(self, e, INPUT_KEYUP); [super keyUp: e]; }
- (void) mouseDown: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_DOWN); [super mouseDown: e]; }
- (void) mouseUp: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_UP); [super mouseUp: e]; }
- (void) rightMouseDown: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_DOWN); [super rightMouseDown: e]; }
- (void) rightMouseUp: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_UP); [super rightMouseUp: e]; }
- (void) otherMouseDown: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_DOWN); [super otherMouseDown: e]; }
- (void) otherMouseUp: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_UP); [super otherMouseUp: e]; }
// mouse motion outside window is also captured on OSX:
- (void) mouseMoved: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_MOVE); [super mouseMoved: e]; }
- (void) mouseDragged: (NSEvent*) e { mouse_input(e, INPUT_MOUSE_DRAG); [super mouseDragged: e]; }

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    @public Window* window;
}
@end

@implementation AppDelegate : NSObject 

- (id) init {
    self = super.init;
    if (self != null) {
        window = Window.create;
        window.delegate = self;
    }
    return self;
}

- (void) applicationWillFinishLaunching:(NSNotification *)notification {
    window.title = NSProcessInfo.processInfo.processName;
    [window cascadeTopLeftFromPoint: NSMakePoint(20,20)];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification { [window makeKeyAndOrderFront: self]; }
- (void) preferences: (nullable id)sender { if (app.prefs != null) { app.prefs(); } }
- (void) hide: (nullable id)sender { hide_application(window, true); }
- (void) windowDidMove: (NSNotification*) n { reshape(window); }

- (void) windowDidResize: (NSNotification*) n {
    reshape(window);
}

- (void) applicationDidHide: (NSNotification*) n {
    window_state.style |= WINDOW_STYLE_HIDDEN;
    shadow_copy.window_state.style |= WINDOW_STYLE_HIDDEN;
    update_state(window);
}

- (void) applicationDidUnhide: (NSNotification*) n {
    window_state.style &= ~WINDOW_STYLE_HIDDEN;
    shadow_copy.window_state.style &= ~WINDOW_STYLE_HIDDEN;
    update_state(window);
}

- (void) applicationDidBecomeActive: (NSNotification*) n {
    window_state.style &= ~WINDOW_STYLE_HIDDEN;
    shadow_copy.window_state.style &= ~WINDOW_STYLE_HIDDEN;
    update_state(window);
    hide_application(window, false);
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication*) sender { return true; }
- (BOOL) acceptsFirstResponder { return true; } /* receive key events */

- (void) flagsChanged: (NSEvent*) e { keyboad_input(window, e, 0); [self flagsChanged: e]; }
- (void) updateState { update_state(window); }

@end

static void redraw(int x, int y, int w, int h) {
    AppDelegate* d = (AppDelegate*)NSApplication.sharedApplication.delegate;
    if (d->window != null) {
        d->window.contentView.needsDisplay = true;
        d->window.viewsNeedDisplay = true;
    }
}

static void quit() {
    [NSApplication.sharedApplication stop: NSApplication.sharedApplication];
}

static void* map_resource(const char* resource_name, int* size) {
    NSString* name = [NSString stringWithUTF8String: resource_name];
    NSString* path = [NSBundle.mainBundle pathForResource: name.stringByDeletingPathExtension ofType: name.pathExtension];
    void* a = null;
    if (path != null) {
        int fd = open(path.UTF8String, O_RDONLY);
        if (fd > 0) {
            struct stat s = {0};
            if (fstat(fd, &s) == 0) {
                a = mmap(0, s.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
                if (a != null) {
                    *size = (int)s.st_size;
                }
            }
            close(fd);
        }
        return a;
    }
    return null;
}

static void unmap_resource(void* a, int size) {
    munmap(a, size);
}

static void update() {
    [(AppDelegate*)NSApplication.sharedApplication.delegate updateState];
}

static void later(double seconds, void* that, void* message, void (*callback)(void* _that, void* _message)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        update();
        callback(that, message);
    });
}

startup_t startup = {
    quit,
    later,
    redraw,
    map_resource,
    unmap_resource,
    update
};

static void menu_add_item(NSMenu* submenu, NSString* title, SEL callback, NSString* key) {
    [submenu addItem: [NSMenuItem.alloc initWithTitle: title action: callback keyEquivalent: key]];
}

int main(int argc, const char* argv[]) {
    seconds_since_start(); // to initialize start_time
    app.init(argc, argv);
    NSApplication* a = NSApplication.sharedApplication;
    a.activationPolicy = NSApplicationActivationPolicyRegular;
    NSMenuItem* i = NSMenuItem.new;
    i.submenu = NSMenu.new;
    i.submenu.autoenablesItems = false;
    NSString* quit = [@"Quit " stringByAppendingString: NSProcessInfo.processInfo.processName];
    menu_add_item(i.submenu, @"Preferences...", @selector(preferences:), @",");
    menu_add_item(i.submenu, @"Hide", @selector(hide:), @"h");
    menu_add_item(i.submenu, @"Enter Full Screen", @selector(toggleFullScreen:), @"f");
    menu_add_item(i.submenu, quit, @selector(stop:), @"q");
    a.mainMenu = NSMenu.new;
    [a.mainMenu addItem: i];
    a.delegate = AppDelegate.new;
    [a run]; // event dispatch loop
    int exit_status = app.exits != null ? app.exits() : 0;
    return exit_status;
}
