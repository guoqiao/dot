#!/usr/bin/env bash

echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/${USER}"

file=/etc/sudoers.d/${USER}
ls -l "${file}"

