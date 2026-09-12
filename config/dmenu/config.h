/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

/* dmenu 5.4 with patches applied in this order:
 * line-height 5.2, border 20230512, center 20250407,
 * fuzzymatch 5.3, fuzzyhighlight 5.3, xresources 20260510 */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
static int fuzzy  = 1;                      /* -F  option; if 0, dmenu doesn't use fuzzy matching */
static int centered = 1;                    /* -c option; centers dmenu on screen */
static int min_width = 720;                    /* minimum width when centered */
static const float menu_height_ratio = 4.0f;  /* This is the ratio used in the original calculation */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"Iosevka Nerd Font:size=16"
};
static const char *prompt      = NULL;      /* -p  option; prompt to left of input field */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#BBB3A9", "#131210" },
	[SchemeSel] = { "#DDD5CA", "#6785A1" },
	[SchemeSelHighlight] = { "#131210", "#6785A1" },
	[SchemeNormHighlight] = { "#DDD5CA", "#131210" },
	[SchemeOut] = { "#131210", "#879B5C" },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 8;
/* -h option; minimum height of a menu line */
static unsigned int lineheight = 28;
static unsigned int min_lineheight = 8;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";

/* Size of the window border */
static unsigned int border_width = 2;

/* X resources to load at startup */
static const XResPref resources[] = {
	/* name                  type     address */
	{ "dmenu.font",          STRING,  &fonts[0] },
	{ "dmenu.prompt",        STRING,  &prompt },
	{ "dmenu.foreground",    STRING,  &colors[SchemeNorm][ColFg] },
	{ "dmenu.background",    STRING,  &colors[SchemeNorm][ColBg] },
	{ "dmenu.foregroundSel", STRING,  &colors[SchemeSel][ColFg] },
	{ "dmenu.backgroundSel", STRING,  &colors[SchemeSel][ColBg] },
	{ "dmenu.foregroundOut", STRING,  &colors[SchemeOut][ColFg] },
	{ "dmenu.backgroundOut", STRING,  &colors[SchemeOut][ColBg] },
	{ "dmenu.topbar",        INTEGER, &topbar },
	{ "dmenu.lines",         INTEGER, &lines },
};
