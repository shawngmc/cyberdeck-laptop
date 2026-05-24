#!/bin/bash

cp ../neon_poly_tiger.jpg ~/.config/sway/neon_poly_tiger.jpg
sed -i 's|output \* bg .*|output * bg ~/.config/sway/neon_poly_tiger.jpg fill|' ~/.config/sway/config

