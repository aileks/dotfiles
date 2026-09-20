/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom */
static int fuzzy = 1;                       /* -F  option; if 0, dmenu doesn't use fuzzy matching */
static int center = 0;                      /* -c  option; if 0, dmenu won't be centered on the screen */
static int min_width = 720;                 /* minimum width when centered */
static int max_width = 800;                 /* maximum width when centered */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] =
{
	"Iosevka Nerd Font:size=16"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */

static
const
char *colors[][2] = {
	/*               fg         bg       */
	[SchemeNorm] = { "#c5afa4", "#15110f" },
	[SchemeSel]  = { "#e9d1c5", "#944d24" },
	[SchemeOut]  = { "#5f5049", "#15110f" },
	[SchemeBorder] = { "#5f5049", "#5f5049" },
	[SchemeSelHighlight]  = { "#e9d1c5", "#944d24" },
	[SchemeNormHighlight] = { "#e9d1c5", "#15110f" },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";

/* Size of the window border */
static unsigned int border_width = 2;

