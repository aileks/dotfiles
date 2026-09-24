#ifndef CONFIG_H
#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER "^d^^c#80756E^ │ ^d^"

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 45

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// Icon slots carry status2d color codes (Muted Umber); the parser copies
// exactly 7 characters after ^c, so colors are #RRGGBB.
#define BLOCKS(X)                    \
    X("^c#B39887^", "bar-dnd", 1, 1)   \
    X("^c#C6BBB5^", "bar-volume", 1, 2)        \
    X("^c#A2968E^", "bar-cpu-temperature", 5, 3) \
    X("^c#A2968E^", "bar-memory", 5, 4)        \
    X("^c#A69082^", "bar-gpu", 5, 5)           \
    X("^c#C1AD9F^", "bar-network", 5, 6)       \
    X("^c#DED6D0^", "bar-clock", 1, 10)

#endif  // CONFIG_H
