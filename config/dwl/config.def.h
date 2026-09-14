// clangd: off
/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int smartgaps = 0;
static const unsigned int gappih = 4, gappiv = 4, gappoh = 4, gappov = 4;
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int systrayspacing   = 2; /* systray spacing */
static const int showsystray               = 1; /* 0 means no systray */
static const char *icon_theme              = "Papirus-Dark";
static const int showbar                   = 1; /* 0 means no bar */
static const int topbar                    = 1; /* 0 means bottom bar */
static const char *fonts[]                 = {"Iosevka Nerd Font Propo:size=12"};
static const float rootcolor[]             = COLOR(0x131210ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xbbb3a9ff, 0x131210ff, 0x58534cff },
	[SchemeSel]  = { 0xe17a3fff, 0x131210ff, 0xe17a3fff },
	[SchemeUrg]  = { 0xddd5caff, 0xb34a45ff, 0xb34a45ff },
};

/* tagging */
static char *tags[] = { "1", "2", "3", "4", "5", "6", "7" };

/* logging */
static int log_level = WLR_ERROR;

static const unsigned int truncate_icons_after = 3;
static const char *default_appicon = "";

static const char *const autostart[] = { "/bin/sh", "-c", "exec \"${XDG_CONFIG_HOME:-$HOME/.config}/dwl/autostart.sh\"", NULL, NULL };

static const Rule rules[] = {
	/* app_id, title, tags, floating, monitor, icon */
	{ "org.wezfurlong.wezterm", NULL, 0, 0, -1, "" },
	{ "zen", NULL, 0, 0, -1, "󰖟" },
	{ "firefox", NULL, 0, 0, -1, "󰈹" },
	{ "emacs", NULL, 0, 0, -1, "" },
	{ "Emacs", NULL, 0, 0, -1, "" },
	{ "signal", NULL, 0, 0, -1, "󰭹" },
	{ "mpv", NULL, 0, 0, -1, "" },
	{ "imv", NULL, 0, 1, -1, "" },
	{ "Qalculate-gtk", NULL, 0, 1, -1, "" },
	{ "Blueman", NULL, 0, 1, -1, "" },
	{ "blueman", NULL, 0, 1, -1, "" },
	{ "Bitwarden", NULL, 0, 1, -1, "󰌾" },
	{ "bitwarden", NULL, 0, 1, -1, "󰌾" },
	{ "LocalSend", NULL, 0, 1, -1, "" },
	{ "localsend", NULL, 0, 1, -1, "" },
	{ "localSend", NULL, 0, 1, -1, "" },
	{ "Localsend", NULL, 0, 1, -1, "" },
	{ "polkit-gnome", NULL, 0, 1, -1, "󰒃" },
	{ "Polkit-gnome", NULL, 0, 1, -1, "󰒃" },
	{ "xdg-desktop-portal-gtk", NULL, 0, 1, -1, NULL },
	{ "nm-connection-editor", NULL, 0, 1, -1, "󰈀" },
	{ "Nm-connection-editor", NULL, 0, 1, -1, "󰈀" },
};

/* monitors */
/* (x=-1, y=-1) is reserved as an "autoconfigure" monitor position indicator
 * WARNING: negative values other than (-1, -1) cause problems with Xwayland clients due to
 * https://gitlab.freedesktop.org/xorg/xserver/-/issues/899 */
