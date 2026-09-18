pragma Singleton
import Quickshell

// Nerd Font glyph names used across the shell. Keeping the names abstract lets
// the renderer change without touching bar or popup call sites.
Singleton {
  readonly property var glyphs: ({
    "bell": "󰂚",
    "bellOff": "󰂛",
    "close": "󰅖",
    "check": "󰄬",
    // Agent states, written as surrogate pairs so the escapes stay exact.
    "agentWorking": "\udb81\udea9",
    "agentIdle": "\udb85\udea7",
    "agentAttention": "\udb85\ude9f",
    "blocked": "\uf071",
    "ready": "\uf00c",
    "clock": "\uf017",
    "volume": "󰕾",
    "muted": "󰝟",
    "volumeHdmi": "󰽟",
    "mutedHdmi": "󰽠",
    "battery": "󰁹",
    "memory": "󰍛",
    "temp": "󰔄",
    "up": "󰁝",
    "down": "󰁅",
    "eye": "󰈈",
    "eyeOff": "󰈉",
    "play": "󰐊",
    "pause": "󰏤",
    "music": "󰝚",
    "alert": "󰀦",
    "profilePerformance": "󱐋",
    "profileBalanced": "\uf1e6",
    "profilePowerSaver": "\uf06c",
    "chart": "\uf080",
    "calendar": "\uf133",
    "sliders": "\uf1de",
    "leaf": "\uf06c",
    "trash": "\uf1f8"
  })

  function glyph(name) {
    return glyphs[name] !== undefined ? glyphs[name] : "";
  }
}
