#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set bash history size to "unlimited" and to not store duplicate commands
export HISTSIZE=-1
export HISTFILESIZE=-1
export HISTCONTROL=ignoreboth

# Source .bashrc_*
[[ -f ~/.bashrc_commands ]] && . ~/.bashrc_commands
[[ -f ~/.bashrc_starship ]] && . ~/.bashrc_starship

