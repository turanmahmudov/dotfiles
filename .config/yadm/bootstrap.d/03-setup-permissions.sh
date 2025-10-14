#!/bin/sh

# brightnessctl
sudo usermod -aG video $USER

# docker
sudo groupadd docker
sudo usermod -aG docker $USER
