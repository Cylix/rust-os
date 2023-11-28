#! /bin/bash
set -eoux pipefail

# Installation Configuration
export BUILD_DIR="${BUILD_DIR:-$(pwd)/build/toolchain}"
export PREFIX_DIR="${PREFIX_DIR:-$(pwd)/opt}"

export BINUTILS_VERSION="2.41"
export ARCH="${ARCH:-x86_64}"

# Create build & prefix directories
mkdir -p "${PREFIX_DIR}"
mkdir -p "${BUILD_DIR}"
pushd "${BUILD_DIR}"

# Install binutils for cross-compilation, refer to https://wiki.osdev.org/GCC_Cross-Compiler
if [ ! -f "binutils-${BINUTILS_VERSION}.tar.gz" ]; then
    wget "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz"
fi

if [ ! -d "binutils-${BINUTILS_VERSION}" ]; then
    tar xf "binutils-${BINUTILS_VERSION}.tar.gz"
fi

if [ ! -f "${PREFIX_DIR}/bin/${ARCH}-elf-as" ] || [ ! -f "${PREFIX_DIR}/bin/${ARCH}-elf-ld" ]; then
    mkdir -p build-binutils
    pushd build-binutils

    ../binutils-${BINUTILS_VERSION}/configure \
        --target="${ARCH}-elf" \
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
