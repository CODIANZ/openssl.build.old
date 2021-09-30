#!/bin/sh

# ANDROID_NDK_HOME はインストールに応じて変更
export ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/23.0.7599858
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH 

OPENSSL_VER=1.1.1l
OPENSSL_DIR=openssl-${OPENSSL_VER}
OPENSSL_FILE=openssl-${OPENSSL_VER}.tar.gz
OPENSSL_LIBS=libs.android

if [ ! -f ${OPENSSL_FILE} ]; then
  curl -L https://www.openssl.org/source/${OPENSSL_FILE} > ${OPENSSL_FILE}
fi


if [ ! -e ${OPENSSL_DIR} ]; then
    tar xvfz ${OPENSSL_FILE}
fi


if [ -e ${OPENSSL_LIBS} ]; then
    rm -rf .${OPENSSL_LIBS}
fi

function buildOne {
    APIVER=$1
    ARCH=$2
    CONFARCH=$3

    make clean
    ./Configure reconfigure

    ./Configure $CONFARCH \
        --cross-compile-prefix=$ARCH-linux-androideabi$APIVER \
        -D__ANDROID_API__=$APIVER \
        CC=clang \
        no-shared \
        no-tests \
        no-ui \
        no-stdio

    make

    if [ ! -e ./dist/$OPENSSL_DIR/lib/$ARCH ]; then
        mkdir -p ./dist/$OPENSSL_DIR/lib/$ARCH
    fi
    cp libcrypto.a ./dist/$OPENSSL_DIR/lib/$ARCH
    cp libssl.a    ./dist/$OPENSSL_DIR/lib/$ARCH
}

pushd $OPENSSL_DIR

if [ -e ./dist ]; then
    rm -rf ./dist
fi


buildOne 26 armeabi-v7a android-arm
buildOne 26 x86_64      android-x86_64
buildOne 26 x86         android-x86
buildOne 26 arm64-v8a   android-arm64

if [ ! -e ./dist/${OPENSSL_DIR}/include ]; then
    mkdir -p ./dist/${OPENSSL_DIR}/include
fi

cp -r include/openssl ./dist/${OPENSSL_DIR}/include

if [ ! -e ./../${OPENSSL_LIBS} ]; then
    mkdir -p ./../${OPENSSL_LIBS}
fi

cp -r ./dist/$OPENSSL_DIR/* ./../${OPENSSL_LIBS}
mv -f ./../${OPENSSL_LIBS}/lib/* ./../${OPENSSL_LIBS}

popd

tar cvfz ${OPENSSL_LIBS}.tar.gz ${OPENSSL_LIBS}
