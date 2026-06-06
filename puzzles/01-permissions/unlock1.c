/*
 * unlock1 — setuid binary for escape-linux puzzle 1.
 *
 * Runs as root (setuid). Reads /srv/vault/secret1 (root-owned, mode 0600)
 * and prints its contents — but only when the correct argument is given.
 *
 * The player discovers this binary via:  find / -perm -4000 -type f 2>/dev/null
 * They read this source at:             /usr/local/src/unlock1.c
 * They run it as:                       unlock1 open
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define SECRET_PATH "/srv/vault/secret1"
#define REQUIRED_ARG "open"

int main(int argc, char *argv[]) {
    /* Verify the caller knows the magic argument. */
    if (argc < 2 || strcmp(argv[1], REQUIRED_ARG) != 0) {
        fprintf(stderr, "Usage: %s " REQUIRED_ARG "\n", argv[0]);
        return 1;
    }

    /* At this point we're running with euid=root (setuid bit).
     * Open the secret file — the calling user could not do this directly. */
    FILE *f = fopen(SECRET_PATH, "r");
    if (!f) {
        fprintf(stderr, "unlock1: cannot open %s: %s\n", SECRET_PATH, strerror(errno));
        return 1;
    }

    char buf[256];
    if (!fgets(buf, sizeof(buf), f)) {
        fprintf(stderr, "unlock1: read error\n");
        fclose(f);
        return 1;
    }
    fclose(f);

    /* Strip trailing newline before printing. */
    size_t len = strlen(buf);
    if (len > 0 && buf[len - 1] == '\n') buf[len - 1] = '\0';

    printf("%s\n", buf);
    return 0;
}
