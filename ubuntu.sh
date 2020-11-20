#!/bin/sh

NO_ROOT=""
LOCAL=$HOME/.local
if [ -n "${BASH}" ]; then
  SHELL="bash"
  RC_FILE=$HOME/.bashrc
elif [ -n "${ZSH_NAME}" ]; then
  SHELL="zsh"
  RC_FILE=$HOME/.zshrc
fi
if [ $XDG_CONFIG_HOME ]; then
  CONFIG=$XDG_CONFIG_HOME
else
  CONFIG=$HOME/.config
fi
TMP_PATH=/tmp/vvk_tools

print_usage() {
  echo "$package - install useful tools for smoother development experience in the shell"
  echo " "
  echo "$package [options]"
  echo " "
  echo "options:"
  echo "-h, --help  show help"
  echo "-u, --user  Install in user (non-root) mode"
}

check_local_bin() {
    mkdir -p $LOCAL/bin
    case :$PATH: in
      *:$LOCAL/bin*) ;;
      *) echo "export PATH=$LOCAL/bin:$PATH" >> $RC_FILE
         export PATH=$LOCAL/bin:$PATH ;;
    esac
}

init_tmp() {
  mkdir -p $TMP_PATH
}

tmux() {
  if [ ! $NO_ROOT ]; then
    echo "Installing tmux"
    apt-get install -y --no-install-recommends tmux > /dev/null
    curl -s -fLo $HOME/.tmux.conf "https://vivekroy.com/tmux.conf"
  fi
}

zsh() {
  if [ ! $NO_ROOT ]; then
    echo "Installing zsh"
    apt-get install -y --no-install-recommends zsh > /dev/null
    curl -s -fsSL "https://starship.rs/install.sh" | zsh -s -- -y
    echo "$(starship init zsh)" >> $HOME/.zshrc
    curl -s -fLo $HOME/.config/starship.toml --create-dirs "https://vivekroy.com/starship.toml"
  fi
}

common_utils() {
  if [ ! $NO_ROOT ]; then
    echo "Installing common utils"
    apt-get install -y --no-install-recommends software-properties-common git curl tar > /dev/null
  fi
}

python() {
  if [ ! $NO_ROOT ]; then
    echo "Installing python"
    add-apt-repository -y ppa:deadsnakes/ppa > /dev/null
    apt-get install -y --no-install-recommends python3.8 > /dev/null
    ln -s /usr/bin/python3.8 /usr/bin/python
    apt-get install -y --no-install-recommends python3-setuptools > /dev/null
    python -m easy_install pip > /dev/null
    PYTHON_INSTALLED="true"
  fi
}

nvim() {
  echo "Installing NeoVim"
  if [ $NO_ROOT ]; then
    curl -s -fLo $LOCAL/bin/nvim --create-dirs \
      "https://github.com/neovim/neovim/releases/download/stable/nvim.appimage"
    chmod +x $LOCAL/bin/nvim
  else
    add-apt-repository -y ppa:neovim-ppa/stable > /dev/null
    apt-get -y update > /dev/null
    apt-get install -y --no-install-recommends neovim > /dev/null
  fi
  if [ $PYTHON_INSTALLED ]; then
    python -m pip install pynvim > /dev/null
  else
    python3 -m pip install pynvim > /dev/null
  fi
}

nvim_config() {
  echo "Installing NeoVim config"
  mkdir -p $CONFIG/nvim
  curl -s -fLo $LOCAL/share/nvim/site/autoload/plug.vim --create-dirs \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  git clone "https://github.com/thezealousfool/nvim.git" $CONFIG/nvim > /dev/null
  nvim --headless +'PlugInstall --sync' +qa > /dev/null
}

lazygit() {
  echo "Installing lazygit"
  if [ $NO_ROOT ]; then
    curl -s -fLo $TMP_PATH/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v0.20.9/lazygit_0.20.9_Linux_x86_64.tar.gz"
    tar -xf $TMP_PATH/lazygit.tar.gz -C $LOCAL/bin > /dev/null
  else
    add-apt-repository -y ppa:lazygit-team/release > /dev/null
    apt-get -y update > /dev/null
    apt-get install -y --no-install-recommends lazygit > /dev/null
  fi
}

binaries() {
  git clone "https://github.com/thezealousfool/tools_binaries.git" "$TMP_PATH/binaries" > /dev/null
}

ripgrep() {
  if ls "$TMP_PATH/binaries/" | egrep "rg-x86_64" > /dev/null 2>&1; then
    echo "Installing ripgrep"
    cp "$TMP_PATH/binaries/rg-x86_64"* $LOCAL/bin/rg
  else
    echo "Ripgrep binary not found"
  fi
}

exa() {
  if ls "$TMP_PATH/binaries/" | egrep "exa-x86_64" > /dev/null 2>&1; then
    echo "Installing exa "
    cp "$TMP_PATH/binaries/exa-x86_64"* $LOCAL/bin/exa
  else
    echo "exa binary not found"
  fi
}

autojump() {
  if ls "$TMP_PATH/binaries/" | egrep "autojump-x86_64" > /dev/null 2>&1; then
    echo "Installing autojump"
    cp "$TMP_PATH/binaries/autojump-x86_64"* $LOCAL/bin/autojump
  else
    echo "autojump binary not found"
    return
  fi
  if [ -f "$TMP_PATH/binaries/autojump.bash" ]; then
    echo "Installing autojump script"
    cat "$TMP_PATH/binaries/autojump.bash" >> $RC_FILE
    echo "" >> $RC_FILE
  else
    echo "autojump script file not found"
  fi
}

fd() {
  if ls "$TMP_PATH/binaries/" | egrep "fd-x86_64" > /dev/null 2>&1; then
    echo "Installing fd"
    cp "$TMP_PATH/binaries/fd-x86_64"* $LOCAL/bin/fd
    echo "export FZF_DEFAULT_COMMAND=\"fd --type file --color=always\"" >> $RC_FILE
    echo "export FZF_CTRL_T_COMMAND=\"$FZF_DEFAULT_COMMAND\"" >> $RC_FILE
    echo "export FZF_DEFAULT_OPTS=\"--ansi\"" >> $RC_FILE
    echo "" >> $RC_FILE
  else
    echo "fd binary not found"
  fi
}

alias() {
  echo "alias cl=clear" >> $RC_FILE
  echo "alias rt=reset" >> $RC_FILE
  echo "alias ls=exa" >> $RC_FILE
  echo "alias l=exa" >> $RC_FILE
  echo 'alias ll="exa -l"' >> $RC_FILE
  echo 'alias la="exa -al"' >> $RC_FILE
  echo 'alias lgit="lazygit"' >> $RC_FILE
  echo "export EDITOR=nvim" >> $RC_FILE

  echo "function cd {" >> $RC_FILE
  echo '    builtin cd "$@" && ls -F' >> $RC_FILE
  echo "  }" >> $RC_FILE
  echo "}" >> $RC_FILE
}

install_all() {
  check_local_bin
  init_tmp
  common_utils
  tmux
  zsh
  python
  nvim
  nvim_config
  lazygit
  binaries
  ripgrep
  exa
  autojump
  fd
  alias
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    -u|--user)
      NO_ROOT="true"
      shift
      ;;
    *)
      print_usage
      exit 1
      ;;
  esac
done

PWD=$(pwd)
install_all
source $RC_FILE
cd $PWD
