#! /bin/bash
set -eoux pipefail

# Installation Configuration
export BUILD_DIR="$(pwd)/tmp"
export PREFIX_DIR="$(pwd)/opt"
export PATH="${PREFIX_DIR}/bin:${PATH}"

export BINUTILS_VERSION="2.41"
export GCC_VERSION="13.2.0"

export TARGET="i686-elf"

# Create build & prefix directories
mkdir -p "${PREFIX_DIR}"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"

# Brew setup
brew update

# Install binutils and gcc dependencies, refer to https://wiki.osdev.org/GCC_Cross-Compiler
#
# Known issue: '/usr/local/sbin is not writable'
# Solution: `sudo mkdir -p /usr/local/sbin && sudo chown -R $(whoami) $(brew --prefix)/*`
# Refer to https://stackoverflow.com/a/48245412/1939604
HOMEBREW_NO_AUTO_UPDATE=1 brew install gmp mpfr mpc libmpc libiconv texinfo

# Misc.
HOMEBREW_NO_AUTO_UPDATE=1 brew install wget

# Installing binutils for cross-compilation, refer to https://wiki.osdev.org/GCC_Cross-Compiler
if [ ! -d "binutils-${BINUTILS_VERSION}" ]; then
    wget "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz"
    tar xf "binutils-${BINUTILS_VERSION}.tar.gz"
fi

if [ ! -f "${PREFIX_DIR}/bin/i686-elf-as" ] || [ ! -f "${PREFIX_DIR}/bin/i686-elf-ld" ]; then
    mkdir -p build-binutils
    pushd build-binutils

    ../binutils-${BINUTILS_VERSION}/configure \
        --target="${TARGET}" \
        --prefix="${PREFIX_DIR}" \
        --with-sysroot \
        --disable-nls \
        --disable-werror \
        --enable-interwork \
        --enable-multilib

    make
    make install

    popd
fi

# Installing gcc for cross-compilation, refer to https://wiki.osdev.org/GCC_Cross-Compiler
if [ ! -d "gcc-${GCC_VERSION}" ]; then
    wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
    tar xf "gcc-${GCC_VERSION}.tar.gz"
fi

if [ ! -f "${PREFIX_DIR}/bin/i686-elf-gcc" ]; then
    mkdir -p build-gcc
    pushd build-gcc

    ../gcc-${GCC_VERSION}/configure \
        --target="${TARGET}" \
        --prefix="${PREFIX_DIR}" \
        --disable-nls \
        --enable-languages=c,c++ \
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
