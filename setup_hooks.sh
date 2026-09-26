#!/bin/sh
echo "Configuring local Git hooks..."
git config core.hooksPath .githooks
chmod +x .githooks/*
echo "Done! Git hooks are configured to strip AI co-authors."
