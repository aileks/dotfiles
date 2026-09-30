import asyncio
import contextlib
import os
import signal
import subprocess

import xcffib
from libqtile.backend.x11.core import Core
from libqtile.backend.x11.xkeysyms import keysyms
from libqtile.core.manager import Qtile
from libqtile.log_utils import logger


class HeldDictation:
    def __init__(self):
        self.process: subprocess.Popen[bytes] | None = None
        self.timer: asyncio.TimerHandle | None = None
        self.keycodes: list[int] = []

    def start(self, qtile: Qtile):
        if self.timer is not None:
            return
        if self.process is not None and self.process.poll() is None:
            return
        if not isinstance(qtile.core, Core):
            return
        self.keycodes = qtile.core.conn.keysym_to_keycode(keysyms["F9"])
        if not any(self.keycodes):
            logger.error("Could not find the F9 keycode for dictation")
            return
        try:
            self.process = subprocess.Popen(
                ["voxtype-hold"], stdin=subprocess.PIPE, start_new_session=True
            )
        except OSError:
            logger.exception("Could not start held dictation")
            return
        self._poll(qtile)

    def _poll(self, qtile: Qtile):
        self.timer = None
        if self.process is not None and self.process.poll() is not None:
            self.process = None
        try:
            if not isinstance(qtile.core, Core):
                self.cancel()
                return
            pressed = qtile.core.conn.conn.core.QueryKeymap().reply().keys
            is_pressed = any(
                pressed[code // 8] & (1 << (code % 8)) for code in self.keycodes
            )
            if (
                self.process is not None
                and self.process.stdin is not None
                and not self.process.stdin.closed
                and not is_pressed
            ):
                self.process.stdin.write(b"release\n")
                self.process.stdin.close()
        except BrokenPipeError:
            pass
        except xcffib.XcffibException:
            logger.exception("Could not check the dictation key")
            self.cancel()
            return
        if is_pressed or self.process is not None:
            self.timer = qtile.call_later(0.02, self._poll, qtile)

    def cancel(self):
        if self.timer is not None:
            self.timer.cancel()
            self.timer = None
        if self.process is None:
            return
        if self.process.stdin is not None and not self.process.stdin.closed:
            with contextlib.suppress(BrokenPipeError):
                self.process.stdin.close()
        if self.process.poll() is None:
            # Stop the worker's CLI child too, so its EXIT trap can cancel promptly.
            with contextlib.suppress(ProcessLookupError):
                os.killpg(self.process.pid, signal.SIGTERM)


# Qtile reloads this module before config.py.
previous_dictation = globals().get("held_dictation")
if previous_dictation is not None:
    previous_dictation.cancel()
held_dictation = HeldDictation()
