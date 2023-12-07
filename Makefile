# Arch
ARCH ?= x86_64

# Build Config
CUR_DIR   := $(shell pwd)
BUILD_DIR := $(CUR_DIR)/build
OPT_DIR   := $(CUR_DIR)/opt

# Tools
LD             := $(OPT_DIR)/bin/$(ARCH)-elf-ld
AS             := $(OPT_DIR)/bin/$(ARCH)-elf-as
GRUB           := $(OPT_DIR)/bin/grub-mkrescue
QEMU           := qemu-system-$(ARCH)
QEMU_INSTALLED := $(shell command -v $(QEMU) 2> /dev/null)

# Bootloader
BOOTLOADER_SRCS := $(wildcard src/bootloader/arch/$(ARCH)/*.s)
BOOTLOADER_OBJS := $(patsubst src/bootloader/arch/$(ARCH)/%.s, $(BUILD_DIR)/bootloader/arch/$(ARCH)/%.o, $(BOOTLOADER_SRCS))
BOOTLOADER_GRUB := src/bootloader/arch/$(ARCH)/grub.cfg
BOOTLOADER_LINK := src/bootloader/arch/$(ARCH)/linker.ld

# Kernel Output
KERNEL := $(BUILD_DIR)/rust-os-$(ARCH).bin
ISO    := $(BUILD_DIR)/rust-os-$(ARCH).iso

# Build Kernel
all: $(KERNEL)

$(KERNEL): $(LD) $(AS) $(BOOTLOADER_OBJS) $(BOOTLOADER_LINK)
	$(LD) -T $(BOOTLOADER_LINK) -o $(KERNEL) $(BOOTLOADER_OBJS)

$(BUILD_DIR)/bootloader/arch/$(ARCH)/%.o: src/bootloader/arch/$(ARCH)/%.s
	mkdir -p $(shell dirname $@)
	$(AS) $< -o $@

# Install Tools
binutils:
	ARCH=$(ARCH) BUILD_DIR=$(BUILD_DIR)/toolchain PREFIX_DIR=$(OPT_DIR) ./toolchain/install_binutils.sh

$(LD):
	$(MAKE) binutils

$(AS):
	$(MAKE) binutils

$(QEMU):
ifndef QEMU_INSTALLED
	ARCH=$(ARCH) ./toolchain/install_qemu.sh
endif

$(GRUB):
	ARCH=$(ARCH) BUILD_DIR=$(BUILD_DIR)/toolchain PREFIX_DIR=$(OPT_DIR) ./toolchain/install_grub.sh

# Build & Run ISO
run: $(QEMU) $(ISO)
	$(QEMU) -cdrom $(ISO) -monitor stdio -no-reboot -d int

iso: $(ISO)

$(ISO): $(GRUB) $(KERNEL) $(BOOTLOADER_GRUB)
	mkdir -p $(BUILD_DIR)/isofiles/boot/grub
	cp $(KERNEL) $(BUILD_DIR)/isofiles/boot/kernel.bin
	cp $(BOOTLOADER_GRUB) $(BUILD_DIR)/isofiles/boot/grub
	$(GRUB) -o $(ISO) $(BUILD_DIR)/isofiles

# Misc.
clean:
	rm -r build

.PHONY: all clean run iso binutils
