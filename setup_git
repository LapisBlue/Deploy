#!/bin/bash

# Ensure all commands below will be successful or fail if not
set -e

# Enter password if called by ssh-add
[ -n "$SSH_ASKPASS" ] && [ -n "$DISPLAY" ] && {
	[ ! -f ".ssh-add" ]
	touch .ssh-add
	echo "$LAPIS_PASS"
	exit 0
}

echo && echo "Initializing Git environment..."

# We don't need to set up anything if we don't have the passphrase
[[ -z "$LAPIS_PASS" || ( -n "$TRAVIS_SECURE_ENV_VARS" && "$TRAVIS_SECURE_ENV_VARS" = "false" ) ]] && {
	echo "Passphrase is not available, unable to set up Git environment."
	exit 1
}

KEY_NAME=lapislazuli.pem
KEY_PATH=~/.ssh/$KEY_NAME

# This is where I am.
deploy_scripts=$(dirname $0)

mkdir -pv $(dirname $KEY_PATH)
cp -v "$deploy_scripts/$KEY_NAME" $KEY_PATH

# Change the permissions so it is accepted as SSH key
chmod -v 600 $KEY_PATH

# Setup detached ASKPASS for ssh
export SSH_ASKPASS=$0
export DISPLAY=dummydisplay:0

cleanup() {
	unset SSH_ASKPASS DISPLAY LAPIS_PASS
	rm .ssh-add
}

true | setsid ssh-add "$KEY_PATH" || {
	cleanup
	echo "Failed to add private Git key. Maybe the passphrase is wrong?"
	exit 1
}

cleanup

echo "Successfully installed Lapis Git SSH key!"
echo "Adding GitHub host keys..."

# Get the public key from the GitHub server
ssh-keyscan github.com > /tmp/gh_key

# Verify the GitHub key fingerprint
[ "$(ssh-keygen -lf /tmp/gh_key)" = "2048 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48 github.com (RSA)" ] || {
	echo "Failed to verify GitHub key, mismatching fingerprint - please try again later."
	exit 1
}

# We're really talking to GitHub, yay!
cp -v /tmp/gh_key ~/.ssh/known_hosts
echo "GitHub host key was successfully added to the known hosts!"

echo "Setting up Git settings..."
git config --global user.name "Lapislazuli"
git config --global user.email "lapislazuli@lapis.blue"
git config --global push.default simple
echo "Done! Successfully set up Lapis Git environment. ;)" && echo

