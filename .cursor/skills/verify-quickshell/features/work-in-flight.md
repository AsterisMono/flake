# Work in flight

Work in flight is the V2 summary at the right of the bottom bar and the panel it opens. Rows are herdr's current agents, grouped as Needs you, Ready when you are, and In progress. The shell does not start, stop, or approve an agent.

## Sub-features

- `work-summary` shows the flights fixture counts on the bottom bar: working, idle, and need you.
- `work-no-focus` does not change the focused Sway window while the summary is read.
- `work-no-socket` does not open a herdr socket while the fixture is selected.
- `work-panel` would open from a click on that summary. This toolchain cannot send that click.

## How to get to it (user POV)

- On a workstation with herdr, the bottom-right summary appears when herdr has agents worth returning to. Choose it to open the panel. Choose a row's open action to ask herdr to focus that agent. Opening the panel itself does not focus anything.
- Without herdr, the section is absent. V1 bars still work.
- For an offline check, the shell reads `QS_WORK_FIXTURE` (`flights`, `followup`, `disconnected`, `ended`, `empty`, `incompatible`, or `idle`). Those strings are sample data in `FixtureSource.qml`.

## Driving it with verify-quickshell

Preconditions:

- Launch used the default `--fixture flights` (or an explicit `--fixture flights`).
- `verify-quickshell doctor` prints `doctor=ok`.
- `config-provenance.txt` says `herdr_endpoint=blank` or `herdr_endpoint=rewritten-blank`, and `account_usage=stub` or `account_usage=rewritten-stub`.

- **Read the summary.** Run `.cursor/skills/verify-quickshell/bin/verify-quickshell drive work-in-flight`. `summary.ocr.txt` contains `working` and `need you`. `summary.png` is the frame that was read. The flights fixture's full wording is `1 working`, `2 idle`, and `2 need you`.
- **Focus stayed put.** `focused-before.txt` and `focused-after.txt` are the same id.
- **Socket stayed closed.** `fds.txt` is the quickshell file-descriptor list and does not contain `herdr.sock`.
- **Panel not opened.** `panel-blocker.txt` says `panel=not-driven`. Do not report the panel, the `Needs you` heading, or `Sample data · fixture mode (flights)` as verified by this drive.

## Gotchas

- The bar OCR often glues the words (`1working`, `2need you`). Assert the substrings `working` and `need you`, not a single exact line.
- Opening the panel needs a click. `wlrctl` 0.2.2 cannot address a pixel, and `ydotoold` found no `/dev/uinput` on the cloud VM. The panel's `Needs you` heading and `Sample data · fixture mode (flights)` line are the proof on a machine that can click. They are not proved here.
- `done` means herdr says ready to review. The fixture must not be described as tests passing.
- The panel also starts account-usage reads. The harness points those at a stub that does not read secrets and does not call the network. A module config is rewritten the same way. Do not set `VERIFY_QUICKSHELL_LIVE_ACCOUNTS`.
- Choosing a row in fixture mode reports a sample focus and does not raise a window. This drive does not click a row. Do not claim `agent.focus` was proven.
- `disconnected`, `empty`, and `incompatible` are separate launches (`--fixture disconnected` and so on). Do not report them as covered by `flights`.
- Live herdr on the user's socket is a maintainer session, not this drive. The shell must keep using the fixture source line if the proof is the fixture.
- Cleanup must not delete `summary.png` or `summary.ocr.txt`.
