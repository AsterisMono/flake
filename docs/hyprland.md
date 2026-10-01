# Hyprland desktop

The workstation role and `stylix-test` use the Hyprland package from the locked NixOS release. Home Manager generates its Lua configuration from [the desktop aspect](../modules/apps/hyprland/default.nix) and [bindings](../modules/apps/hyprland/bindings.lua). UWSM manages the session; the display-manager entry is **Hyprland (uwsm-managed)**.

Bindings use the familiar Sway window controls from before commit `b0903cf`, with the later Noctalia adaptations. Hyprland's [dwindle layout](https://wiki.hypr.land/0.55.0/Configuring/Layouts/Dwindle-Layout/) replaces Sway's automatic splits: a wider focused window splits left/right, a taller one splits top/bottom, and existing splits can change direction as their geometry changes (`preserve_split = false`). New windows open to the right or below. Stylix supplies Rose Pine Moon colours, fonts and the cursor; Noctalia owns the wallpaper and shell. Window corners are 8 px, borders 2 px, outer gaps 12 px and shared inner gaps 12 px. Shadows are enabled with Hyprland's default geometry and the Stylix theme colour. Transparent windows and Noctalia surfaces use background blur.

Window opening and closing approximate Niri's defaults: opening scales from 50% to 100% with a simultaneous fade-in over 150 ms; closing scales from 100% to 80% with a fade-out over 150 ms. Opening uses a Bézier approximation of exponential ease-out; closing uses quadratic ease-out. Window movement/resizing and horizontal workspace/scratchpad transitions use critically damped springs (mass 1, stiffness 800 and 1000 respectively), with no fixed duration. Other inherited effects use 150 ms rather than Hyprland's built-in 800 ms fallback; gradient border rotation remains disabled and the internal colour-transform fade retains its default. Noctalia's matched layers still bypass compositor animations, and its own UI animation settings are unchanged.

| Shortcut | Action |
| --- | --- |
| `Super+H/J/K/L` or arrows | Focus left/down/up/right; left/right traverse grouped windows before leaving the group |
| Add `Shift` | Move the window in that direction |
| `Super+1…9/0` | Select workspace 1…9/10; selecting the current workspace returns to the previous one |
| Add `Shift` | Send the window to that workspace without following it |
| `Super+B` | Select a horizontal split for the next window |
| `Super+E` | Return a group to split tiling; toggling split direction requires `preserve_split = true` |
| `Super+F`, `Super+Shift+F` | Toggle maximized / fullscreen |
| `Super+R` | Resize mode: H/J/K/L or arrows; Escape or Return exits |
| `Super+S/W` | Use a group with stacked/tabbed titles |
| `Super+Shift+Space` | Toggle floating |
| `Super+Alt+Space` | Switch focus between floating and tiled windows |
| `Super+left/right mouse drag` | Move / resize the window |
| `Super+Minus`, `Super+Shift+Minus` | Show the scratchpad / send a window to it |
| `Super+Q/C` | Open Kitty / close the focused window |
| `Super+D` | Noctalia launcher |
| `Super+V` | Clipboard |
| `Super+Shift+S/A/P` | Region / annotated / fullscreen screenshot |
| `Super+Escape` | Lock, including in resize mode |
| `Super+Shift+C` | Reload the configuration |
| `Super+Shift+E` | Confirm logout through a notification, then end the UWSM session |

Volume, microphone mute, media and brightness keys use Noctalia and work while locked and in resize mode. Closing a laptop lid asks Noctalia to lock and suspend. Three-finger horizontal swipes retain Sway's workspace gesture.

Floating windows snap to nearby window and monitor edges while dragging. Closing a window returns focus to the most recently used window. Noctalia launches applications as independent systemd user services; its runtime settings can override the declarative base, so keep the corresponding launcher setting enabled in the GUI too.

Firefox picture-in-picture windows float, appear across workspaces, keep their aspect ratio when resized with the mouse, and remember their size for the compositor session. Focused Tencent Meeting windows inhibit idle; fullscreen mpv and gaming windows do so too. These are fallbacks, not meeting-state detection: an unfocused meeting relies on the application's own inhibitor or Noctalia's manual idle inhibitor. Noctalia notification layers and 1Password windows are excluded from screen sharing. XDPH screen sharing is limited to 60 fps, without changing display refresh rates or Noctalia's recording settings.

Hyprland groups approximate Sway's containers: their tab/stack title style applies to all groups, and they do not provide Sway's parent-container focus (`Super+A` is unbound). The special scratchpad workspace shows its floating windows together, whereas Sway cycles individual scratchpad windows. The historical Sway override already replaced `Super+V`'s vertical split with the clipboard. Niri's column, overview, workspace-cycle and wheel bindings are not retained. Hyprland's conflicting defaults yield to the existing keys; pseudotiling is unbound by choice. Hyprland does not provide Niri's automatic touchpad disabling when an external mouse is connected.

Parallax retains DP-1 at 3840×2160@120, scale 1.333333, position 1440×416, with workspace 1 assigned to it. DP-3 remains at 2560×1440, scale 1, rotated 270° and positioned at 0×0. Asymmetry retains its internal display at 2880×1800@120 and scale 1.75. These settings, VRR, suspend, fractional scaling, picture-in-picture and meeting window matching, capture exclusions and the shell's interactions need verification on the actual hosts after activation.
