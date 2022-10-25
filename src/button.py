import time
from machine import Pin

class Button:
    def __init__(self, pin_id, mode=Pin.IN, pull=Pin.PULL_UP, debounce_ms=100):
        self.pin = Pin(pin_id, mode, pull)
        self.held = bool(self) # get current value via __bool__
        self.debounce_ms = debounce_ms
        self._debouncing = False
        self._debounce_ticks = time.ticks_ms()

    def __bool__(self):
        return not self.pin.value()

    def debounced(self):
        """Return True once for each press of the button.
        Will emit False until the button is released."""
        if self:
            if not self._debouncing:
                self._debouncing = True
                self._debounce_ticks = time.ticks_ms()
                return True
            else:
                return False
        else:
            if self._debouncing and time.ticks_diff(time.ticks_ms(), self._debounce_ticks) > self.debounce_ms:
                self._debouncing = False
            return False
