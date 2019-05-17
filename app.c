#include "app.h"
#include <stdio.h>

BEGIN_C

static void shape(int x, int y, int w, int h) {
    printf("shape(%d,%d %dx%d)\n", x, y, w, h);
}

static void paint(int x, int y, int w, int h) {
    printf("[%06d] paint(%d,%d %dx%d)\n", gettid(), x, y, w, h);
}

static void input(input_event_t* e) {
    if (e->kind == INPUT_KEYBOARD && (e->flags & INPUT_KEYDOWN) && e->ch != 0) {
        if (32 <= e->ch && e->ch <= 127) { // otherwise %c or %lc debug output in Xcode gets confused
            printf("ch=%d 0x%04X '%c' key=%d 0x%02X ", e->ch, e->ch, e->ch, e->key, e->key);
        } else {
            printf("ch=%d 0x%04X key=%d 0x%02X ", e->ch, e->ch, e->key, e->key);
        }
        if (e->ch == 'f' || e->ch == 'F' || e->key == KEY_ESCAPE) {
            window_state.style ^= WINDOW_STYLE_FULLSCREEN;
        }
        if (e->ch == 'q' || e->ch == 'Q') {
            startup.quit();
        }
        if (e->ch == 'h' || e->ch == 'H') {
            window_state.style ^= WINDOW_STYLE_HIDDEN;
        }
        if (e->key == KEY_KEYPAD_CLEAR)   { printf("CLEAR \u2327 "); }
        if (e->key == KEY_KEYPAD_ENTER)   { printf("ENTER \u2324 "); }
        if (e->key == KEY_FORWARD_DELETE) { printf("DELETE \u2326 "); }
        if (e->key == KEY_SPACE)      { printf("\u2423 "); }
        if (e->key == KEY_TAB)        { printf("TAB \u21E5 "); }
        if (e->key == KEY_COMMAND)    { printf("\u2318 "); }
        if (e->key == KEY_RETURN)     { printf("RETURN \u23CE "); }
        if (e->key == KEY_DELETE)     { printf("BACKSPACE \u232B "); } // aka BACKSPACE
        if (e->key == KEY_ESCAPE)     { printf("\u238B "); }
        if (e->key == KEY_HOME)       { printf("\u21F1 "); }
        if (e->key == KEY_END)        { printf("\u21F2 "); }
        if (e->key == KEY_PAGE_UP)    { printf("\u21DE "); }
        if (e->key == KEY_PAGE_DOWN)  { printf("\u21DF "); }
        if (e->key == KEY_LEFT_ARROW)  { printf("\u2190 "); }
        if (e->key == KEY_UP_ARROW)    { printf("\u2191 "); }
        if (e->key == KEY_RIGHT_ARROW) { printf("\u2192 "); }
        if (e->key == KEY_DOWN_ARROW)  { printf("\u2193 "); }
        if (e->flags & INPUT_SHIFT)    { printf("SHIFT \u21E7 "); }
        if (e->flags & INPUT_ALT)      { printf("ALT "); }
        if (e->flags & INPUT_NUM)      { printf("NUM \u21ED "); }
        if (e->flags & INPUT_CAPS)     { printf("CAPS \u21EA "); }
        if (e->flags & INPUT_COMMAND)  { printf("COMMAND \uF8FF "); }
        if (e->flags & INPUT_CONTROL)  { printf("CONTROL \u2303 "); }
        if (e->flags & INPUT_OPTION)   { printf("OPTION \u2325 "); } // ATL == OPTION on Mac OSX keyboards
        printf("\n");
        if (e->flags & INPUT_SHIFT) {
            /* resize window */
            if (e->key == KEY_LEFT_ARROW)  { window_state.w--; }
            if (e->key == KEY_UP_ARROW)    { window_state.h--; }
            if (e->key == KEY_RIGHT_ARROW) { window_state.w++; }
            if (e->key == KEY_DOWN_ARROW)  { window_state.h++; }
        } else {
            /* move window */
            if (e->key == KEY_LEFT_ARROW)  { window_state.x--; }
            if (e->key == KEY_UP_ARROW)    { window_state.y++; }
            if (e->key == KEY_RIGHT_ARROW) { window_state.x++; }
            if (e->key == KEY_DOWN_ARROW)  { window_state.y--; }
        }
        startup.update();
    } else if (e->kind == INPUT_MOUSE_MOVE) {
//      printf("INPUT_MOUSE_MOVE %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_MOUSE_DRAG) {
        printf("INPUT_MOUSE_DRAG %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_MOUSE_DOWN) {
        printf("INPUT_MOUSE_DOWN %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_MOUSE_UP) {
        printf("INPUT_MOUSE_UP %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_MOUSE_DOUBLE_CLICK) {
        printf("INPUT_MOUSE_DOUBLE_CLICK %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_MOUSE_LONG_PRESS) {
        printf("INPUT_MOUSE_LONG_PRESS %.1f %.1f\n", e->x, e->y);
    } else if (e->kind == INPUT_TOUCH_PROXIMITY) {
        printf("INPUT_TOUCH_PROXIMITY %.1f %.1f\n", e->x, e->y);
    }
    if (e->momentum_phase != INPUT_MOMENTUM_PHASE_NONE) {
        // scrolling deltas should be accumulated between _BEGAN and _ENDED events in INPUT_SCROLL_WHEEL_POINTS or INPUT_SCROLL_WHEEL
        if (e->momentum_phase == INPUT_MOMENTUM_PHASE_BEGAN)      { printf("INPUT_MOMENTUM_PHASE_BEGAN\n"); }
        if (e->momentum_phase == INPUT_MOMENTUM_PHASE_STATIONARY) { printf("INPUT_MOMENTUM_PHASE_STATIONARY\n"); }
//      if (e->momentum_phase == INPUT_MOMENTUM_PHASE_CHANGED)    { printf("INPUT_MOMENTUM_PHASE_CHANGED\n"); }
        if (e->momentum_phase == INPUT_MOMENTUM_PHASE_ENDED)      { printf("INPUT_MOMENTUM_PHASE_ENDED\n"); }
        if (e->momentum_phase == INPUT_MOMENTUM_PHASE_CANCELLED)  { printf("INPUT_MOMENTUM_PHASE_CANCELLED\n"); }
        if (e->momentum_phase == INPUT_MOMENTUM_PHASE_MAYBEGIN)   { printf("INPUT_MOMENTUM_PHASE_MAYBEGIN\n"); }
    }
    if (e->pressure != 0 && e->pressure != 1) { printf("pressure=%.6f\n", e->pressure); }
}

static void timer() {
//  printf("[%06d] timer %.6f\n", gettid(), app.time);
//  app.redraw(0, 0, window_state.w, window_state.h);
}

static void later_callback(void* that, void* message) {
    printf("[%06d] later_callback %.6f %s\n", gettid(), app.time, message);
    startup.later(2.5, null, "in 2.5 seconds", later_callback);
}

static void prefs() {
    printf("preferences\n");
    startup.later(0.5, null, "in 0.5 seconds", later_callback);
}

static int exits() {
    printf("about to quit\n");
    return EXIT_SUCCESS; // exit status (because sysexits.h is no posix)
}

void init(int argc, const char* argv[]) {
//  window_state.style = WINDOW_STYLE_FULLSCREEN;
    window_state.min_w = 800;
    window_state.min_h = 600;
    app.timer_frequency = 60; // Hz
}

app_t app = {
    init,
    shape,
    paint,
    input,
    timer,
    prefs,
    exits,
};

END_C