static const MonitorRule monrules[] = {
   /* name        mfact  nmaster scale rotate/reflect                x    y
    * example of a HiDPI laptop monitor:
    { "eDP-1",    0.5f,  1,      2,    WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 }, */
	{ NULL,       0.50f, 1,      1,    WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* default monitor rule: can be changed but cannot be eliminated; at least one monitor rule must exist */
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example: .options = "ctrl:nocaps", */
	.layout = "aileks",
	.options = NULL,
};

static const int repeat_rate = 50;
static const int repeat_delay = 250;

/* Trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
/* You can choose between:
LIBINPUT_CONFIG_SCROLL_NO_SCROLL
LIBINPUT_CONFIG_SCROLL_2FG
LIBINPUT_CONFIG_SCROLL_EDGE
LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN
*/
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;

/* You can choose between:
LIBINPUT_CONFIG_CLICK_METHOD_NONE
LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS
LIBINPUT_CONFIG_CLICK_METHOD_CLICKFINGER
*/
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;

/* You can choose between:
LIBINPUT_CONFIG_SEND_EVENTS_ENABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED
LIBINPUT_CONFIG_SEND_EVENTS_DISABLED_ON_EXTERNAL_MOUSE
*/
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;

/* You can choose between:
LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE
LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT
*/
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_FLAT;
static const double accel_speed = 0.0;

/* You can choose between:
LIBINPUT_CONFIG_TAP_MAP_LRM -- 1/2/3 finger tap maps to left/right/middle
LIBINPUT_CONFIG_TAP_MAP_LMR -- 1/2/3 finger tap maps to left/middle/right
*/
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* Super */
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

#define CMD(...) { .v = (const char *[]){ __VA_ARGS__, NULL } }

static const char *dmenucmd[] = { "rofi", "-dmenu", "-i", "-no-custom", "-format", "i", "-p", "Tray", NULL };

static const Key keys[] = {
	{ MODKEY, XKB_KEY_Return, spawn, CMD("wezterm", "connect", "unix") },
	{ MODKEY, XKB_KEY_space, spawn, CMD("rofi", "-show", "drun") },
	{ MODKEY, XKB_KEY_x, spawn, CMD("emacsclient", "-c", "-a", "") },
	{ MODKEY, XKB_KEY_t, spawn, CMD("wezterm-sessions") },
	{ MODKEY, XKB_KEY_w, spawn, CMD("zen-browser") },
	{ MODKEY, XKB_KEY_e, spawn, CMD("wezterm", "start", "--always-new-process", "--", "yazi") },
	{ MODKEY, XKB_KEY_s, spawn, CMD("signal-desktop") },
	{ MODKEY, XKB_KEY_a, spawn, CMD("wezterm", "start", "--always-new-process", "--", "wiremix") },
	{ MODKEY, XKB_KEY_o, spawn, CMD("color-picker") },
	{ MODKEY, XKB_KEY_v, spawn, CMD("clipboard-menu") },
	{ MODKEY, XKB_KEY_semicolon, spawn, CMD("bemoji", "-n") },
	{ MODKEY, XKB_KEY_Escape, spawn, CMD("lock-session") },
	{ MODKEY, XKB_KEY_n, spawn, CMD("dnd-toggle") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_n, spawn, CMD("night-light") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_p, spawn, CMD("power-menu") },
	{ MODKEY, XKB_KEY_r, spawninfo, CMD("screenrecord", "menu") },
	{ 0, XKB_KEY_Print, spawninfo, CMD("screenshot", "region") },
	{ WLR_MODIFIER_CTRL, XKB_KEY_Print, spawninfo, CMD("screenshot", "window") },
	{ WLR_MODIFIER_SHIFT, XKB_KEY_Print, spawninfo, CMD("screenshot", "full") },
	{ MODKEY, XKB_KEY_Print, spawninfo, CMD("screenrecord", "region") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Print, spawninfo, CMD("screenrecord", "output") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_space, spawn, CMD("desktop-actions") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_o, spawn, CMD("region-ocr") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_o, spawn, CMD("qr-scan") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_r, spawn, CMD("reminder") },
	{ MODKEY, XKB_KEY_equal, spawn, CMD("calculate") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_n, spawn, CMD("notification-history") },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_n, spawn, CMD("dunstctl", "context") },
	{ 0, XKB_KEY_XF86AudioPlay, spawn, CMD("playerctl", "play-pause") },
	{ 0, XKB_KEY_XF86AudioPause, spawn, CMD("playerctl", "play-pause") },
	{ 0, XKB_KEY_XF86AudioNext, spawn, CMD("playerctl", "next") },
	{ 0, XKB_KEY_XF86AudioPrev, spawn, CMD("playerctl", "previous") },
	{ 0, XKB_KEY_XF86AudioRaiseVolume, spawn, CMD("audio", "sink", "up") },
	{ 0, XKB_KEY_XF86AudioLowerVolume, spawn, CMD("audio", "sink", "down") },
	{ 0, XKB_KEY_XF86AudioMute, spawn, CMD("audio", "sink", "mute") },
	{ 0, XKB_KEY_XF86MonBrightnessUp, spawn, CMD("brightness", "up") },
	{ 0, XKB_KEY_XF86MonBrightnessDown, spawn, CMD("brightness", "down") },
	{ MODKEY, XKB_KEY_q, killclient, {0} },
	{ MODKEY, XKB_KEY_f, togglefullscreen, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_space, togglefloating, {0} },
	{ MODKEY, XKB_KEY_j, focusstack, {.i = 1} },
	{ MODKEY, XKB_KEY_k, focusstack, {.i = -1} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_j, movestack, {.i = 1} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_k, movestack, {.i = -1} },
	{ MODKEY, XKB_KEY_h, setmfact, {.f = -0.05f} },
	{ MODKEY, XKB_KEY_l, setmfact, {.f = 0.05f} },
	{ MODKEY, XKB_KEY_i, incnmaster, {.i = 1} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_i, incnmaster, {.i = -1} },
	{ MODKEY, XKB_KEY_comma, focusmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY, XKB_KEY_period, focusmon, {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_less, tagmon, {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_greater, tagmon, {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_q, quit, {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_r, quit, {.i = 1} },
	{ MODKEY, XKB_KEY_b, togglebar, {0} },
	{ MODKEY|WLR_MODIFIER_ALT, XKB_KEY_0, togglegaps, {0} },
	TAGKEYS(XKB_KEY_1, XKB_KEY_exclam, 0),
	TAGKEYS(XKB_KEY_2, XKB_KEY_at, 1),
	TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign, 2),
	TAGKEYS(XKB_KEY_4, XKB_KEY_dollar, 3),
	TAGKEYS(XKB_KEY_5, XKB_KEY_percent, 4),
	TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum, 5),
	TAGKEYS(XKB_KEY_7, XKB_KEY_ampersand, 6),
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT, XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6), CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ ClkTitle,    0,      BTN_MIDDLE, zoom,           {0} },
	{ ClkClient,   MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ ClkClient,   MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ ClkClient,   MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
	{ ClkTagBar,   0,      BTN_LEFT,   view,           {0} },
	{ ClkTagBar,   0,      BTN_RIGHT,  toggleview,     {0} },
	{ ClkTagBar,   MODKEY, BTN_LEFT,   tag,            {0} },
	{ ClkTagBar,   MODKEY, BTN_RIGHT,  toggletag,      {0} },
	{ ClkTray,     0,      BTN_LEFT,   trayactivate,   {0} },
	{ ClkTray,     0,      BTN_RIGHT,  traymenu,       {0} },
};
