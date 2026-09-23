/* See LICENSE file for copyright and license details. */

// clang-format off
#include <X11/XF86keysym.h>

/* Helper macros for spawning commands */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define CMD(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

/* appearance */
static const unsigned int borderpx       = 2;   /* border pixel of windows */
static const unsigned int snap           = 32;  /* snap pixel */
static const int swallowfloating         = 0;   /* 1 means swallow floating windows by default */
static const unsigned int gappih         = 6;   /* horiz inner gap between windows */
static const unsigned int gappiv         = 6;   /* vert inner gap between windows */
static const unsigned int gappoh         = 12;  /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 12;  /* vert outer gap between windows and screen edge */
static const int smartgaps_fact          = 1;   /* gap factor when there is only one client; 0 = no gaps, 3 = 3x outer gaps */
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".local/share";
static const int showbar                 = 1;   /* 0 means no bar */
static const int topbar                  = 1;   /* 0 means bottom bar */
#define ICONSIZE 20    /* icon size */
#define ICONSPACING 5  /* space between icon and title */
/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
static const int statusmon               = 'A';
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int showsystray             = 1;   /* 0 means no systray */

/* Indicators: see patch/bar_indicators.h for options */
static int tagindicatortype              = INDICATOR_TOP_LEFT_SQUARE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;
static const char *fonts[]               = { "Iosevka Nerd Font Propo:style=Medium:size=10" };

static char c000000[]                    = "#000000"; // placeholder value

static char normfgcolor[]                = "#E9D1C5";
static char normbgcolor[]                = "#15110F";
static char normbordercolor[]            = "#5F5049";
static char normfloatcolor[]             = "#5F5049";

static char selfgcolor[]                 = "#F1A278";
static char selbgcolor[]                 = "#15110F";
static char selbordercolor[]             = "#F1A278";
static char selfloatcolor[]              = "#F1A278";

static char titlenormfgcolor[]           = "#5F5049";
static char titlenormbgcolor[]           = "#15110F";
static char titlenormbordercolor[]       = "#5F5049";
static char titlenormfloatcolor[]        = "#5F5049";

static char titleselfgcolor[]            = "#E9D1C5";
static char titleselbgcolor[]            = "#15110F";
static char titleselbordercolor[]        = "#F1A278";
static char titleselfloatcolor[]         = "#F1A278";

static char tagsnormfgcolor[]            = "#E9D1C5";
static char tagsnormbgcolor[]            = "#15110F";
static char tagsnormbordercolor[]        = "#5F5049";
static char tagsnormfloatcolor[]         = "#5F5049";

static char tagsselfgcolor[]             = "#F1A278";
static char tagsselbgcolor[]             = "#15110F";
static char tagsselbordercolor[]         = "#F1A278";
static char tagsselfloatcolor[]          = "#F1A278";

static char hidnormfgcolor[]             = "#5F5049";
static char hidselfgcolor[]              = "#F1A278";
static char hidnormbgcolor[]             = "#15110F";
static char hidselbgcolor[]              = "#15110F";

static char urgfgcolor[]                 = "#E9D1C5";
static char urgbgcolor[]                 = "#A45751";
static char urgbordercolor[]             = "#A45751";
static char urgfloatcolor[]              = "#A45751";

static char *colors[][ColCount] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { normfgcolor,      normbgcolor,      normbordercolor,      normfloatcolor },
	[SchemeSel]          = { selfgcolor,       selbgcolor,       selbordercolor,       selfloatcolor },
	[SchemeTitleNorm]    = { titlenormfgcolor, titlenormbgcolor, titlenormbordercolor, titlenormfloatcolor },
	[SchemeTitleSel]     = { titleselfgcolor,  titleselbgcolor,  titleselbordercolor,  titleselfloatcolor },
	[SchemeTagsNorm]     = { tagsnormfgcolor,  tagsnormbgcolor,  tagsnormbordercolor,  tagsnormfloatcolor },
	[SchemeTagsSel]      = { tagsselfgcolor,   tagsselbgcolor,   tagsselbordercolor,   tagsselfloatcolor },
	[SchemeHidNorm]      = { hidnormfgcolor,   hidnormbgcolor,   c000000,              c000000 },
	[SchemeHidSel]       = { hidselfgcolor,    hidselbgcolor,    c000000,              c000000 },
	[SchemeUrg]          = { urgfgcolor,       urgbgcolor,       urgbordercolor,       urgfloatcolor },
};

