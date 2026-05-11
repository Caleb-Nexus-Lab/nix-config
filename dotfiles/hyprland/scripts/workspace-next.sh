#!/bin/sh
cur=$(hyprctl activeworkspace | awk 'NR==1{print $3}')
next=$(( (cur % 5) + 1 ))
hyprctl dispatch workspace "$next"
