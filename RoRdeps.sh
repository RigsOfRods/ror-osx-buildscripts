#!/bin/sh

# Initialization
set -eu
. ./config

# install build tools if not already installed
if  xcode-select —-version 2>/dev/null ]; then
  xcode-select --install
fi

if [ ! -e "$ROR_SOURCE_DIR" ]; then
  mkdir -p "$ROR_SOURCE_DIR"
fi

# install brew if not already installed
if [ brew —-version 2>/dev/null ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# install dependencies available in brew repositories
brew install wget pkgconfig cmake boost wxwidgets openal-soft mercurial

# compile missing dependencies

# dependencies of OGRE
cd "$ROR_SOURCE_DIR"
if [ ! -e ogredeps ]; then
  hg clone https://bitbucket.org/cabalistic/ogredeps
fi
cd ogredeps
hg pull
cmake -DCMAKE_OSX_DEPLOYMENT_TARGET= \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \.
make $ROR_MAKEOPTS
make install

# OGRE
cd "$ROR_SOURCE_DIR"
if [ ! -e ogre ]; then
  hg clone https://bitbucket.org/sinbad/ogre -b v2-0
fi
cd ogre
hg pull
cmake \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DFREETYPE_INCLUDE_DIR=/usr/include/freetype2/ \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DOGRE_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install

# MyGUI
cd "$ROR_SOURCE_DIR"
if [ ! -e mygui ]; then
  git clone https://github.com/MyGUI/mygui.git
fi
cd mygui
git checkout ogre2
git pull
cmake \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DFREETYPE_INCLUDE_DIR=/usr/include/freetype2/ \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DMYGUI_BUILD_DEMOS:BOOL=OFF \
-DMYGUI_BUILD_DOCS:BOOL=OFF \
-DMYGUI_BUILD_TEST_APP:BOOL=OFF \
-DMYGUI_BUILD_TOOLS:BOOL=OFF \
-DMYGUI_BUILD_PLUGINS:BOOL=OFF .
make $ROR_MAKEOPTS
make install

#MySocketW
cd "$ROR_SOURCE_DIR"
if [ ! -e mysocketw ]; then
  git clone https://github.com/Hiradur/mysocketw.git
fi
cd mysocketw
git pull
sed -i '/^PREFIX *=/d' Makefile.conf
make $ROR_MAKEOPTS shared
PREFIX="$ROR_INSTALL_DIR" make install
