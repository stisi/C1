#!/bin/sh
cd "$(dirname "$0")" && python3 generate.py && python3 -c "import cairosvg; cairosvg.svg2png(url='preview.svg', write_to='preview.png', output_width=${1:-1400})"
