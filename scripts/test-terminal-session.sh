#!/bin/bash
set -Eeuxo pipefail
cd "$XDG_RUNTIME_DIR"
export WAYLAND_DEBUG=1
sway --config /etc/begonia/sway.conf --debug >sway.log 2>&1 &
sway_pid=$!
trap 'status=$?; if ((status != 0)); then tail -n 100 sway.log protocols.log >&2; fi; kill "$sway_pid" 2>/dev/null || true; wait "$sway_pid" 2>/dev/null || true' EXIT
for i in $(seq 1 60); do
  socket=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'sway-ipc*.sock' -print -quit)
  display=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' -type s -printf '%f\n' -quit)
  if [[ -n "$socket" && -n "$display" ]]; then break; fi
  kill -0 "$sway_pid"
  sleep 1
done
export SWAYSOCK="$socket" WAYLAND_DISPLAY="$display"
wayland-info >protocols.log 2>&1
grep -q zwp_virtual_keyboard_manager_v1 protocols.log
grep -q zwlr_layer_shell_v1 protocols.log
for i in $(seq 1 30); do
  swaymsg -t get_tree >tree.json
  if jq -e '.. | objects | select(.app_id? == "begonia-terminal")' tree.json >/dev/null; then break; fi
  sleep 1
done
jq -e '.. | objects | select(.app_id? == "begonia-terminal")' tree.json >/dev/null
pgrep -x wvkbd-mobintl
# Same virtual-keyboard protocol as the OSK; prove text reaches the terminal shell.
wtype "printf TERMINAL_INPUT_OK > '$XDG_RUNTIME_DIR/input-result'"
wtype -k Return
for i in $(seq 1 10); do test -f input-result && break; sleep 1; done
test "$(cat input-result)" = TERMINAL_INPUT_OK
swaymsg -t get_outputs >outputs.json
swaymsg -t get_inputs >inputs.json
printf 'PASS: Sway + foot + wvkbd mapped; virtual keyboard shell input works. No physical hardware tested.\n' | tee terminal-smoke.log
# Sway can close IPC before acknowledging exit; process status below is decisive.
swaymsg exit || true
wait "$sway_pid"
trap - EXIT
