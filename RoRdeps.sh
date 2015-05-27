#!/bin/sh

# Initialization
#set -eu   some commands show errors which don't affect the build
. ./config

# install build tools
xcode-select --install

if [ ! -e "$ROR_SOURCE_DIR" ]; then
  mkdir -p "$ROR_SOURCE_DIR"
fi

# install brew if not already installed
if [ brew —-version 2>/dev/null ]; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# install dependencies available in brew repositories
brew install wget pkgconfig cmake git boost wxwidgets openal-soft

# compile missing dependencies

# dependencies of OGRE
cd "$ROR_SOURCE_DIR"
wget —c O ogredeps.zip https://bitbucket.org/cabalistic/ogredeps/get/tip.zip
unzip -o ogredeps.zip
cd cabalistic-ogredeps-*
cmake -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING= \
-DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
-DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DOGREDEPS_BUILD_CG:BOOL=TRUE \
.
make $ROR_MAKEOPTS
make install

#OGRE
cd "$ROR_SOURCE_DIR"
wget -c -O ogre.zip http://bitbucket.org/sinbad/ogre/get/v1-8.zip
unzip -o ogre.zip
cd sinbad-ogre-*

# Apply patch for OS X 10.10
wget https://gist.github.com/Hiradur/a5573323ae2701bef6bc/download
patch -p1 < ogre1.8osx.patch

cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DCMAKE_BUILD_TYPE:STRING=Release \
-DOGRE_STATIC=1 \
-DOGRE_BUILD_SAMPLES:BOOL=OFF .
make $ROR_MAKEOPTS
make install


PKG_CONFIG_PATH="$ROR_INSTALL_DIR/lib/pkgconfig"

#OpenAL Soft (only required if the one from brew doesn't work)
#cd "$ROR_SOURCE_DIR"
#wget -c http://kcat.strangesoft.net/openal-releases/openal-soft-1.16.0.tar.bz2
#tar -xvf openal-soft-*.tar.bz2
#cd openal-soft-*
#cmake .
#make $ROR_MAKEOPTS
#make install

#MyGUI (needs specific revision)
cd "$ROR_SOURCE_DIR"
wget -c -O mygui.zip https://github.com/MyGUI/mygui/archive/a790944c344c686805d074d7fc1d7fc13df98c37.zip
unzip -o mygui.zip
cd mygui-*
cmake -DCMAKE_INSTALL_PREFIX="$ROR_INSTALL_DIR" \
-DMYGUI_STATIC:BOOL=ON \
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


