#!/usr/bin/env bash

if [ -n "$(lspci | grep -i 'nvidia')" ]; then
    if echo "$(lspci | grep -i 'nvidia')" | grep -q -E "RTX [2-9][0-9]|GTX 16"; then
        NVIDIA_DRIVER_PACKAGE="nvidia-open-dkms"
    else
        NVIDIA_DRIVER_PACKAGE="nvidia-dkms"
    fi

    KERNEL_HEADERS="linux-headers"
    if pacman -Q linux-zen &>/dev/null; then
        KERNEL_HEADERS="linux-zen-headers"
    elif pacman -Q linux-lts &>/dev/null; then
        KERNEL_HEADERS="linux-lts-headers"
    elif pacman -Q linux-hardened &>/dev/null; then
        KERNEL_HEADERS="linux-hardened-headers"
    fi

    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    fi

    sudo pacman -Syy

    PACKAGES_TO_INSTALL=(
        "${KERNEL_HEADERS}"
        "${NVIDIA_DRIVER_PACKAGE}"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "egl-wayland"
        "libva-nvidia-driver"
        "qt5-wayland"
        "qt6-wayland"
    )

    sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}"

    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

    # Following Arch wiki instructions
    MKINITCPIO_CONF="/etc/mkinitcpio.conf"
    NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

    sudo cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.backup"
    sudo sed -i -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g;' "$MKINITCPIO_CONF"
    sudo sed -i -E "s/^(MODULES=\\()/\\1${NVIDIA_MODULES} /" "$MKINITCPIO_CONF"
    sudo sed -i -E 's/  +/ /g' "$MKINITCPIO_CONF"
fi
