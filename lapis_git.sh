#!/bin/bash

# We don't need to set up anything if we don't have the passphrase
if [[ -z "$LAPIS_PASS" || (-n "$TRAVIS_SECURE_ENV_VARS" && "$TRAVIS_SECURE_ENV_VARS" = "false") ]]; then
	echo "Passphrase is not available, unable to set up Git environment."
	exit 1
fi

KEY_PATH=~/.ssh/lapis_git

# Ensure all commands below will be successful or fail if not
set -e

# We will need Expect to pass the passphrase to ssh-add
sudo apt-get install expect -qq

mkdir -pv $(dirname $KEY_PATH)
cat > $KEY_PATH << EOF
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFLjBYBgkqhkiG9w0BBQ0wSzAqBgkqhkiG9w0BBQwwHQQIfafPZhAm7sACAw9C
QDAMBggqhkiG9w0CCwUAMB0GCWCGSAFlAwQBKgQQyXSoF00DdQInjmhlvg0+HQSC
BNBMIYh3J2L7bn+ElI5fXeVvlTvxaw2FHoEpKk/mBisQPBkWhPe0DdJt+CUhrrYW
G1+LRjgMTdOl2Ck/S6fZ7yoGTuBs3Qxr3m9QOUYAuJKjgy9t3ITIUMQe8c49N2cO
5VYstQxz6vXPseCP8keWRrqrzJpCwWzl62e5OcllsbR2W+YYsuDvL9PXBLhWyugT
PO4UFtx6CySTVuroz0XQoA+BGSYTkTmfLj7VocmSMJWwc2Bg1oT0Bzb6gOubtrj+
tJx/uATqRUvJ66gHfO1VEKa79D0fwqGhiA9IECd1bOSRAFia+58d9P9CmD4eLXye
wNiPmbPBoQwDzymTPZWOIalym4cw52fq0qIkS54BFAzObzI1XxZNXre3APNp0fAo
v3cy9zCrPvnDuFX4RYHiwxNMN028F0D1u9na9KGrSQO3p3o0c610UhZLMdvGgtdT
PP/IQRPsDD4EPLDRmCJhgwD4PbcjgBO/qK4JprVvjhlaslJhc1m/TXbvrHgZxoov
lpq2auCxZxay/Rl70e2ZTZbpzuma4O+3umxxxBiqmmeYrYFquGpiltjoSKV+mpyC
cIJ+plg53skta0gqhlHrorGic1aNWdnWS+tkvsDSjPDyF5vXazzQSMflJyhG1RtR
W5S3xSp0N3Q18casmzZ+z1lMnM/cZfXdWWzDjg0+ggkify1qSMwIL3B2ezjdqLSG
0VN2ht7XxR8/GbOH7RL7ZvTCsARos4C/qW5j10VIyUFZwsxBvEO+ZM62IGRW0oYv
Aexr3ksMK+b888FJYpemNNNlQpXHszSgnk4+Fx1gUy3cnfSkgFm10MnZoGoLreJ4
IWwd58P2iV9+0f4MhFygRA3OXengRujXlQunDhhu6oWdzQJpoGD79mUvwR2tsYMc
PAbytsvgzhavfN0I9U3XREkDdGL/KXdapYZvyJ3uuifVmvKabsXzIIN1VUorqUgl
mQALkcdcaYLWLG76SPdhVj2xU2Egu35LNiwQ1dnJJAMovjGp0iQnsVFuhPYx8Xvg
Ybtl+NpK0LUbSh9hXKP2UK5o72SMwE3VaaWYlohwCFZ66AE0Mom+svJwHi9U1JjE
JTGANhKgjmVtQYZ5UYvrbo4HnkpDb1bNdnFQXnXYgTCrZRC+pLCKmhlAOOqtFgfa
oofW5kSrZ55gp1jfGwlbaSaHuXwRsxRYbYtmvVTnURCr1eqq3i/FLDL2AP+kSqDj
iQw66P8mcyB2XIIX7Q5az9gk9tFhsYyMOjj8sN6hV5gxUCE4waAGHoWvfW8CPzMw
GhLqtZq6ZXpW7KZ2mXTQEfRWZTNTDvWMKTmTyalviFOBziTutr15Tj4suCjLxO5m
zA+6qtvsrpcwVH4x6nl1rE6+Rd5fKAHv/waDbaDMgZ6YbCE4SKFBV9vgI0/ZLrBF
P7UZAZ7zueswibONjNVREkt7OZpo8h8/4HaOGmR+HZcwhtbIdBCfYsLJNT6AmVQT
scoDBtEMBSKM839Y+4xjWmuu1IU+vQpiYc2+vncozmy21WXpK7HGRbm4qQWDYPZc
2uCuhv5gRGboiQX25PB4hCFSpqjXPWW53V27XWW0o3oqTSmyfdWCFwPSu04r7+4Y
ewZSs037eMXXs/7vEnHsVN+HrucasXr7fKSrPGk50CR0pA==
-----END ENCRYPTED PRIVATE KEY-----
EOF

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
echo "Done! Successfully set up Lapis Git environment. Enjoy! ;)"
