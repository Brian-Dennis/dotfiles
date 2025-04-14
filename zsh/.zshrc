# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1500
SAVEHIST=1500

export PATH="$HOME/.local/bin:$PATH"
export VISUAL="nvim" # Or gedit, or another installed editor
export EDITOR="$VISUAL"

eval "$(oh-my-posh --init --shell zsh --config ~/.poshthemes/atomic.omp.json)"

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

alias ls='eza' # or alias ls='eza -l' for a simpler list
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
