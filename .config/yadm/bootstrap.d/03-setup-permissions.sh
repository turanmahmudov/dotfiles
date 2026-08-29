#!/bin/sh

# brightnessctl
sudo usermod -aG video $USER

# docker
sudo groupadd docker
sudo usermod -aG docker $USER

# gamemode
# The packaged policy denies every GameMode helper even to an active local
# session, so gamemoderun gets renice but never the CPU governor or GPU clocks.
GAMEMODE_RULES="/etc/polkit-1/rules.d/49-gamemode.rules"
if [ ! -f "$GAMEMODE_RULES" ]; then
    echo "Allowing GameMode helpers for the local session..."
    sudo tee "$GAMEMODE_RULES" >/dev/null <<'RULE'
polkit.addRule(function (action, subject) {
    if (action.id.indexOf("com.feralinteractive.GameMode.") === 0
        && subject.local && subject.active && subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
RULE
fi
