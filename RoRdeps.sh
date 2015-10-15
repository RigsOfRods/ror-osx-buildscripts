#!/bin/sh

# Initialization
set -eu
. ./config

# install build tools if not already installed
if [ xcode-select --version 2>/dev/null ]; then
  xcode-select --install
fi

if [ ! -e "$ROR_SOURCE_DIR" ]; then
  mkdir -p "$ROR_SOURCE_DIR"
fi

# install brew if not already installed
if [ brew --version 2>/dev/null ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# install dependencies available in brew repositories
brew install wget pkgconfig cmake wxwidgets openal-soft mercurial
brew install boost --c++11

# compile missing dependencies

# dependencies of OGRE
cd "$ROR_SOURCE_DIR"
if [ ! -e ogredeps ]; then
  hg clone https://bitbucket.org/cabalistic/ogredeps
fi
cd ogredeps
hg pull && hg update
# remove OSX_DEPLOYMENT_TARGET so we can build with libc++ (requires 10.7+)
sed -i .orig 's/set(CMAKE_OSX_DEPLOYMENT_TARGET 10.6)//g' CMakeLists.txt
cmake \
-DCMAKE_OSX_DEPLOYMENT_TARGET= \
-DCMAKE_CXX_FLAGS="-stdlib=libc++ -std=c++11" \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
.
make $ROR_MAKEOPTS
make install

# OGRE
cd "$ROR_SOURCE_DIR"
if [ ! -e ogre ]; then
  hg clone https://bitbucket.org/sinbad/ogre -b v1-9
fi
cd ogre
hg pull -r 1-9 && hg update
cmake \
-DCMAKE_CXX_FLAGS="-stdlib=libc++ -std=c++11" \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DFREETYPE_INCLUDE_DIR=/usr/include/freetype2/ \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DOGRE_BUILD_RENDERSYSTEM_GL3PLUS=ON \
-DOGRE_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install

# MyGUI
cd "$ROR_SOURCE_DIR"
if [ ! -e mygui ]; then
  git clone https://github.com/MyGUI/mygui.git
fi
cd mygui
git pull
cmake \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCMAKE_CXX_FLAGS="-stdlib=libc++ -std=c++11" \
-DFREETYPE_INCLUDE_DIR=/usr/include/freetype2/ \
-DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DMYGUI_BUILD_DEMOS:BOOL=OFF \
-DMYGUI_BUILD_DOCS:BOOL=OFF \
-DMYGUI_BUILD_TEST_APP:BOOL=OFF \
-DMYGUI_BUILD_TOOLS:BOOL=OFF \
-DMYGUI_BUILD_PLUGINS:BOOL=OFF .
make $ROR_MAKEOPTS
make install

# Paged Geometry
cd "$ROR_SOURCE_DIR"
if [ ! -e ogre-paged ]; then
  git clone https://github.com/Hiradur/ogre-paged.git
fi
cd ogre-paged
git pull
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DPAGEDGEOMETRY_BUILD_SAMPLES:BOOL=OFF \
-DCMAKE_CXX_FLAGS="-stdlib=libc++ -std=c++11" \
-DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo .
make $ROR_MAKEOPTS
make install

# Caelum
cd "$ROR_SOURCE_DIR"
if [ ! -e caelum ]; then
  git clone https://github.com/RigsOfRods/caelum
fi
cd caelum
git pull
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" 
-DCMAKE_CXX_FLAGS="-stdlib=libc++ -std=c++11" \
.
make $ROR_MAKEOPTS
make install
# important step, so the plugin can load:
ln -sf "$ROR_INSTALL_DIR/lib/libCaelum.so" "$ROR_INSTALL_DIR/lib/OGRE/"

# MySocketW
cd "$ROR_SOURCE_DIR"
if [ ! -e mysocketw ]; then
  git clone https://github.com/Hiradur/mysocketw.git
fi
cd mysocketw
git pull
sed -i .orig '/^PREFIX *=/d' Makefile.conf
make CXXFLAGS="-stdlib=libc++ -std=c++11" $ROR_MAKEOPTS dylib
PREFIX="$ROR_INSTALL_DIR" make installosx

# Angelscript
cd "$ROR_SOURCE_DIR"
if [ ! -e angelscript ]; then
  mkdir angelscript
fi
cd angelscript
wget -c http://www.angelcode.com/angelscript/sdk/files/angelscript_2.22.1.zip
unzip -o angelscript_*.zip
cd "sdk/angelscript/projects/gnuc macosx"
sed -i .orig '/^LOCAL *=/d' makefile
# make fails when making the symbolic link, this removes the existing versions
rm -f ../../lib/*
SHARED=1 VERSION=2.22.1 make CFLAGS="-stdlib=libc++ -std=c++11" CXXFLAGS="-stdlib=libc++ -std=c++11" $ROR_MAKEOPTS
rm -f ../../lib/*
SHARED=1 VERSION=2.22.1 LOCAL="$ROR_INSTALL_DIR" make -s install