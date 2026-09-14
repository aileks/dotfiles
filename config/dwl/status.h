#ifndef DWL_STATUS_H
#define DWL_STATUS_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum { STATUS_BLOCKS = 7, STATUS_TEXT_SIZE = 160, STATUS_LINE_SIZE = 2048 };
typedef struct {
	uint32_t color;
	char text[STATUS_TEXT_SIZE];
} StatusBlock;
typedef struct {
	StatusBlock blocks[STATUS_BLOCKS];
	char line[STATUS_LINE_SIZE];
	size_t used;
	int discarded;
} Status;

/* Each line contains seven tab-separated "RRGGBBAA text" fields. */
static int
status_parse(Status *status)
{
	StatusBlock next[STATUS_BLOCKS] = {0};
	char *field = status->line, *end;
	size_t i, j, length;
	for (i = 0; i < STATUS_BLOCKS; i++) {
		end = strchr(field, '\t');
		if ((i + 1 < STATUS_BLOCKS) != (end != NULL))
			return 0;
		length = end ? (size_t)(end - field) : strlen(field);
		if (length < 9 || length - 9 >= STATUS_TEXT_SIZE || field[8] != ' ')
			return 0;
		for (j = 0; j < 8; j++)
			if (!strchr("0123456789abcdefABCDEF", field[j]))
				return 0;
		for (j = 9; j < length; j++)
			if ((unsigned char)field[j] < 32 || field[j] == 127)
				return 0;
		field[8] = '\0';
		next[i].color = (uint32_t)strtoul(field, NULL, 16);
		memcpy(next[i].text, field + 9, length - 9);
		if (end)
			field = end + 1;
	}
	memcpy(status->blocks, next, sizeof(next));
	return 1;
}

static int
status_feed(Status *status, const char *bytes, size_t length)
{
	size_t i;
	int changed = 0;
	for (i = 0; i < length; i++) {
		if (bytes[i] == '\n') {
			status->line[status->used] = '\0';
			if (!status->discarded)
				changed |= status_parse(status);
			status->used = 0;
			status->discarded = 0;
		} else if (!bytes[i] || status->used == sizeof(status->line) - 1) {
			status->discarded = 1;
		} else if (!status->discarded) {
			status->line[status->used++] = bytes[i];
		}
	}
	return changed;
}
#endif
