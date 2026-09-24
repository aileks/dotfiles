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
	[SchemeNorm] = { "#DED6D0", "#221B17" },
	[SchemeSel]  = { "#F1EAE5", "#725F52" },
	[SchemeOut]  = { "#A2968E", "#221B17" },
	[SchemeBorder] = { "#80756E", "#80756E" },
	[SchemeSelHighlight]  = { "#F1EAE5", "#725F52" },
	[SchemeNormHighlight] = { "#B39887", "#221B17" },
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
