/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }
/* appearance */
static const int smartgaps = 0, monoclegaps = 1;
static const unsigned int gappih = 4, gappiv = 4, gappoh = 4, gappov = 4;
static const int sloppyfocus               = 1;  /* focus follows mouse */
static const int bypass_surface_visibility = 0;  /* 1 means idle inhibitors will disable idle tracking even if it's surface isn't visible  */
static const unsigned int borderpx         = 2;  /* border pixel of windows */
static const unsigned int systrayspacing   = 2; /* systray spacing */
static const int showsystray               = 1; /* 0 means no systray */
static const int showbar                   = 1; /* 0 means no bar */
static const int topbar                    = 1; /* 0 means bottom bar */
static const char *fonts[]                 = {"Iosevka Nerd Font Propo:size=11"};
static const float rootcolor[]             = COLOR(0x131210ff);
/* This conforms to the xdg-protocol. Set the alpha to zero to restore the old behavior */
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f}; /* You can also use glsl colors */
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xbbb3a9ff, 0x131210ff, 0x58534cff },
	[SchemeSel]  = { 0xe17a3fff, 0x131210ff, 0xe17a3fff },
	[SchemeUrg]  = { 0xddd5caff, 0xb34a45ff, 0xb34a45ff },
};

enum { LAYOUT };
static const char *modes_labels[] = { "layout: [t]ile [f]loat [m]onocle [Esc]cancel" };

/* tagging */
static char *tags[] = { "1", "2", "3", "4", "5", "6", "7" };

/* logging */
static int log_level = WLR_ERROR;

static const unsigned int truncate_icons_after = 3;

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
	{ "imv", NULL, 0, 1, -1, NULL },
	{ "Qalculate-gtk", NULL, 0, 1, -1, NULL },
	{ "Blueman", NULL, 0, 1, -1, NULL },
	{ "blueman", NULL, 0, 1, -1, NULL },
	{ "Bitwarden", NULL, 0, 1, -1, NULL },
	{ "bitwarden", NULL, 0, 1, -1, NULL },
	{ "LocalSend", NULL, 0, 1, -1, NULL },
	{ "localsend", NULL, 0, 1, -1, NULL },
	{ "localSend", NULL, 0, 1, -1, NULL },
	{ "Localsend", NULL, 0, 1, -1, NULL },
	{ "polkit-gnome", NULL, 0, 1, -1, NULL },
	{ "Polkit-gnome", NULL, 0, 1, -1, NULL },
	{ "xdg-desktop-portal-gtk", NULL, 0, 1, -1, NULL },
	{ "nm-connection-editor", NULL, 0, 1, -1, NULL },
	{ "Nm-connection-editor", NULL, 0, 1, -1, NULL },
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* monitors */
/* (x=-1, y=-1) is reserved as an "autoconfigure" monitor position indicator
 * WARNING: negative values other than (-1, -1) cause problems with Xwayland clients due to
 * https://gitlab.freedesktop.org/xorg/xserver/-/issues/899 */
