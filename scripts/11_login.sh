#!/usr/bin/env bash

if ! grep -Eq '^HOOKS=.*plymouth' /etc/mkinitcpio.conf; then
    sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.$(date +%Y%m%d%H%M%S)"
    if grep "^HOOKS=" /etc/mkinitcpio.conf | grep -q "systemd"; then
        sudo sed -i '/^HOOKS=/s/systemd/systemd plymouth/' /etc/mkinitcpio.conf
    else
        sudo sed -i '/^HOOKS=/s/udev/udev plymouth/' /etc/mkinitcpio.conf
    fi
fi

info "Adding kernel parameters for quiet boot..."
if [ -d "/boot/loader/entries" ]; then # systemd-boot
    for entry in /boot/loader/entries/*.conf; do
        if [ -f "$entry" ] && [[ ! "$(basename "$entry")" == *"fallback"* ]] && ! grep -q "splash" "$entry"; then
            sudo sed -i '/^options/ s/$/ splash quiet/' "$entry"
        fi
    done
elif [ -f "/etc/default/grub" ]; then # GRUB
    if ! grep -q "GRUB_CMDLINE_LINUX_DEFAULT.*splash" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash quiet"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
else
    warn "No systemd-boot or GRUB detected. Please add 'splash quiet' to your kernel parameters manually."
fi

sudo plymouth-set-default-theme -R black_hud

# From here: https://github.com/basecamp/omarchy/blob/master/install/config/login.sh
info "Compiling seamless login helper..."
if [ ! -x /usr/local/bin/seamless-login ]; then
    cat <<'CCODE' >/tmp/seamless-login.c
/*
* Seamless Login - Minimal Plymouth transition helper
* Manages VT to prevent console text from appearing before the desktop.
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/kd.h>
#include <linux/vt.h>
#include <sys/wait.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <session_command>\n", argv[0]);
        return 1;
    }

    int vt_fd = open("/dev/tty1", O_RDWR);
    if (vt_fd < 0) {
        perror("Failed to open VT");
        return 1;
    }

    ioctl(vt_fd, VT_ACTIVATE, 1);
    ioctl(vt_fd, VT_WAITACTIVE, 1);
    ioctl(vt_fd, KDSETMODE, KD_GRAPHICS);

    close(vt_fd);

    const char *home = getenv("HOME");
    if (home) chdir(home);

    execvp(argv[1], &argv[1]);
    perror("Failed to exec session");
    return 1;
}
CCODE
    gcc -o /tmp/seamless-login /tmp/seamless-login.c
    sudo mv /tmp/seamless-login /usr/local/bin/seamless-login
    sudo chmod +x /usr/local/bin/seamless-login
    rm /tmp/seamless-login.c
fi

info "Creating seamless login systemd service..."
if [ ! -f /etc/systemd/system/seamless-login.service ]; then
    cat <<EOF | sudo tee /etc/systemd/system/seamless-login.service
[Unit]
Description=Seamless Auto-Login Service
Conflicts=getty@tty1.service
After=systemd-user-sessions.service getty@tty1.service plymouth-quit.service

[Service]
ExecStart=/usr/local/bin/seamless-login uwsm start -- hyprland
User=$USER
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal+console
PAMName=login

[Install]
WantedBy=graphical.target
EOF
fi

sudo systemctl disable getty@tty1.service
sudo systemctl enable seamless-login.service

# Mask plymouth-quit-wait.service to prevent it from running.
sudo systemctl mask plymouth-quit-wait.service
sudo systemctl daemon-reload

sudo mkinitcpio -P