/* Tags
 * In a traditional dwm the number of tags in use can be changed simply by changing the number
 * of strings in the tags array. This build does things a bit different which has some added
 * benefits. If you need to change the number of tags here then change the NUMTAGS macro in dwm.c.
 *
 * Examples:
 *
 *  1) static char *tagicons[][NUMTAGS*2] = {
 *         [DEFAULT_TAGS] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I" },
 *     }
 *
 *  2) static char *tagicons[][1] = {
 *         [DEFAULT_TAGS] = { "•" },
 *     }
 *
 * The first example would result in the tags on the first monitor to be 1 through 9, while the
 * tags for the second monitor would be named A through I. A third monitor would start again at
 * 1 through 9 while the tags on a fourth monitor would also be named A through I. Note the tags
 * count of NUMTAGS*2 in the array initialiser which defines how many tag text / icon exists in
 * the array. This can be changed to *3 to add separate icons for a third monitor.
 *
 * For the second example each tag would be represented as a bullet point. Both cases work the
 * same from a technical standpoint - the icon index is derived from the tag index and the monitor
 * index. If the icon index is is greater than the number of tag icons then it will wrap around
 * until it an icon matches. Similarly if there are two tag icons then it would alternate between
 * them. This works seamlessly with alternative tags and alttagsdecoration patches.
 */
static char *tagicons[][NUMTAGS] =
{
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "7" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G" },
	[ALT_TAGS_DECORATION] = { "<1>", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>" },
};

/* There are two options when it comes to per-client rules:
 *  - a typical struct table or
 *  - using the RULE macro
 *
 * A traditional struct table looks like this:
 *    // class      instance  title  wintype  tags mask  isfloating  monitor
 *    { "Gimp",     NULL,     NULL,  NULL,    1 << 4,    0,          -1 },
 *    { "Firefox",  NULL,     NULL,  NULL,    1 << 7,    0,          -1 },
 *
 * The RULE macro has the default values set for each field allowing you to only
 * specify the values that are relevant for your rule, e.g.
 *
 *    RULE(.class = "Gimp", .tags = 1 << 4)
 *    RULE(.class = "Firefox", .tags = 1 << 7)
 *
 * Refer to the Rule struct definition for the list of available fields depending on
 * the patches you enable.
 */
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */
	RULE(.wintype = WTYPE "DIALOG", .isfloating = 1)
	RULE(.wintype = WTYPE "UTILITY", .isfloating = 1)
	RULE(.wintype = WTYPE "TOOLBAR", .isfloating = 1)
	RULE(.wintype = WTYPE "SPLASH", .isfloating = 1)
	RULE(.class = "st", .isterminal = 1)
	RULE(.class = "imv", .isfloating = 1)
	RULE(.class = "Qalculate-gtk", .isfloating = 1)
	RULE(.class = "Blueman", .isfloating = 1)
	RULE(.class = "Bitwarden", .isfloating = 1)
	RULE(.class = "bitwarden", .isfloating = 1)
	RULE(.class = "localsend", .isfloating = 1)
	RULE(.class = "polkit-gnome", .isfloating = 1)
	RULE(.class = "xdg-desktop-portal-gtk", .isfloating = 1)
	RULE(.class = "Nm-connection-editor", .isfloating = 1)
	RULE(.class = "firefox", .instance = "Places", .isfloating = 1)
};

