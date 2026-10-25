function git --description 'git wrapper with gum-powered commit'
    if test "$argv[1]" = "commit" -a (count $argv) -eq 1
        set -l msg (gum input --width 50 --placeholder "Summary of changes")
        if test -n "$msg"
            command git commit -m "$msg"
        else
            echo "Commit cancelled (empty message)"
        end
    else
        command git $argv
    end
end
