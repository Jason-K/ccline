# ccline - fish integration.
#
# Install this as ~/.config/fish/conf.d/ccline.fish.
#
# When you type something that isn't a real command, fish hands the whole line
# to fish_command_not_found. A single unknown word is treated as a normal typo.
# Two or more words are treated as a thought and routed to the `ccline` helper.
#
# The helper renders the answer and shows the command menu, but it does NOT run
# the chosen command itself. It writes the selection to $CCLINE_RUN_FILE and
# this handler evals it in your live fish shell, where cd, set, aliases,
# functions, and history work as expected.

if functions -q fish_command_not_found
    if not functions -q __ccline_command_not_found
        if not functions -q __ccline_previous_fish_command_not_found
            functions -c fish_command_not_found __ccline_previous_fish_command_not_found
        end
    end
end

function __ccline_command_not_found
    if test (count $argv) -ge 2; and command -q ccline
        set -l tempdir /tmp
        if set -q TMPDIR; and test -n "$TMPDIR"
            set tempdir "$TMPDIR"
        end

        set -l runfile (mktemp "$tempdir/ccline.XXXXXX" 2>/dev/null)
        if test $status -ne 0; or test -z "$runfile"
            env CCLINE_SHELL=fish ccline $argv
            return $status
        end

        env CCLINE_SHELL=fish CCLINE_RUN_FILE="$runfile" ccline $argv
        set -l rc $status

        if test -s "$runfile"
            while read -l line
                test -n "$line"; or continue
                printf '$ %s\n' "$line"
                eval "$line"
                set rc $status
                if test "$rc" -ne 0
                    break
                end
            end < "$runfile"
        end

        rm -f "$runfile"
        return $rc
    end

    if functions -q __ccline_previous_fish_command_not_found
        __ccline_previous_fish_command_not_found $argv
    else if functions -q __fish_default_command_not_found_handler
        __fish_default_command_not_found_handler $argv
    else if test (count $argv) -ge 1
        printf 'fish: Unknown command: %s\n' "$argv[1]" >&2
    else
        printf 'fish: Unknown command\n' >&2
    end
    return 127
end

function fish_command_not_found
    __ccline_command_not_found $argv
end
