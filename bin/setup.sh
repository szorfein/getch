#!/usr/bin/env sh

set -o errexit -o nounset

DIR=/tmp/getch-master
PATH=${PATH}:/tmp/ruby/bin

# last snapshot https://www.ruby-lang.org/en/downloads/
compile_ruby() {
  PN=ruby
  PV=2.7
  [ -f /tmp/$PN_$PV.tar.gz ] || curl -s -L -o /tmp/$PN_$PV.tar.gz https://cache.ruby-lang.org/pub/ruby/snapshot/snapshot-$PN_$PV.tar.gz
  [ -d /tmp/snapshot-$PN_$PV ] || {
    cd /tmp
    tar xvf $PN_$PV.tar.gz
  }
  cd snapshot-$PN_$PV
  ./configure --prefix=/tmp/$PN
  make
  make install
}

search_ruby() {
  if hash ruby 2>/dev/null ; then
    echo "Ruby $(ruby -v | awk '{print $2}') found"
  else
    echo "Install ruby"
    if hash pacman 2>/dev/null ; then
      pacman -Syy libyaml ruby ruby-irb ruby-reline rubygems
    elif hash emerge 2>/dev/null ; then
      emerge -av dev-lang/ruby
    elif hash apt-get 2>/dev/null ; then
      apt-get install ruby
    else
      compile_ruby
    fi
  fi
}

get_getch() {
  if hash gem 2>/dev/null ; then
    gem install getch
    getch -h
  else
    cd /tmp
    [ -f ./getch.tar.gz ] && rm ./getch.tar.gz
    [ -d ./getch-master ] && rm -rf ./getch-master

    curl -s -L -o getch.tar.gz https://github.com/szorfein/getch/archive/master.tar.gz
    tar xzf getch.tar.gz \
      && cd $DIR \
      && ruby -I lib bin/getch -h
  fi
}

set_shell() {
  your_shell=~/.bashrc
  [ -f ~/.zshrc ] && your_shell=~/.zshrc

  [ -f "$your_shell" ] && {
    if ! grep -q ".gem/ruby/[0-9.]*/bin" "$your_shell" ; then
      echo "export PATH=\$PATH:$(ruby -e 'puts Gem.user_dir')/bin" >> "$your_shell"
    fi
    . "$your_shell"
  }
}

main() {
  search_ruby
  set_shell
  get_getch
}

main "$@"
