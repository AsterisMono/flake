# Workspaces and tasks

Workspaces and tasks are the bottom bar: a button per Sway workspace, then one button per window title. Choosing a window button focuses that window. The overflow control appears only when the titles do not fit.

## Sub-features

- `task-appears` shows a newly opened window's title on the bottom bar.
- `task-matches-tree` uses the same title Sway reports for that window.
- `task-closes` removes the button after the window closes, without deleting a different window.

## How to get to it (user POV)

- Open a window in the Sway session. Its title shows on the bottom bar.
- Choose the workspace number on the left of the bottom bar to switch workspace.
- Choose the window title to focus it. Middle-click requests close.
- When titles overflow, choose the `…` control to open the window list.

## Driving it with verify-quickshell

Preconditions:

- `verify-quickshell doctor` prints `doctor=ok` on a one-output launch.
- The session's `PATH` includes `foot` (the harness nix shell does).

- **Open a titled window.** Run `.cursor/skills/verify-quickshell/bin/verify-quickshell drive workspaces-and-tasks`. The harness runs `swaymsg exec foot --title "Verify task"` inside the isolated compositor. `evidence/workspaces-and-tasks/tree.json` contains a node named `Verify task`.
- **Read the bar.** `tasks.ocr.txt` contains `Verify task`. `tasks.png` is the frame that was read. `tree.json` contains a node named `Verify task`.
- **Close it.** After the OCR succeeds, the harness runs `swaymsg '[title="Verify task"] kill'`. A following `swaymsg -t get_tree` in the same session no longer needs that title; the evidence of the kill is the command completing in the drive's exit.

## Gotchas

- Workspace buttons come from the Sway IPC connection (`SWAYSOCK` of this session). A quickshell pointed at the user's real socket would change the user's desktop. Doctor checks the runtime directory before this drive.
- The verification compositor starts on workspace 1 with no user windows. Titles other than `Verify task` are not part of the proof.
- Task order follows workspace, then window position. One window cannot demonstrate reorder. Do not claim order stability from this drive.
- Middle-click close and the `…` overflow list are not driven here. One foot window fits on a 1920-wide bar, so the overflow control stays hidden. Say they were not driven.
- Stock sway has no SwayFX blur. The title text is the proof, not the bar material.
