#!/usr/bin/env sh

set -o errexit -o nounset

DIR=/tmp/getch-master

if hash ruby 2>/dev/null ; then
  echo "Ruby is found"
else
  echo "Install ruby"
fi

cd /tmp
[ -f ./getch.tar.gz ] && rm ./getch.tar.gz
[ -d ./getch-master ] && rm -rf ./getch-master

curl -s -L -o getch.tar.gz https://github.com/szorfein/getch/archive/master.tar.gz
tar xvf getch.tar.gz

cd $DIR \
  && ruby -I lib bin/getch
