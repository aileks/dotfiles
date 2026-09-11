#ifndef CONFIG_H
#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER "   "

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 45

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// Define blocks for the status feed as X(icon, cmd, interval, signal).
#define BLOCKS(X)                          \
    X("", "bar-mpris", 5, 6)               \
    X("", "bar-dnd", 2, 0)                 \
    X("", "bar-volume", 2, 10)             \
    X("\uF2DB", "bar-cpu-temperature", 5, 1) \
    X("\uEFC5", "bar-memory", 5, 2)        \
    X("\uF0FB2", "bar-gpu", 5, 3)          \
    X("", "bar-network", 10, 4)            \
    X("\uF017", "date '+%a %d %b %H:%M'", 5, 0)

#endif  // CONFIG_H
