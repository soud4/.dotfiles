#
# ~/.bash_profile
#

export PATH="$HOME/.local/bin:$PATH"
export WLR_RENDERER=vulkan

# Source .bashrc for interactive login shells
if [[ -f ~/.bashrc ]]; then
    . ~/.bashrc
fi

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
