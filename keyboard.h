#pragma once

/* keycodes for keys that are independent of keyboard layout (for OSX) */
enum {
    KEY_RETURN                    = 0x24,
    KEY_TAB                       = 0x30,
    KEY_SPACE                     = 0x31,
    KEY_DELETE                    = 0x33,
    KEY_ESCAPE                    = 0x35,
    KEY_COMMAND                   = 0x37,
    KEY_SHIFT                     = 0x38,
    KEY_CAPSLOCK                  = 0x39,
    KEY_OPTION                    = 0x3A,
    KEY_CONTROL                   = 0x3B,
    KEY_RIGHT_SHIFT               = 0x3C,
    KEY_RIGHT_OPTION              = 0x3D,
    KEY_RIGHT_CONTROL             = 0x3E,
    KEY_FUNCTION                  = 0x3F,
    KEY_F17                       = 0x40,
    KEY_VOLUME_UP                 = 0x48,
    KEY_VOLUME_DOWN               = 0x49,
    KEY_MUTE                      = 0x4A,
    KEY_F18                       = 0x4F,
    KEY_F19                       = 0x50,
    KEY_F20                       = 0x5A,
    KEY_F5                        = 0x60,
    KEY_F6                        = 0x61,
    KEY_F7                        = 0x62,
    KEY_F3                        = 0x63,
    KEY_F8                        = 0x64,
    KEY_F9                        = 0x65,
    KEY_F11                       = 0x67,
    KEY_F13                       = 0x69,
    KEY_F16                       = 0x6A,
    KEY_F14                       = 0x6B,
    KEY_F10                       = 0x6D,
    KEY_F12                       = 0x6F,
    KEY_F15                       = 0x71,
    KEY_HELP                      = 0x72,
    KEY_HOME                      = 0x73,
    KEY_PAGE_UP                   = 0x74,
    KEY_FORWARD_DELETE            = 0x75,
    KEY_F4                        = 0x76,
    KEY_END                       = 0x77,
    KEY_F2                        = 0x78,
    KEY_PAGE_DOWN                 = 0x79,
    KEY_F1                        = 0x7A,
    KEY_LEFT_ARROW                = 0x7B,
    KEY_RIGHT_ARROW               = 0x7C,
    KEY_DOWN_ARROW                = 0x7D,
    KEY_UP_ARROW                  = 0x7E
};

enum { /* ANSI keyboard */
    KEY_KEYPAD_DECIMAL       = 0x41,
    KEY_KEYPAD_MULTIPLY      = 0x43,
    KEY_KEYPAD_PLUS          = 0x45,
    KEY_KEYPAD_CLEAR         = 0x47,
    KEY_KEYPAD_DIVIDE        = 0x4B,
    KEY_KEYPAD_ENTER         = 0x4C,
    KEY_KEYPAD_MINUS         = 0x4E,
    KEY_KEYPAD_EQUALS        = 0x51,
    KEY_KEYPAD0              = 0x52,
    KEY_KEYPAD1              = 0x53,
    KEY_KEYPAD2              = 0x54,
    KEY_KEYPAD3              = 0x55,
    KEY_KEYPAD4              = 0x56,
    KEY_KEYPAD5              = 0x57,
    KEY_KEYPAD6              = 0x58,
    KEY_KEYPAD7              = 0x59,
    KEY_KEYPAD8              = 0x5B,
    KEY_KEYPAD9              = 0x5C
};

/*
                    Mac	Windows	Linux
KeyUp               126	26	103
KeyDown             125	28	108
KeyLeft             123	25	105
KeyRight            124	27	106
KeyBackspace        117	8	14
KeyEnter            76	*	28
KeyHome             115	36	102
KeyEnd              119	35	107
KeyPageDown         121	34	109
KeyPageUp           116	33	104
KeyReturn           36	13	*
KeyDelete           51	46	111
KeyTab              48	9	15
KeySpacebar         49	20	57
KeyShift            56	10	*
KeyControl          59	11	*
KeyMenu             58	18	139	The Alt key
KeyPrintScreen      *	42	210
KeyEscape           53	27	1
KeyCapsLock         57	20	58
KeyHelp             114	47	138
KeyF1               122	112	59
KeyF2               120	113	60
KeyF3               99	114	61
KeyF4               118	115	62
KeyF5               96	116	63
KeyF6               97	117	64
KeyF7               98	118	65
KeyF8               100	119	66
KeyF9               101	120	67
KeyF10              109	121	68
KeyF11              103	122	87
KeyF12              111	123	88
KeyMacFn            63	*	*
KeyMacOption        58	*	*
KeyMacCommand       55	*	*
KeyWinLeftWindow	*	91	*	On "Natural" keyboards
KeyWinRightWindow	*	92	*	On "Natural" keyboards
KeyWinApplication	110	93	*	On "Natural" keyboards
KeyNum0             82	96	82	On numeric keypad or with NumLock
KeyNum1             83	97	79
KeyNum2             84	98	80
KeyNum3             85	99	81
KeyNum4             86	100	75
KeyNum5             87	101	76
KeyNum6             88	102	77
KeyNum7             89	103	71
KeyNum8             91	104	72
KeyNum9             92	105	73
KeyMultiply         67	106	55
KeyAdd              69	107	78
KeySubtract         78	109	74
KeyDivide           75	111	98
KeyDecimal          65	110	83
KeyNumEqual         81	*	117
*/
