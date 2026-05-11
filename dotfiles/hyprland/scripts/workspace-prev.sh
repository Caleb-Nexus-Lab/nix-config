#!/bin/sh
cur=$(hyprctl activeworkspace | awk 'NR==1{print $3}')
prev=$(( ((cur - 2 + 5) % 5) + 1 ))
hyprctl dispatch workspace "$prev"
