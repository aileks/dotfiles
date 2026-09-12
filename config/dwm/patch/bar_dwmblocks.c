#include <limits.h>

static int statussig;
pid_t statuspid = -1;

pid_t
getstatusbarpid()
{
	char buf[32], command[64], *str = buf, *c, *end;
	long pid;
	FILE *fp;

	if (statuspid > 0) {
		snprintf(buf, sizeof(buf), "/proc/%u/cmdline", statuspid);
		if ((fp = fopen(buf, "r"))) {
			if (!fgets(buf, sizeof(buf), fp)) {
				fclose(fp);
				return -1;
			}
			while ((c = strchr(str, '/')))
				str = c + 1;
			fclose(fp);
			if (!strcmp(str, STATUSBAR))
				return statuspid;
		}
	}
	snprintf(command, sizeof(command), "pgrep -u %lu -o -x "STATUSBAR, (unsigned long)getuid());
	if (!(fp = popen(command, "r")))
		return -1;
	if (!fgets(buf, sizeof(buf), fp)) {
		pclose(fp);
		return -1;
	}
	pclose(fp);
	errno = 0;
	pid = strtol(buf, &end, 10);
	if (errno == ERANGE || end == buf || (*end != '\n' && *end != '\0') || pid <= 0 || pid > INT_MAX)
		return -1;
	return (pid_t)pid;
}

void
sigstatusbar(const Arg *arg)
{
	union sigval sv;

	if (!statussig)
		return;
	if ((statuspid = getstatusbarpid()) <= 0)
		return;

	#if BAR_DWMBLOCKS_SIGUSR1_PATCH
	sv.sival_int = (statussig << 8) | arg->i;
	if (sigqueue(statuspid, SIGUSR1, sv) == -1) {
		if (errno == ESRCH) {
			if (!getstatusbarpid())
				sigqueue(statuspid, SIGUSR1, sv);
		}
	}
	#else
	sv.sival_int = arg->i;
	sigqueue(statuspid, SIGRTMIN+statussig, sv);
	#endif // BAR_DWMBLOCKS_SIGUSR1_PATCH
}
