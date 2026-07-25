#!/bin/sh
# Miscellaneous System Configuration

# Disable Bluetooth Handsfree Auto-Switch
BLUETOOTH_CONF="/etc/bluetooth/main.conf"
if [ -f "$BLUETOOTH_CONF" ]; then
    if ! grep -q "^Disable=Handsfree" "$BLUETOOTH_CONF"; then
        echo "Disabling Bluetooth Handsfree auto-switch..."
        sudo sed -i '/^\[General\]/a Disable=Handsfree' "$BLUETOOTH_CONF"
    fi
fi

# Disable WiFi power save (iwlwifi throttles throughput and adds latency jitter)
NM_POWERSAVE_CONF="/etc/NetworkManager/conf.d/wifi-powersave-off.conf"
if [ ! -f "$NM_POWERSAVE_CONF" ]; then
    echo "Disabling WiFi power save..."
    printf '[connection]\nwifi.powersave = 2\n' | sudo tee "$NM_POWERSAVE_CONF" >/dev/null
    sudo systemctl restart NetworkManager
fi

# Load i2c-dev at boot (ddcutil needs it for external-monitor brightness over DDC/CI)
I2C_CONF="/etc/modules-load.d/i2c-dev.conf"
if [ ! -f "$I2C_CONF" ]; then
    echo "Enabling i2c-dev module for ddcutil..."
    echo 'i2c-dev' | sudo tee "$I2C_CONF" >/dev/null
    sudo modprobe i2c-dev 2>/dev/null || true
fi

# Replace sudo-rs with legacy sudo
sudo update-alternatives --set sudo /usr/bin/sudo.ws

# Add globalprotectcallback handler
xdg-mime default gp-vpn-callback.desktop x-scheme-handler/globalprotectcallback
update-desktop-database ~/.local/share/applications

# systemd rejects loading units whose symlink target contains '##'
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
for unit in gnome-keyring-ssh.service; do
    path="$SYSTEMD_USER_DIR/$unit"
    if [ -L "$path" ]; then
        src="$(readlink -f "$path")"
        rm "$path"
        cp "$src" "$path"
    fi
done
systemctl --user daemon-reload
systemctl --user enable --now vicinae.service
