#! /bin/bash
set -eoux pipefail

# Installation Configuration
export BUILD_DIR="${BUILD_DIR:-$(pwd)/build/toolchain}"
export PREFIX_DIR="${PREFIX_DIR:-$(pwd)/opt}"
export PATH="${PREFIX_DIR}/bin:${PATH}"

export GCC_VERSION="13.2.0"
export ARCH="${ARCH:-x86_64}"

# Create build & prefix directories
mkdir -p "${PREFIX_DIR}"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"

# Brew setup
brew update

# Install gcc dependencies, refer to https://wiki.osdev.org/GCC_Cross-Compiler
#
# Known issue: '/usr/local/sbin is not writable'
# Solution: `sudo mkdir -p /usr/local/sbin && sudo chown -R $(whoami) $(brew --prefix)/*`
# Refer to https://stackoverflow.com/a/48245412/1939604
HOMEBREW_NO_AUTO_UPDATE=1 brew install gmp mpfr mpc libmpc texinfo

# Install grub dependencies
HOMEBREW_NO_AUTO_UPDATE=1 brew install gawk xorriso

# Misc.
HOMEBREW_NO_AUTO_UPDATE=1 brew install wget

# Install gcc, refer to https://wiki.osdev.org/GCC_Cross-Compiler
if [ ! -f "gcc-${GCC_VERSION}.tar.gz" ]; then
    wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
fi

if [ ! -d "gcc-${GCC_VERSION}" ]; then
    tar xf "gcc-${GCC_VERSION}.tar.gz"
fi

if [ ! -f "${PREFIX_DIR}/bin/${ARCH}-elf-gcc" ]; then
    mkdir -p build-gcc
    pushd build-gcc

    ../gcc-${GCC_VERSION}/configure \
        --target="${ARCH}-elf" \
        --prefix="${PREFIX_DIR}" \
        --disable-nls \
        --enable-languages=c \
        --without-headers \
        --with-gmp=/usr/local \
        --with-mpc=/opt/local \
        --with-mpfr=/opt/local \
        --enable-interwork \
        --enable-multilib

    make all-gcc
    make all-target-libgcc
    make install-gcc
    make install-target-libgcc

    popd
fi

# Install objconv
if [ ! -f "objconv.zip" ]; then
    wget http://www.agner.org/optimize/objconv.zip
fi

if [ ! -d "build-objconv" ]; then
    unzip objconv.zip -d build-objconv
fi

if [ ! -f "${PREFIX_DIR}/bin/objconv" ]; then
    pushd build-objconv

    unzip source.zip -d src
    g++ -o objconv -O2 src/*.cpp --prefix="${PREFIX_DIR}"
    cp objconv "${PREFIX_DIR}/bin"

    popd
fi

# Install grub, refer to https://wiki.osdev.org/GRUB_2#Installing_GRUB2_on_Mac_OS_X
if [ ! -d "grub" ]; then
    git clone git://git.savannah.gnu.org/grub.git
fi

if [ ! -f "${PREFIX_DIR}/bin/grub-mkrescue" ]; then
    pushd grub
    ./bootstrap
    ./autogen.sh
    popd

    mkdir -p build-grub
    pushd build-grub

    ../grub/configure \
        --prefix="${PREFIX_DIR}" \
        --disable-werror \
        TARGET_CC="${ARCH}-elf-gcc" \
        TARGET_OBJCOPY="${ARCH}-elf-objcopy" \
        TARGET_STRIP="${ARCH}-elf-strip" \
        TARGET_NM="${ARCH}-elf-nm" \
        TARGET_RANLIB="${ARCH}-elf-ranlib" \
        --target="${ARCH}-elf"

    make
    make install

    popd
fi