static const MonitorRule monrules[] = {
   /* name        mfact  nmaster scale layout       rotate/reflect                x    y
    * example of a HiDPI laptop monitor:
    { "eDP-1",    0.5f,  1,      2,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 }, */
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
	/* default monitor rule: can be changed but cannot be eliminated; at least one monitor rule must exist */
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	/* can specify fields: rules, model, layout, variant, options */
	/* example:
	.options = "ctrl:nocaps",
	*/
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

/* Super, matching the oxwm bindings. */
#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static const char *dmenucmd[] = { "rofi", "-dmenu", "-i", "-p", "Tray", NULL };

static const Key keys[] = {
	{ MODKEY, XKB_KEY_Return, spawn, SHCMD("wezterm connect unix") },
	{ MODKEY, XKB_KEY_space, spawn, SHCMD("rofi -show drun") },
	{ MODKEY, XKB_KEY_x, spawn, SHCMD("emacsclient -c -a ''") },
	{ MODKEY, XKB_KEY_t, spawn, SHCMD("wezterm-sessions") },
	{ MODKEY, XKB_KEY_w, spawn, SHCMD("zen-browser") },
	{ MODKEY, XKB_KEY_e, spawn, SHCMD("wezterm start --always-new-process -- yazi") },
	{ MODKEY, XKB_KEY_s, spawn, SHCMD("signal-desktop") },
	{ MODKEY, XKB_KEY_a, spawn, SHCMD("wezterm start --always-new-process -- wiremix") },
	{ MODKEY, XKB_KEY_o, spawn, SHCMD("color-picker") },
	{ MODKEY, XKB_KEY_v, spawn, SHCMD("clipboard-menu") },
	{ MODKEY, XKB_KEY_semicolon, spawn, SHCMD("bemoji -n") },
	{ MODKEY, XKB_KEY_Escape, spawn, SHCMD("lock-session") },
	{ MODKEY, XKB_KEY_n, spawn, SHCMD("dnd-toggle") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_n, spawn, SHCMD("night-light") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_p, spawn, SHCMD("power-menu") },
	{ MODKEY, XKB_KEY_r, spawninfo, SHCMD("screenrecord menu") },
	{ 0, XKB_KEY_Print, spawninfo, SHCMD("screenshot region") },
	{ WLR_MODIFIER_CTRL, XKB_KEY_Print, spawninfo, SHCMD("screenshot window") },
	{ WLR_MODIFIER_SHIFT, XKB_KEY_Print, spawninfo, SHCMD("screenshot full") },
	{ MODKEY, XKB_KEY_Print, spawninfo, SHCMD("screenrecord region") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Print, spawninfo, SHCMD("screenrecord output") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_space, spawn, SHCMD("desktop-actions") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_o, spawn, SHCMD("region-ocr") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_o, spawn, SHCMD("qr-scan") },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_r, spawn, SHCMD("reminder") },
	{ MODKEY, XKB_KEY_equal, spawn, SHCMD("calculate") },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_n, spawn, SHCMD("notification-history") },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_n, spawn, SHCMD("dunstctl context") },
	{ 0, XKB_KEY_XF86AudioPlay, spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioPause, spawn, SHCMD("playerctl play-pause") },
	{ 0, XKB_KEY_XF86AudioNext, spawn, SHCMD("playerctl next") },
	{ 0, XKB_KEY_XF86AudioPrev, spawn, SHCMD("playerctl previous") },
	{ 0, XKB_KEY_XF86AudioRaiseVolume, spawn, SHCMD("audio sink up") },
	{ 0, XKB_KEY_XF86AudioLowerVolume, spawn, SHCMD("audio sink down") },
	{ 0, XKB_KEY_XF86AudioMute, spawn, SHCMD("audio sink mute") },
	{ 0, XKB_KEY_XF86MonBrightnessUp, spawn, SHCMD("brightness up") },
	{ 0, XKB_KEY_XF86MonBrightnessDown, spawn, SHCMD("brightness down") },
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
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_t, setlayout, {.v = &layouts[0]} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_f, setlayout, {.v = &layouts[1]} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_m, setlayout, {.v = &layouts[2]} },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_period, nextlayout, {0} },
	{ MODKEY|WLR_MODIFIER_CTRL, XKB_KEY_m, entermode, {.i = LAYOUT} },
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

static const Modekey modekeys[] = {
	{ LAYOUT, { 0, XKB_KEY_t, setlayout, {.v = &layouts[0]} } },
	{ LAYOUT, { 0, XKB_KEY_t, entermode, {.i = NORMAL} } },
	{ LAYOUT, { 0, XKB_KEY_f, setlayout, {.v = &layouts[1]} } },
	{ LAYOUT, { 0, XKB_KEY_f, entermode, {.i = NORMAL} } },
	{ LAYOUT, { 0, XKB_KEY_m, setlayout, {.v = &layouts[2]} } },
	{ LAYOUT, { 0, XKB_KEY_m, entermode, {.i = NORMAL} } },
	{ LAYOUT, { 0, XKB_KEY_Escape, entermode, {.i = NORMAL} } },
	{ LAYOUT, { MODKEY, XKB_KEY_Escape, spawn, SHCMD("lock-session") } },
};

static const Button buttons[] = {
	{ ClkLtSymbol, 0,      BTN_LEFT,   setlayout,      {.v = &layouts[0]} },
	{ ClkLtSymbol, 0,      BTN_RIGHT,  setlayout,      {.v = &layouts[2]} },
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
