source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/caue/.lmstudio/bin
# End of LM Studio CLI section
oh-my-posh init fish --config '/home/caue/.config/fish/oh_my_posh/blueish.omp.json' | source
