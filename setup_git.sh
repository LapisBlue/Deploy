#!/bin/bash

# We don't need to set up anything if we don't have the passphrase
[[ -z "$LAPIS_PASS" || ( -n "$TRAVIS_SECURE_ENV_VARS" && "$TRAVIS_SECURE_ENV_VARS" = "false" ) ]] && {
	echo "Passphrase is not available, unable to set up Git environment."
	exit 1
}

# Ensure all commands below will be successful or fail if not
set -e

KEY_NAME=lapislazuli.pem
KEY_PATH=~/.ssh/$KEY_NAME

# This is where I am.
deploy_scripts=$(dirname $0)

# We will need Expect to pass the passphrase to ssh-add
sudo apt-get install expect -qq

mkdir -pv $(dirname $KEY_PATH)
cp -v "$deploy_scripts/$KEY_NAME" $KEY_PATH

# Change the permissions so it is accepted as SSH key
chmod -v 600 $KEY_PATH

# Add the ssh key to the SSH agent
expect 2> /dev/null << EOF
	# Start the process
	spawn ssh-add $KEY_PATH
	# If an error occurs we should already stop here
	expect {
		eof { exit 1 }
		"Enter passphrase"
	}

	# Enter the passphrase into the prompt
	send "$LAPIS_PASS\r"

	expect {
		eof { exit 1 }
		"try again" { exit 1 }
		"Identity added"
	}

	expect eof
EOF

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
echo "Done! Successfully set up Lapis Git environment. ;)"
