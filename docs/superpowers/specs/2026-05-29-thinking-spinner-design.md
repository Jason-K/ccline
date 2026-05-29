# Thinking spinner

## Goal

After the user submits a thought, show a small ASCII "thinking" animation while
ccline waits for the LLM, so the wait doesn't look frozen.

## Behavior

- A braille spinner cycles `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏` next to the label `thinking…`,
  redrawn in place (`\r`) at ~10 fps, dimmed (`\e[2m`), cursor hidden.
- It runs only while interactive (`[ -t 1 ]`). When stdout is a pipe or file,
  there is no spinner and behavior is unchanged.
- It appears during the blocking LLM call in `ccline_main`
  (`answer="$("ccline_ask_${backend}" …)"`) and is removed before the answer
  renders. The cleared line leaves no trace.

## Design

`ccline_spinner` — infinite loop drawing frames to **`/dev/tty`**. Drawing to
`/dev/tty` (never stdout/stderr) is required because the answer is captured via
`$(...)`; any spinner bytes on stdout would corrupt the captured answer.

`ccline_main` wiring:
- Start `ccline_spinner &` only when `[ -t 1 ]`; capture its PID.
- Run the LLM call, then `kill` the spinner, `wait` it (suppress job message),
  and clear the line (`\r\e[K`) + restore cursor (`\e[?25h`) on `/dev/tty`.
- A `trap` (INT/EXIT) for the duration kills the spinner and restores the
  cursor, so Ctrl-C never leaves a hidden cursor or a stray frame.

## Testing

Existing end-to-end tests run `ccline_main` with stdout captured (non-tty), so
they already prove the answer stays clean. Add one explicit assertion that a
non-interactive run emits no spinner bytes into the captured output.
