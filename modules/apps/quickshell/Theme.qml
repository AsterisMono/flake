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
  // The OSD is one fixed width: the gauge keeps a single physical scale, and
  // the plate never changes size between "Muted", "Brightness" and a three
  // digit reading.
  readonly property int osdWidth: 288
  readonly property int radius: 3

  // Roles, not values. The primitives come from Stylix through the generated StylixPalette singleton, so
  // a scheme change is a theme change and nothing here repeats a hex literal.
  // Under Catppuccin Mocha: text base05, secondary text base04, blue base0D,
  // yellow base0A, red base08.
  //
  // There is no third text tier. base03 would be the next slot down, but it
  // measures 3.4:1 on an opaque base00 backing and every quiet string in this
  // shell is still meant to be read, so secondary labels, headings, timestamps
  // and "unavailable" readings all take base04 and hierarchy comes from size,
  // weight and spacing instead.
  readonly property color text: StylixPalette.base05
  readonly property color muted: StylixPalette.base04
  readonly property color accent: StylixPalette.base0D
  readonly property color attention: StylixPalette.base0A
  readonly property color critical: StylixPalette.base08

  // One alpha channel over a palette colour. The shell assumes the dark
  // polarity Stylix is pinned to: every surface is translucent glass over a
  // SwayFX-blurred background and text is fully opaque.
  function withAlpha(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha);
  }

  // Chosen glass option C: 40% backing opacity, fully opaque text.
  readonly property color glass: withAlpha(StylixPalette.base00, 0.40)
  // The bars sit on blurred wallpaper, which is often far brighter than the
  // window content behind a popup, so the popup's 40% reads as plain
  // transparency there. A workspace that holds a window takes the 0.72
  // backing. One showing bare wallpaper is the only place the frosted material
  // is seen unobstructed, and backs off to 0.50 for the airy look.
  //
  // Measured against the brightest region of each bar's own band on the
  // current wallpaper, the occupied bar leaves base05 at 7.3:1 and base04 at
  // 4.7:1, and the empty bar leaves them at 4.9:1 and 3.2:1, so primary text
  // clears 4.5:1 on both bars in both states. Secondary text still falls short
  // on the empty bar, and a popup or banner at 0.40 over the brightest pixel
  // anywhere leaves primary text at 2.2:1. A backing dense enough to clear
  // those too would hide the wallpaper the material exists to show, so the
  // shortfall is deliberate and still wants a capture on the real output
  // rather than a calculated sample.
  readonly property real barOpacity: 0.72
  readonly property real barEmptyOpacity: 0.50

  function barGlass(occupied) {
    const alpha = occupied ? theme.barOpacity : theme.barEmptyOpacity;
    return withAlpha(StylixPalette.base00, alpha);
  }

  // The one surface that does not take the 40% material. A popup is anchored
  // under its bar control and read at leisure; the OSD lands on whatever the
  // user is working in, at the bottom centre of an arbitrary window, and is
  // gone 1.2 s after the last change, so it is read once and in passing.
  // Composited over white at 85%, this scheme keeps primary text at 7.1:1 and
  // secondary text at 4.6:1, which is the pair the card actually relies on.
  // Like every number above, that is arithmetic over the palette rather than a
  // reading of a real output: the honest check is a capture with the card over
  // a white document.
  readonly property color osdGlass: withAlpha(StylixPalette.base00, 0.85)

  // Neutral overlays are the scheme's lightest text colour at low alpha rather
  // than white, so they carry the palette's tint and follow a polarity change.
  readonly property color edge: withAlpha(StylixPalette.base05, 0.10)
  readonly property color separator: withAlpha(StylixPalette.base05, 0.10)
  // An otherwise transparent row or icon that gains a fill on hover.
  readonly property color hover: withAlpha(StylixPalette.base05, 0.06)
  // A neutral control that carries a resting fill: not the same role as a row
  // hover, which is transparent until the pointer arrives.
  readonly property color fill: withAlpha(StylixPalette.base05, 0.08)
  readonly property color fillHover: withAlpha(StylixPalette.base05, 0.13)
  readonly property color fillPressed: withAlpha(StylixPalette.base05, 0.18)
  readonly property color border: withAlpha(StylixPalette.base05, 0.18)
  readonly property color borderHover: withAlpha(StylixPalette.base05, 0.28)
  // A functional track is a groove, not a divider: the panel behind a slider
  // can be as bright as the wallpaper, where a light rail, the fill and the
  // thumb all measure within 2:1 of each other. Going dark instead keeps the
  // rail at 4.5:1 against that panel and the fill at 6.8:1 against the rail.
  readonly property color track: withAlpha(StylixPalette.base00, 0.90)
  // The outline that keeps a light thumb readable over that same bright panel.
  // Shares the groove's value today, but it separates a control rather than
  // filling a track, so it is its own role.
  readonly property color thumbBorder: withAlpha(StylixPalette.base00, 0.90)
  readonly property color selected: withAlpha(StylixPalette.base0D, 0.10)
  readonly property color attentionFill: withAlpha(StylixPalette.base0A, 0.12)

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