/* Bar rules allow you to configure what is shown where on the bar, as well as
 * introducing your own bar modules.
 *
 *    monitor:
 *      -1  show on all monitors
 *       0  show on monitor 0
 *      'A' show on active monitor (i.e. focused / selected) (or just -1 for active?)
 *    bar - bar index, 0 is default, 1 is extrabar
 *    alignment - how the module is aligned compared to other modules
 *    widthfunc, drawfunc, clickfunc - providing bar module width, draw and click functions
 *    name - does nothing, intended for visual clue and for logging / debugging
 */
static const BarRule barrules[] = {
	/* monitor   bar    alignment         widthfunc                 drawfunc                clickfunc                hoverfunc                name */
	{ -1,        0,     BAR_ALIGN_LEFT,   width_tags,               draw_tags,              click_tags,              hover_tags,              "tags" },
	{  0,        0,     BAR_ALIGN_RIGHT,  width_systray,            draw_systray,           click_systray,           NULL,                    "systray" },
	{ -1,        0,     BAR_ALIGN_LEFT,   width_ltsymbol,           draw_ltsymbol,          click_ltsymbol,          NULL,                    "layout" },
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status2d,           draw_status2d,          click_statuscmd,         NULL,                    "status2d" },
	{ -1,        0,     BAR_ALIGN_NONE,   width_wintitle,           draw_wintitle,          click_wintitle,          NULL,                    "wintitle" },
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[T]",      tile },    /* first entry is default */
	{ "[F]",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "TTT",      bstack },
	{ "|M|",      centeredmaster },
	{ "[D]",      deck },
	{ "[\\]",     dwindle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* commands */
static const char *termcmd[]  = { "st", NULL };
static const char *dictatecmd[] = { "voxtype-hold", NULL };
static const char *browsercmd[] = {"env", "QTWEBENGINE_CHROMIUM_FLAGS=--use-gl=angle --enable-features=Vulkan --use-vulkan=native", "qutebrowser", NULL};

/* This defines the name of the executable that handles the bar (used for signalling purposes) */
#define STATUSBAR "dwmblocks"

static const Key keys[] = {
	/* modifier                     key            function                argument */
	{ MODKEY,                       XK_Return,     spawn,                  {.v = termcmd } },
	{ MODKEY,                       XK_space,      spawn,                  SHCMD("j4-dmenu-desktop --dmenu='dmenu -i -c -l 8 -p Apps -S' --display-binary --term st --usage-log=$HOME/.cache/j4-history") },
	{ MODKEY,                       XK_x,          spawn,                  SHCMD("emacsclient -c -a ''") },
	{ MODKEY,                       XK_w,          spawn,                  {.v = browsercmd } },
	{ MODKEY,                       XK_s,          spawn,                  SHCMD("signal-desktop") },
	{ MODKEY,                       XK_e,          spawn,                  SHCMD("st -e open-nnn") },
	{ MODKEY,                       XK_a,          spawn,                  SHCMD("st -e wiremix") },
	{ 0,                            XK_F9,         spawnheld,              {.v = dictatecmd } },
	{ MODKEY|ShiftMask,             XK_d,          spawn,                  SHCMD("voxtype record cancel") },
	{ MODKEY,                       XK_o,          spawn,                  SHCMD("region-ocr") },
	{ MODKEY,                       XK_semicolon,  spawn,                  SHCMD("bemoji -n") },
	{ MODKEY,                       XK_equal,      spawn,                  SHCMD("qalculate-gtk") },
	{ MODKEY,                       XK_Escape,     spawn,                  SHCMD("lock-session") },
	{ MODKEY,                       XK_n,          spawn,                  SHCMD("dnd-toggle") },
	{ MODKEY|ControlMask|ShiftMask, XK_n,          spawn,                  SHCMD("dunstctl context") },
	{ MODKEY|ShiftMask,             XK_p,          spawn,                  SHCMD("power-menu") },
	{ MODKEY,                       XK_r,          spawn,                  SHCMD("screenrecord menu") },
	{ MODKEY|ControlMask,           XK_r,          spawn,                  SHCMD("screenrecord stop") },
	{ MODKEY,                       XK_Print,      spawn,                  SHCMD("screenrecord region") },
	{ MODKEY|ShiftMask,             XK_Print,      spawn,                  SHCMD("screenrecord output") },
	{ 0,                            XK_Print,      spawn,                  SHCMD("screenshot region") },
	{ ControlMask,                  XK_Print,      spawn,                  SHCMD("screenshot window") },
	{ ShiftMask,                    XK_Print,      spawn,                  SHCMD("screenshot full") },
	{ 0,                            XF86XK_AudioPlay,        spawn,       SHCMD("playerctl play-pause") },
	{ 0,                            XF86XK_AudioPause,       spawn,       SHCMD("playerctl play-pause") },
	{ 0,                            XF86XK_AudioNext,        spawn,       SHCMD("playerctl next") },
	{ 0,                            XF86XK_AudioPrev,        spawn,       SHCMD("playerctl previous") },
	{ 0,                            XF86XK_AudioRaiseVolume, spawn,       SHCMD("audio sink up") },
	{ 0,                            XF86XK_AudioLowerVolume, spawn,       SHCMD("audio sink down") },
	{ 0,                            XF86XK_AudioMute,        spawn,       SHCMD("audio sink mute") },
	{ 0,                            XF86XK_AudioMicMute,     spawn,       SHCMD("audio source mute") },
	{ 0,                            XF86XK_MonBrightnessUp,   spawn,      SHCMD("brightness up") },
	{ 0,                            XF86XK_MonBrightnessDown, spawn,      SHCMD("brightness down") },
	{ MODKEY,                       XK_b,          togglebar,              {0} },
	{ MODKEY,                       XK_j,          focusstack,             {.i = +1 } },
	{ MODKEY,                       XK_k,          focusstack,             {.i = -1 } },
	{ MODKEY,                       XK_i,          incnmaster,             {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_i,          incnmaster,             {.i = -1 } },
	{ MODKEY,                       XK_h,          setmfact,               {.f = -0.05} },
	{ MODKEY,                       XK_l,          setmfact,               {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_j,          movestack,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,          movestack,              {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_0,          togglegaps,             {0} },
	{ MODKEY,                       XK_q,          killclient,             {0} },
	{ MODKEY|ShiftMask,             XK_q,          quit,                   {0} },
	{ MODKEY|ShiftMask,             XK_r,          quit,                   {1} },
	{ MODKEY|ShiftMask,             XK_t,          setlayout,              {.v = &layouts[0]} },
	{ MODKEY|ShiftMask,             XK_f,          setlayout,              {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_m,          setlayout,              {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_space,      togglefloating,         {0} },
	{ MODKEY,                       XK_f,          togglefullscreen,       {0} },
	{ MODKEY|ControlMask,           XK_period,     cyclelayout,            {.i = +1 } },
	TAGKEYS(                        XK_1,                                  0)
	TAGKEYS(                        XK_2,                                  1)
	TAGKEYS(                        XK_3,                                  2)
	TAGKEYS(                        XK_4,                                  3)
	TAGKEYS(                        XK_5,                                  4)
	TAGKEYS(                        XK_6,                                  5)
	TAGKEYS(                        XK_7,                                  6)
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask           button          function        argument */
	{ ClkLtSymbol,          0,                   Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,                   Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
	{ ClkStatusText,        0,                   Button1,        sigstatusbar,   {.i = 1 } },
	{ ClkStatusText,        0,                   Button2,        sigstatusbar,   {.i = 2 } },
	{ ClkStatusText,        0,                   Button3,        sigstatusbar,   {.i = 3 } },
	{ ClkClientWin,         MODKEY,              Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,              Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,              Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
};

