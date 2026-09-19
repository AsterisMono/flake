pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: theme

  readonly property int barHeight: 30
  readonly property int popupWidth: 380
  readonly property int noticePanelWidth: 384
  // Banner column: the prototype's 360 at 13 px padding, kept narrow enough to
  // stay clear of the notification panel.
  readonly property int bannerWidth: 360
  readonly property int radius: 3

  readonly property color text: "#e1dad3"
  readonly property color muted: "#b8b0b3"
  readonly property color dim: "#9d969e"
  readonly property color accent: "#a0bbc1"
  readonly property color amber: "#d3bb8f"
  readonly property color red: "#e5a3a5"

  // Chosen glass option C: 40% backing opacity, fully opaque text.
  readonly property color glass: Qt.rgba(32 / 255, 33 / 255, 43 / 255, 0.40)
  // The bars sit on blurred wallpaper, which is often far brighter than the
  // window content behind a popup, so the popup's 40% reads as plain
  // transparency there. A workspace that holds a window takes the 0.72
  // backing. One showing bare wallpaper is the only place the frosted material
  // is seen unobstructed, and backs off to 0.50 for the airy look: measured
  // over the live sky that leaves primary text 3.4 to 5.2 and secondary text
  // 2.2 to 3.4, so readings over the brightest cloud sit below the 4.5 target.
  // The empty bar is a deliberately softer surface there. dim stays reserved
  // for dark popups, and text is fully opaque either way.
  readonly property real barOpacity: 0.72
  readonly property real barEmptyOpacity: 0.50

  function barGlass(occupied) {
    const alpha = occupied ? theme.barOpacity : theme.barEmptyOpacity;
    return Qt.rgba(32 / 255, 33 / 255, 43 / 255, alpha);
  }

  readonly property color edge: Qt.rgba(1, 1, 1, 0.10)
  readonly property color separator: Qt.rgba(1, 1, 1, 0.10)
  readonly property color hover: Qt.rgba(1, 1, 1, 0.06)
  readonly property color selected: Qt.rgba(160 / 255, 187 / 255, 193 / 255, 0.10)
  readonly property color attentionFill: Qt.rgba(211 / 255, 187 / 255, 143 / 255, 0.12)

  readonly property string mono: "FiraCode Nerd Font Propo"
  readonly property string reading: "Noto Sans"
  // Twemoji is the emoji face the bar has always used for the flag.
  readonly property string emoji: "Twitter Color Emoji"
  // One type scale: quiet metadata, bar reading text, popup titles, and the
  // single large display numeral in the power popup.
  readonly property int fontMicro: 9
  readonly property int fontTiny: 10
  readonly property int fontSmall: 11
  readonly property int fontBody: 12
  readonly property int fontTitle: 13
  readonly property int fontLarge: 14
  // Panel headings carry the prototype's 17px voice; the rest of the scale
  // stays shared so bars, rows, and popups keep one rhythm.
  readonly property int fontHeading: 17
  readonly property int fontDisplay: 24

  readonly property int motion: 140

  // One spacing scale for bars, metrics, and panels: 4px rhythm, with 8px
  // inside a control, 12px between groups, and 20px panel reading edges.
  readonly property int space1: 4
  readonly property int space2: 8
  readonly property int space3: 12
  readonly property int space4: 16
  readonly property int space5: 20
  readonly property int panelPadding: space5

  // One icon scale. Every outline glyph in the shell picks a step from here
  // instead of carrying its own number; the tray keeps its own image size.
  readonly property int iconSmall: 12
  readonly property int iconSize: 14
  readonly property int iconMedium: 16
  readonly property int iconLarge: 24
  readonly property int iconDisplay: 28

  function appMark(appId) {
    if (!appId)
      return "·";

    const known = {
      "kitty": "\uf120",
      "foot": "\uf120",
      "Alacritty": "\uf120",
      "alacritty": "\uf120",
      "konsole": "\uf120",
      "xterm": "\uf120",
      "org.wezfurlong.wezterm": "\uf120",
      "com.mitchellh.ghostty": "\uf120",
      "firefox": "\uf269",
      "org.mozilla.firefox": "\uf269",
      "org.telegram.desktop": "\uf2c6",
      "telegram": "\uf2c6",
      "Slack": "\uf198",
      "slack": "\uf198",
      "Thunar": "\uf07b",
      "thunar": "\uf07b",
      "1Password": "\uf023",
      "1password": "\uf023"
    };

    const id = String(appId);
    if (known[id] !== undefined)
      return known[id];

    const lower = id.toLowerCase();
    for (const key in known) {
      if (key.toLowerCase() === lower)
        return known[key];
    }

    const generic = ["client", "desktop", "bin", "app", "apps", "gtk", "qt", "linux", "linuxdesktop"];
    const parts = id.replace(/^(org|com|io|dev|net|me)\./, "").split(".");
    let segment = parts[parts.length - 1] || "";
    for (let i = parts.length - 1; i >= 0; i--) {
      if (generic.indexOf(parts[i].toLowerCase()) === -1) {
        segment = parts[i];
        break;
      }
    }
    const short = segment.charAt(0);
    return short ? short.toUpperCase() : "·";
  }

  function centerX(item) {
    return item ? item.mapToItem(null, item.width / 2, 0).x : 0;
  }
}
