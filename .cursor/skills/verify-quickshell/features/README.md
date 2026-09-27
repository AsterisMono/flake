# Quickshell features

The surface is a real `quickshell` process running `modules/apps/quickshell/shell.qml` inside the headless Sway that `verify-quickshell launch` starts. The HTML prototype is not a feature.

| Feature | What it proves | Drive |
| --- | --- | --- |
| `work-fixture-flights` | The flights fixture paints both bars, and a pointer click on the work chip opens the tall Agents panel | `verify-quickshell drive work-fixture-flights` |
| `work-fixture-empty` | `QS_WORK_FIXTURE=empty` still opens the work panel, and that panel stays short | `verify-quickshell drive work-fixture-empty` |
| `shell-isolated-session` | The Wayland socket, Sway IPC socket, and process command lines stay inside this run's scratch directory | `verify-quickshell drive shell-isolated-session` |
| `qml-shell-entrypoint` | The running config's `shell.qml` is the repository file, ShellId `desk-bars` | `verify-quickshell drive qml-shell-entrypoint` |

Prove `work-fixture-flights` after a change to the bars, the work chip, or the fixture. The other rows are mapped so a later check can target them without rediscovering the shell.
