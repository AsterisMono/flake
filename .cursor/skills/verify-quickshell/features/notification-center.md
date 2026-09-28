# Notification center

Notification center is the bell at the right end of the top bar. It lists session notifications. Opening it marks presented entries read. It does not run notification actions by itself.

## Sub-features

- `notify-receive` accepts a normal notification on the shell's notification server.
- `notify-open` shows that notification's title in the panel opened from the bell.
- `notify-not-logout` uses a harmless stand-in title and does not invoke an action.

## How to get to it (user POV)

- An application sends a notification. A banner can appear. The bell remains the way into the history panel.
- Choose the bell, the last control on the top bar. The panel is titled `Notifications`.
- Choose Dismiss or Clear all to drop local history. There is no Undo.

## Driving it with verify-quickshell

Preconditions:

- `verify-quickshell doctor` prints `doctor=ok`.
- The private session bus from launch is still the quickshell process's `DBUS_SESSION_BUS_ADDRESS`.
- No logout notification is part of the fixture. The only title used here is `Verify notice`.

- **Send and open.** Run `.cursor/skills/verify-quickshell/bin/verify-quickshell drive notification-center`. The command exits non-zero and writes `evidence/notification-center/blocker.txt`. The bell is a click, and this toolchain cannot click. A machine that can click would send `notify-send --app-name=verify-quickshell "Verify notice" "Stored for the panel"` on the private bus and then read `Verify notice` in the panel. Do not send a logout action to get a result another way.

## Gotchas

- The HTML prototype's bell is not this panel. Do not drive the prototype.
- On a logged-in workstation the shell owns `org.freedesktop.Notifications`. This drive uses the harness bus so it cannot satisfy, or steal, the user's notification daemon. A pass here does not prove the host unit replaced Mako.
- Critical notifications and Do Not Disturb are not driven. Do not send `notify-send --urgency=critical` with an action that logs out. The Sway logout binding depends on a critical action named `Log out`; automating that action is a real logout.
- History is session-local and capped. Cleanup kills the shell, which drops the history. The screenshot is the record that remains.
- If `notify-send` cannot find the server, the drive fails. Do not point it at the user's bus to "make it pass".
