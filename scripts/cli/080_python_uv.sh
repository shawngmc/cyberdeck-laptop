#!/bin/bash

# Install Python
brew install uv
uv python install
uv python pin $(uv python list | grep 'cpython' | grep -v 'freethreaded' | grep -v 'a[0-9]' | head -1 | grep -o '3\.[0-9]*' | head -1)

