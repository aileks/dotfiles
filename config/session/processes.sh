# Sourced by Bash session scripts. PID records include Linux start time so a reused PID can never identify an unrelated process after a crash.
umask 077
runtime=${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is required}
[[ -d $runtime && ! -L $runtime && -O $runtime && $(stat -c %a "$runtime") == 700 ]] || {
  echo 'The runtime directory must be private and owned by this user' >&2
  return 1
}

RUNTIME_DIR=$runtime/nixdots
STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/nixdots
[[ ! -L $RUNTIME_DIR ]] || return 1
mkdir -p "$RUNTIME_DIR" "$STATE_DIR"
[[ -O $RUNTIME_DIR ]] || return 1
chmod 700 "$RUNTIME_DIR"

process_start() {
  local pid=$1 record
  local -a fields
  [[ $pid =~ ^[0-9]+$ && -O /proc/$pid ]] || return 1
  IFS= read -r record <"/proc/$pid/stat" 2>/dev/null || return 1
  read -r -a fields <<<"${record##*) }"
  [[ ${fields[0]} != Z ]] || return 1
  printf '%s\n' "${fields[19]}"
}

record_is_live() {
  local pid started current
  [[ -f $1 && ! -L $1 && -O $1 ]] || return 1
  read -r pid started <"$1" || return 1
  current=$(process_start "$pid") || return 1
  [[ $started == "$current" ]]
}

session_is_live() {
  [[ ! -e $RUNTIME_DIR/stopping ]] && record_is_live "$RUNTIME_DIR/session.owner"
}

start_session_process() (
  trap - TERM INT HUP
  local name=$1 pid started
  shift
  [[ $name =~ ^[a-z][a-z0-9-]*$ ]] || exit 2
  exec 8>"$RUNTIME_DIR/$name.lock"
  flock 8
  session_is_live || exit 1
  record_is_live "$RUNTIME_DIR/$name.pid" && exit 0
  rm -f "$RUNTIME_DIR/$name.pid"
  setsid session-process supervise "$@" </dev/null >>"$STATE_DIR/$name.log" 2>&1 8>&- 9>&- &
  pid=$!
  started=$(process_start "$pid") || exit 1
  printf '%s %s\n' "$pid" "$started" >"$RUNTIME_DIR/$name.pid"
)

stop_session_process() (
  local name=$1 pid started
  [[ $name =~ ^[a-z][a-z0-9-]*$ ]] || exit 2
  exec 8>"$RUNTIME_DIR/$name.lock"
  flock 8
  if record_is_live "$RUNTIME_DIR/$name.pid"; then
    read -r pid started <"$RUNTIME_DIR/$name.pid"
    kill -TERM "$pid" 2>/dev/null || true
    for _ in {1..30}; do
      record_is_live "$RUNTIME_DIR/$name.pid" || break
      sleep 0.1
    done
    if record_is_live "$RUNTIME_DIR/$name.pid"; then
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$RUNTIME_DIR/$name.pid"
)
