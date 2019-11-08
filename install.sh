#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  authy
  dropbox
  google-chrome
  hyper
  istat-menus
  spotify
  franz
  slack
)

brews=(
  xonsh
  jabba
  awscli
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  bat
  coreutils
  dfc
  exa
  findutils
  "fontconfig --universal"
  fpp
  git
  git-extras
  git-fresh
  git-lfs
  "gnuplot --with-qt"
  "gnu-sed --with-default-names"
  go
  gpg
  #haskell-stack
  hh
  #hosts
  htop
  httpie
  iftop
  "imagemagick --with-webp"
  lighttpd
  lnav
  m-cli
  mackup
  macvim
  mas
  micro
  moreutils
  mtr
  ncdu
  neofetch
  nmap  
  node
  poppler
  postgresql
  pgcli
  pv
  python
  python3
  osquery
  ruby
  scala
  sbt
  shellcheck
  stormssh
  teleport
  thefuck
  tmux
  tree
  trash
  "vim --with-override-system-vi"
  #volumemixer
  "wget --with-iri"
  xsv
)

casks=(
  aerial
  adobe-acrobat-pro
  #airdroid
  cakebrew
  cleanmymac
  docker
  expressvpn
  geekbench
  google-backup-and-sync
  github
  handbrake
  iina
  istat-server  
  launchrocket
  kap-beta
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  macdown
  #muzzle
  plex-media-player
  plex-media-server
  private-eye
  satellite-eyes
  sidekick
  #skype
  sloth
  #steam
  transmission
  transmission-remote-gui
  xquartz
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

gems=(
  bundler
  travis
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
)

#gpg_key='3E219504'
git_email='david.lequin@gmail.com'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "remote.origin.prune true"
  "rerere.enabled true"
  "user.name pathikrit"
  "user.email ${git_email}"
)

fonts=(
  font-fira-code
  font-source-code-pro
)


######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap caskroom/versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

if [[ -z "${CI}" ]]; then
  gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  prompt "Export key to Github"
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi  

prompt "Upgrade bash"
brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
#sudo chsh -s "$(brew --prefix)"/bin/bash

touch ~/.bash_profile 
#see https://github.com/twolfson/sexy-bash-prompt/issues/51
# (cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc

echo "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
alias ls='ls -lah'
alias ll='ls -lah'
alias del='mv -t ~/.Trash/'
#alias ls='exa -l'
alias cat=bat
# updates PATH for the Google Cloud SDK.
if [ -f '/Users/davidlequin/exec -l /bin/bash/google-cloud-sdk/path.bash.inc' ]; then . '/Users/davidlequin/exec -l /bin/bash/google-cloud-sdk/path.bash.inc'; fi
# enables shell command completion for gcloud.
if [ -f '/Users/davidlequin/exec -l /bin/bash/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/davidlequin/exec -l /bin/bash/google-cloud-sdk/completion.bash.inc'; fi
" >> ~/.bash_profile
cat bash_promt >> ~/.bash_profile

prompt "Setting up xonsh"
sudo bash -c "which xonsh >> /private/etc/shells"
sudo chsh -s $(which xonsh)
echo "source-bash --overwrite-aliases ~/.bash_profile" >> ~/.xonshrc

prompt "Install software"
install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

prompt "Changle Slack to dark"
cd ~/Downloads
git clone https://github.com/LanikSJ/slack-dark-mode
cd slack-dark-mode
./slack-dark-mode.sh 

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
