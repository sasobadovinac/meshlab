#!/bin/bash
# This is a script shell for deploying a meshlab-portable folder and create an AppImage.
# Requires a properly built MeshLab (see 1_build.sh).
#
# Without given arguments, the folder that will be deployed is meshlab/install, which
# should be the path where MeshLab has been installed (default output of 1_build.sh).
# The AppImage will be placed in the directory where the script is run.
#
# You can give as argument the path where you installed MeshLab.

SCRIPTS_PATH="$(dirname "$(realpath "$0")")"
RESOURCES_PATH=$SCRIPTS_PATH/../../resources
INSTALL_PATH=$SCRIPTS_PATH/../../install
QT_DIR=""

#checking for parameters
for i in "$@"
do
case $i in
    -i=*|--install_path=*)
        INSTALL_PATH="${i#*=}"
        shift # past argument=value
        ;;
    -qt=*|--qt_dir=*)
        QT_DIR=${i#*=}
        shift # past argument=value
        ;;
    *)
        # unknown option
        ;;
esac
done

bash $SCRIPTS_PATH/internal/make_bundle.sh -i=$INSTALL_PATH

if [ ! -z "$QT_DIR" ]
then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$QT_DIR/lib
    export QMAKE=$QT_DIR/bin/qmake
fi

chmod +x $INSTALL_PATH/usr/bin/meshlab

for plugin in $INSTALL_PATH/usr/lib/meshlab/plugins/*.so
do
    # allow plugins to find linked libraries in usr/lib, usr/lib/meshlab and usr/lib/meshlab/plugins
    patchelf --set-rpath '$ORIGIN/../../:$ORIGIN/../:$ORIGIN' $plugin
done

$RESOURCES_PATH/linux/linuxdeploy --appdir=$INSTALL_PATH \
  --plugin qt

# after deploy, all required libraries are placed into usr/lib, therefore we can remove the ones in
# usr/lib/meshlab (except for the ones that are loaded at runtime)
shopt -s extglob
cd $INSTALL_PATH/usr/lib/meshlab
rm -v !("libIFXCore.so"|"libIFXExporting.so"|"libIFXScheduling.so")

#at this point, distrib folder contains all the files necessary to execute meshlab
echo "$INSTALL_PATH is now a self contained meshlab application"
