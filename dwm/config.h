/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define CMD(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

static const unsigned int borderpx       = 2;
static const unsigned int snap           = 32;
#if SWALLOW_PATCH
static const int swallowfloating         = 0;
#endif
#if VANITYGAPS_PATCH
static const unsigned int gappih         = 10;
static const unsigned int gappiv         = 10;
static const unsigned int gappoh         = 10;
static const unsigned int gappov         = 10;
static const int smartgaps_fact          = 0;
#endif
#if AUTOSTART_PATCH
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".local/share";
#endif
static const int showbar                 = 1;
static const int topbar                  = 1;
#if BAR_HEIGHT_PATCH
static const int bar_height              = 28;
#endif
#if BAR_STATUSPADDING_PATCH
static const int horizpadbar             = 4;
static const int vertpadbar              = 6;
#endif

/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
#if BAR_STATUSALLMONS_PATCH
static const int statusmon               = -1;
#elif BAR_STATICSTATUS_PATCH
static const int statusmon               = 0;
#else
static const int statusmon               = 'A';
#endif

static int tagindicatortype              = INDICATOR_TOP_LEFT_SQUARE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;

#if BAR_PANGO_PATCH
static const char font[]                 = "BerkeleyMono Nerd Font Mono 12";
#else
static const char *fonts[]               = { "BerkeleyMono Nerd Font Mono:size=12" };
#endif
static const char dmenufont[]            = "BerkeleyMono Nerd Font Mono:size=12";

static char c000000[]                    = "#000000";

/* Ashen colorscheme - https://codeberg.org/ficd/ashen */
static char normfgcolor[]                = "#a7a7a7";
static char normbgcolor[]                = "#121212";
static char normbordercolor[]            = "#212121";
static char normfloatcolor[]             = "#4A8B8B";

static char selfgcolor[]                 = "#d5d5d5";
static char selbgcolor[]                 = "#C4693D";
static char selbordercolor[]             = "#C4693D";
static char selfloatcolor[]              = "#C4693D";

static char titlenormfgcolor[]           = "#a7a7a7";
static char titlenormbgcolor[]           = "#121212";
static char titlenormbordercolor[]       = "#212121";
static char titlenormfloatcolor[]        = "#4A8B8B";

static char titleselfgcolor[]            = "#d5d5d5";
static char titleselbgcolor[]            = "#191919";
static char titleselbordercolor[]        = "#C4693D";
static char titleselfloatcolor[]         = "#C4693D";

static char tagsnormfgcolor[]            = "#949494";
static char tagsnormbgcolor[]            = "#121212";
static char tagsnormbordercolor[]        = "#212121";
static char tagsnormfloatcolor[]         = "#4A8B8B";

static char tagsselfgcolor[]             = "#121212";
static char tagsselbgcolor[]             = "#C4693D";
static char tagsselbordercolor[]         = "#C4693D";
static char tagsselfloatcolor[]          = "#C4693D";

static char hidnormfgcolor[]             = "#4A8B8B";
static char hidselfgcolor[]              = "#C4693D";
static char hidnormbgcolor[]             = "#121212";
static char hidselbgcolor[]              = "#121212";

static char urgfgcolor[]                 = "#d5d5d5";
static char urgbgcolor[]                 = "#121212";
static char urgbordercolor[]             = "#B14242";
static char urgfloatcolor[]              = "#B14242";

#if BAR_ALPHA_PATCH
static const unsigned int baralpha = 0xe6;
static const unsigned int borderalpha = OPAQUE;
static const unsigned int alphas[][3] = {
	[SchemeNorm]         = { OPAQUE, baralpha, borderalpha },
	[SchemeSel]          = { OPAQUE, baralpha, borderalpha },
	[SchemeTitleNorm]    = { OPAQUE, baralpha, borderalpha },
	[SchemeTitleSel]     = { OPAQUE, baralpha, borderalpha },
	[SchemeTagsNorm]     = { OPAQUE, baralpha, borderalpha },
	[SchemeTagsSel]      = { OPAQUE, baralpha, borderalpha },
	[SchemeHidNorm]      = { OPAQUE, baralpha, borderalpha },
	[SchemeHidSel]       = { OPAQUE, baralpha, borderalpha },
	[SchemeUrg]          = { OPAQUE, baralpha, borderalpha },
};
#endif

static char *colors[][ColCount] = {
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

#if SCRATCHPADS_PATCH
const char *spcmd1[] = {"wezterm", "start", "--class", "spterm", NULL };
static Sp scratchpads[] = {
   {"spterm",      spcmd1},
};
#endif

#if NAMETAG_PATCH
static char tagicons[][NUMTAGS][MAX_TAGLEN] =
#else
static char *tagicons[][NUMTAGS] =
#endif
{
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
	[ALT_TAGS_DECORATION] = { "<1>", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>", "<8>", "<9>" },
};

static const Rule rules[] = {
	RULE(.wintype = WTYPE "DIALOG", .isfloating = 1)
	RULE(.wintype = WTYPE "UTILITY", .isfloating = 1)
	RULE(.wintype = WTYPE "TOOLBAR", .isfloating = 1)
	RULE(.wintype = WTYPE "SPLASH", .isfloating = 1)
	RULE(.class = "firefox", .tags = 1 << 1)
	RULE(.class = "Pcmanfm", .isfloating = 1)
	RULE(.class = "Nsxiv", .isfloating = 1)
	RULE(.class = "feh", .isfloating = 1)
	RULE(.title = "Event Tester", .isfloating = 1)
	#if SWALLOW_PATCH
	RULE(.class = "org.wezfurlong.wezterm", .isterminal = 1)
	#endif
	#if SCRATCHPADS_PATCH
	RULE(.instance = "spterm", .tags = SPTAG(0), .isfloating = 1)
	#endif
};

static const BarRule barrules[] = {
	#if BAR_TAGS_PATCH
	{ -1,        0,     BAR_ALIGN_LEFT,   width_tags,               draw_tags,              click_tags,              hover_tags,              "tags" },
	#endif
	#if BAR_LTSYMBOL_PATCH
	{ -1,        0,     BAR_ALIGN_LEFT,   width_ltsymbol,           draw_ltsymbol,          click_ltsymbol,          NULL,                    "layout" },
	#endif
	#if BAR_STATUS2D_PATCH && BAR_STATUSCMD_PATCH
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status2d,           draw_status2d,          click_statuscmd,         NULL,                    "status2d" },
	#elif BAR_STATUS2D_PATCH
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status2d,           draw_status2d,          click_status2d,          NULL,                    "status2d" },
	#elif BAR_STATUS_PATCH
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status,             draw_status,            click_status,            NULL,                    "status" },
	#endif
	#if BAR_WINTITLE_PATCH
	{ -1,        0,     BAR_ALIGN_NONE,   width_wintitle,           draw_wintitle,          click_wintitle,          NULL,                    "wintitle" },
	#endif
};

