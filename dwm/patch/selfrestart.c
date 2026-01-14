#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * Magically finds the current's executable path
 *
 * I'm doing the do{}while(); trick because Linux (what I'm running) is not
 * POSIX compilant and so lstat() cannot be trusted on /proc entries
 *
 * Fixed: Handle " (deleted)" suffix when binary was replaced during make install
 *
 * @return char* the path of the current executable
 */
char *get_dwm_path()
{
    struct stat s;
    int r, length, rate = 42;
    char *path = NULL;
    char *deleted_suffix;

    if (lstat("/proc/self/exe", &s) == -1) {
        perror("lstat:");
        return NULL;
    }

    length = s.st_size + 1 - rate;

    do
    {
        length+=rate;

        free(path);
        path = malloc(sizeof(char) * length);

        if (path == NULL){
            perror("malloc:");
            return NULL;
        }

        r = readlink("/proc/self/exe", path, length);

        if (r == -1){
            perror("readlink:");
            return NULL;
        }
    } while (r >= length);

    path[r] = '\0';

    /* Handle " (deleted)" suffix when binary was replaced */
    deleted_suffix = strstr(path, " (deleted)");
    if (deleted_suffix != NULL) {
        *deleted_suffix = '\0';
    }

    return path;
}

/**
 * self-restart
 *
 * Initially inspired by: Yu-Jie Lin
 * https://sites.google.com/site/yjlnotes/notes/dwm
 */
void self_restart(const Arg *arg)
{
    char *const argv[] = {get_dwm_path(), NULL};

    if (argv[0] == NULL) {
        return;
    }

    execv(argv[0], argv);
}

