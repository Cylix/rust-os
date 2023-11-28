#! /bin/bash
set -eoux pipefail

# Installation Configuration
export ARCH="${ARCH:-x86_64}"

# Brew setup
brew update

# Install qemu
if ! command -v "qemu-system-${ARCH}"; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install qemu
fi