static const float mfact     = 0.55;
static const int nmaster     = 1;
#if FLEXTILE_DELUXE_LAYOUT
static const int nstack      = 0;
#endif
static const int resizehints = 0;
static const int lockfullscreen = 1;
static const int refreshrate = 60;

#if FLEXTILE_DELUXE_LAYOUT
static const Layout layouts[] = {
	{ "[]=",      flextile,         { -1, -1, SPLIT_VERTICAL, TOP_TO_BOTTOM, TOP_TO_BOTTOM, 0, NULL } },
 	{ "><>",      NULL,             {0} },
	{ "[M]",      flextile,         { -1, -1, NO_SPLIT, MONOCLE, MONOCLE, 0, NULL } },
	{ "TTT",      flextile,         { -1, -1, SPLIT_HORIZONTAL, LEFT_TO_RIGHT, LEFT_TO_RIGHT, 0, NULL } },
	{ "|M|",      flextile,         { -1, -1, SPLIT_CENTERED_VERTICAL, LEFT_TO_RIGHT, TOP_TO_BOTTOM, TOP_TO_BOTTOM, NULL } },
	{ "[D]",      flextile,         { -1, -1, SPLIT_VERTICAL, TOP_TO_BOTTOM, MONOCLE, 0, NULL } },
	{ "(@)",      flextile,         { -1, -1, NO_SPLIT, SPIRAL, SPIRAL, 0, NULL } },
	{ "[\\]",     flextile,         { -1, -1, NO_SPLIT, DWINDLE, DWINDLE, 0, NULL } },
	#if TILE_LAYOUT
	{ "[]=",      tile,             {0} },
	#endif
	#if MONOCLE_LAYOUT
	{ "[M]",      monocle,          {0} },
	#endif
	#if BSTACK_LAYOUT
	{ "TTT",      bstack,           {0} },
	#endif
	#if CENTEREDMASTER_LAYOUT
	{ "|M|",      centeredmaster,   {0} },
	#endif
	#if DECK_LAYOUT
	{ "[D]",      deck,             {0} },
	#endif
	#if FIBONACCI_SPIRAL_LAYOUT
	{ "(@)",      spiral,           {0} },
	#endif
	#if FIBONACCI_DWINDLE_LAYOUT
	{ "[\\]",     dwindle,          {0} },
	#endif
};
#else
static const Layout layouts[] = {
	#if TILE_LAYOUT
	{ "[]=",      tile },
	#endif
	{ "><>",      NULL },
	#if MONOCLE_LAYOUT
	{ "[M]",      monocle },
	#endif
	#if BSTACK_LAYOUT
	{ "TTT",      bstack },
	#endif
	#if CENTEREDMASTER_LAYOUT
	{ "|M|",      centeredmaster },
	#endif
	#if DECK_LAYOUT
	{ "[D]",      deck },
	#endif
	#if FIBONACCI_SPIRAL_LAYOUT
	{ "(@)",      spiral },
	#endif
	#if FIBONACCI_DWINDLE_LAYOUT
	{ "[\\]",     dwindle },
	#endif
};
#endif

