/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nogroup";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "#15110F",   /* after initialization */
	[INPUT] =  "#D98C63",   /* during input */
	[FAILED] = "#A45751",   /* wrong password */
	[CAPS] =   "#F1A278",   /* CapsLock on */
	[BLOCKS] = "#E9D1C5",   /* key feedback block */
};

/*
 * Xresources preferences to load at startup
 */
ResourcePref resources[] = {
		{ "locked",       STRING,  &colorname[INIT] },
		{ "input",        STRING,  &colorname[INPUT] },
		{ "failed",       STRING,  &colorname[FAILED] },
		{ "capslock",     STRING,  &colorname[CAPS] },
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/* allow control key to trigger fail on clear */
static const int controlkeyclear = 1;

static short int blocks_enabled = 1; // 0 = don't show blocks
static const int blocks_width = 0; // 0 = full width
static const int blocks_height = 16;

// position
static const int blocks_x = 0;
static const int blocks_y = 0;

// Number of blocks
static const int blocks_count = 10;

/* time in seconds to cancel lock with mouse movement */
static const int timetocancel = 4;
