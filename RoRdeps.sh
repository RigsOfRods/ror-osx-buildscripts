#!/bin/sh

# Initialization
set -eu
. ./config

if [ ! -e "$ROR_SOURCE_DIR" ]; then
  mkdir -p "$ROR_SOURCE_DIR"
fi

# install brew if not already installed
if [ brew —-version 2>/dev/null ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# install dependencies available in brew repositories
brew install wget pkgconfig cmake git boost

# compile missing dependencies
# wxWidgets (only required for configurator, does not build on OS X 10.10)
#wget https://github.com/wxWidgets/wxWidgets/archive/WX_3_0_2.zip
#unzip WX_*.zip
#cd wxWidgets-*
#./configure
#make $ROR_MAKEOPTS

# dependencies of OGRE
cd "$ROR_SOURCE_DIR"
wget —c O ogredeps.zip https://bitbucket.org/cabalistic/ogredeps/get/tip.zip
unzip -o ogredeps.zip
cd cabalistic-ogredeps-*
cmake -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING= \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
.
make $ROR_MAKEOPTS
make install

#OGRE
cd "$ROR_SOURCE_DIR"
wget -c -O ogre.zip http://bitbucket.org/sinbad/ogre/get/v1-8.zip
unzip -o ogre.zip
cd sinbad-ogre-*
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCMAKE_BUILD_TYPE:STRING=Release \
-DOGRE_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install

PKG_CONFIG_PATH="$ROR_INSTALL_DIR/lib/pkgconfig"

#OpenAL Soft
wget -c http://kcat.strangesoft.net/openal-releases/openal-soft-1.16.0.tar.bz2
tar -xvf openal-soft-*.tar.bz2
cd openal-soft-*
cmake .
make $ROR_MAKEOPTS
make install

#MyGUI (needs specific revision)
cd "$ROR_SOURCE_DIR"
wget -c -O mygui.zip https://github.com/MyGUI/mygui/archive/a790944c344c686805d074d7fc1d7fc13df98c37.zip
unzip -o mygui.zip
cd mygui-*
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCMAKE_BUILD_TYPE:STRING=Release \
-DMYGUI_BUILD_DEMOS:BOOL=OFF \
-DMYGUI_BUILD_DOCS:BOOL=OFF \
-DMYGUI_BUILD_TEST_APP:BOOL=OFF \
-DMYGUI_BUILD_TOOLS:BOOL=OFF \
-DMYGUI_BUILD_PLUGINS:BOOL=OFF .
make $ROR_MAKEOPTS
make install

#Paged Geometry
cd "$ROR_SOURCE_DIR"
if [ ! -e ogre-paged ]; then
  git clone --depth=1 https://github.com/Hiradur/ogre-paged.git
fi
cd ogre-paged
git pull
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCMAKE_BUILD_TYPE:STRING=Release \
-DPAGEDGEOMETRY_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install

#Caelum (needs specific revision for OGRE-1.8)
cd "$ROR_SOURCE_DIR"
wget -c -O caelum.zip http://caelum.googlecode.com/archive/3b0f1afccf5cb75c65d812d0361cce61b0e82e52.zip
unzip -o caelum.zip
cd caelum-*
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCaelum_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install
# important step, so the plugin can load:
ln -sf "$ROR_INSTALL_DIR/lib/libCaelum.so" "$ROR_INSTALL_DIR/lib/OGRE/"

#MySocketW
cd "$ROR_SOURCE_DIR"
if [ ! -e mysocketw ]; then
  git clone --depth=1 https://github.com/Hiradur/mysocketw.git
fi
cd mysocketw
git pull
sed -i '/^PREFIX *=/d' Makefile.conf
make $ROR_MAKEOPTS shared
PREFIX="$ROR_INSTALL_DIR" make install

# Angelscript TODO: check install dir
cd "$ROR_SOURCE_DIR"
if [ ! -e angelscript ]; then
  mkdir angelscript
fi
cd angelscript
wget -c http://www.angelcode.com/angelscript/sdk/files/angelscript_2.22.1.zip
unzip -o angelscript_*.zip
cd sdk/angelscript/projects/gnuc macosx
sed -i '/^LOCAL *=/d' makefile
# make fails when making the symbolic link, this removes the existing versions
rm -f ../../lib/*
make $ROR_MAKEOPTS
rm -f ../../lib/*
LOCAL="$ROR_INSTALL_DIR" make -s install


