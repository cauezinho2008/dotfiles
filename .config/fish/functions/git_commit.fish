function git_commit --description 'git commit with gum input for message'
    set -l msg (gum input --width 50 --placeholder "Summary of changes")
    if test -n "$msg"
        git commit -m "$msg"
    else
        echo "Commit cancelled (empty message)"
    end
end
