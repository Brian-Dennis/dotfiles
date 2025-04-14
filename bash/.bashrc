#
# ~/.bashrc
#
export VISUAL="nvim" # Or gedit, or another installed editor
export EDITOR="$VISUAL"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
