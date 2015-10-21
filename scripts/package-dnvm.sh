#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

REPOROOT="$( cd -P "$DIR/.." && pwd )"

if [ -z "$RID" ]; then
    UNAME=$(uname)
    if [ "$UNAME" == "Darwin" ]; then
        OSNAME=osx
        RID=osx.10.10-x64
    elif [ "$UNAME" == "Linux" ]; then
        # Detect Distro?
        OSNAME=linux
        RID=ubuntu.14.04-x64
    else
        echo "Unknown OS: $UNAME" 1>&2
        exit 1
    fi
fi

if [ -z "$DOTNET_BUILD_VERSION" ]; then
    TIMESTAMP=$(date "+%Y%m%d%H%M%S")
    DOTNET_BUILD_VERSION=0.0.1-alpha-t$TIMESTAMP
fi

STAGE2_DIR=$REPOROOT/artifacts/$RID/stage2

if [ ! -d "$STAGE2_DIR" ]; then
    echo "Missing stage2 output in $STAGE2_DIR" 1>&2
    exit
fi

PACKAGE_DIR=$REPOROOT/artifacts/packages/dnvm
[ -d "$PACKAGE_DIR" ] || mkdir -p $PACKAGE_DIR

PACKAGE_NAME=$PACKAGE_DIR/dotnet-${OSNAME}-x64.${DOTNET_BUILD_VERSION}.tar.gz

cd $STAGE2_DIR

# Correct all the mode flags

# Managed code doesn't need 'x'
find . -type f -name "*.dll" | xargs chmod 644
find . -type f -name "*.exe" | xargs chmod 644

# Generally, dylibs and sos have 'x' (no idea if it's required ;))
if [ "$OSNAME" == "osx" ]; then
    find . -type f -name "*.dylib" | xargs chmod 744
else
    find . -type f -name "*.so" | xargs chmod 744
fi

# Executables (those without dots) are executable :)
find . -type f ! -name "*.*" | xargs chmod 755

# Tar up the stage2 artifacts
tar -czf $PACKAGE_NAME *

echo "Packaged stage2 to $PACKAGE_NAME"