#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#if !NODMENU_PATCH
static char dmenumon[2] = "0";
#endif
static const char *dmenucmd[] = {
	"dmenu_run",
	#if !NODMENU_PATCH
	"-m", dmenumon,
	#endif
	"-fn", dmenufont,
	"-nb", normbgcolor,
	"-nf", normfgcolor,
	"-sb", selbgcolor,
	"-sf", selfgcolor,
	#if BAR_DMENUMATCHTOP_PATCH
	topbar ? NULL : "-b",
	#endif
	NULL
};
static const char *termcmd[]  = { "wezterm", NULL };
static const char *roficmd[]  = { "rofi", "-show", "drun", NULL };
static const char *filecmd[]  = { "pcmanfm", NULL };
static const char *lockcmd[]  = { "betterlockscreen", "-l", NULL };

#if BAR_STATUSCMD_PATCH && BAR_DWMBLOCKS_PATCH
#define STATUSBAR "dwmblocks"
#endif

static const Key keys[] = {
	{ MODKEY,                       XK_d,          spawn,                  {.v = roficmd } },
	{ MODKEY,                       XK_Return,     spawn,                  {.v = termcmd } },
	{ MODKEY,                       XK_e,          spawn,                  {.v = filecmd } },
	{ MODKEY|ControlMask,           XK_l,          spawn,                  {.v = lockcmd } },
	{ MODKEY,                       XK_b,          togglebar,              {0} },
	{ MODKEY,                       XK_j,          focusstack,             {.i = +1 } },
	{ MODKEY,                       XK_k,          focusstack,             {.i = -1 } },
	{ MODKEY,                       XK_i,          incnmaster,             {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_i,          incnmaster,             {.i = -1 } },
	{ MODKEY,                       XK_h,          setmfact,               {.f = -0.05} },
	{ MODKEY,                       XK_l,          setmfact,               {.f = +0.05} },
	#if CFACTS_PATCH
	{ MODKEY|ShiftMask,             XK_h,          setcfact,               {.f = +0.25} },
	{ MODKEY|ShiftMask,             XK_l,          setcfact,               {.f = -0.25} },
	{ MODKEY|ShiftMask,             XK_o,          setcfact,               {0} },
	#endif
	#if MOVESTACK_PATCH
	{ MODKEY|ShiftMask,             XK_j,          movestack,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,          movestack,              {.i = -1 } },
	#endif
	{ MODKEY|ShiftMask,             XK_Return,     zoom,                   {0} },
	#if VANITYGAPS_PATCH
	{ MODKEY|Mod1Mask,              XK_equal,      incrgaps,               {.i = +2 } },
	{ MODKEY|Mod1Mask,              XK_minus,      incrgaps,               {.i = -2 } },
	{ MODKEY|Mod1Mask,              XK_0,          togglegaps,             {0} },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_0,          defaultgaps,            {0} },
	#endif
	{ MODKEY,                       XK_Tab,        view,                   {0} },
	{ MODKEY,                       XK_q,          killclient,             {0} },
	{ MODKEY,                       XK_t,          setlayout,              {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,          setlayout,              {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,          setlayout,              {.v = &layouts[2]} },
	#if CYCLELAYOUTS_PATCH
	{ MODKEY|ControlMask,           XK_comma,      cyclelayout,            {.i = -1 } },
	{ MODKEY|ControlMask,           XK_period,     cyclelayout,            {.i = +1 } },
	#endif
	{ MODKEY,                       XK_space,      setlayout,              {0} },
	{ MODKEY|ShiftMask,             XK_space,      togglefloating,         {0} },
	#if TOGGLEFULLSCREEN_PATCH
	{ MODKEY|ShiftMask,             XK_f,          togglefullscreen,       {0} },
	#endif
	#if FULLSCREEN_PATCH
	{ MODKEY|ControlMask|ShiftMask, XK_f,          fullscreen,             {0} },
	#endif
	#if STICKY_PATCH
	{ MODKEY|ShiftMask,             XK_s,          togglesticky,           {0} },
	#endif
	#if MOVECENTER_PATCH
	{ MODKEY|ShiftMask,             XK_c,          movecenter,             {0} },
	#endif
	#if FOCUSURGENT_PATCH
	{ MODKEY,                       XK_u,          focusurgent,            {0} },
	#endif
	#if SCRATCHPADS_PATCH
	{ MODKEY,                       XK_grave,      togglescratch,          {.ui = 0 } },
	#endif
	#if SCRATCHPADS_PATCH && !RENAMED_SCRATCHPADS_PATCH
	{ MODKEY,                       XK_0,          view,                   {.ui = ~SPTAGMASK } },
	{ MODKEY|ShiftMask,             XK_0,          tag,                    {.ui = ~SPTAGMASK } },
	#else
	{ MODKEY,                       XK_0,          view,                   {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,          tag,                    {.ui = ~0 } },
	#endif
	{ MODKEY,                       XK_comma,      focusmon,               {.i = -1 } },
	{ MODKEY,                       XK_period,     focusmon,               {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,      tagmon,                 {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,     tagmon,                 {.i = +1 } },
	#if SELFRESTART_PATCH
	{ MODKEY|ShiftMask,             XK_r,          self_restart,           {0} },
	#endif
	{ MODKEY|ShiftMask,             XK_q,          quit,                   {0} },
	#if RESTARTSIG_PATCH
	{ MODKEY|ControlMask|ShiftMask, XK_q,          quit,                   {1} },
	#endif
	TAGKEYS(                        XK_1,                                  0)
	TAGKEYS(                        XK_2,                                  1)
	TAGKEYS(                        XK_3,                                  2)
	TAGKEYS(                        XK_4,                                  3)
	TAGKEYS(                        XK_5,                                  4)
	TAGKEYS(                        XK_6,                                  5)
	TAGKEYS(                        XK_7,                                  6)
	TAGKEYS(                        XK_8,                                  7)
	TAGKEYS(                        XK_9,                                  8)
	{ 0, XF86XK_AudioMute,          spawn,         SHCMD("pamixer -t; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioLowerVolume,   spawn,         SHCMD("pamixer -d 5; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioRaiseVolume,   spawn,         SHCMD("pamixer -i 5; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioPlay,          spawn,         SHCMD("playerctl play-pause") },
	{ 0, XF86XK_AudioNext,          spawn,         SHCMD("playerctl next") },
	{ 0, XF86XK_AudioPrev,          spawn,         SHCMD("playerctl previous") },
	{ 0, XF86XK_MonBrightnessUp,    spawn,         SHCMD("brightnessctl set +5%") },
	{ 0, XF86XK_MonBrightnessDown,  spawn,         SHCMD("brightnessctl set 5%-") },

	/* Screenshots */
	{ 0,                            XK_Print,      spawn,         SHCMD("screenshot area clipboard") },
	{ ShiftMask,                    XK_Print,      spawn,         SHCMD("screenshot area file") },
	{ ControlMask,                  XK_Print,      spawn,         SHCMD("screenshot window clipboard") },
	{ ControlMask|ShiftMask,        XK_Print,      spawn,         SHCMD("screenshot window file") },
	{ MODKEY,                       XK_Print,      spawn,         SHCMD("screenshot fullscreen clipboard") },
	{ MODKEY|ShiftMask,             XK_Print,      spawn,         SHCMD("screenshot fullscreen file") },

	/* Screen recording */
	{ 0,                            XK_F9,         spawn,         SHCMD("screenrecord area") },
	{ ShiftMask,                    XK_F9,         spawn,         SHCMD("screenrecord window") },
	{ ControlMask,                  XK_F9,         spawn,         SHCMD("screenrecord fullscreen") },
};

static const Button buttons[] = {
	{ ClkLtSymbol,          0,                   Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,                   Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
	#if BAR_STATUSCMD_PATCH && BAR_DWMBLOCKS_PATCH
	{ ClkStatusText,        0,                   Button1,        sigstatusbar,   {.i = 1 } },
	{ ClkStatusText,        0,                   Button2,        sigstatusbar,   {.i = 2 } },
	{ ClkStatusText,        0,                   Button3,        sigstatusbar,   {.i = 3 } },
	{ ClkStatusText,        ShiftMask,           Button1,        sigstatusbar,   {.i = 6 } },
	#endif
	{ ClkClientWin,         MODKEY,              Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,              Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,              Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
};
