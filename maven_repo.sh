#!/bin/bash

# Check if enough arguments have been given to the script.
[[ $# >= 1 ]] || {
	echo "Usage: $0 <command> [Travis-JDK]"
	echo "This will run the command using these environment variables:"
	echo "REPO_RELEASES, REPO_SNAPSHOTS, REPO_THIRDPARTY"
	echo "The build should automatically publish it in Maven repository format to the correct folder."
	exit 1
}

# This is where I am.
deploy_scripts=$(dirname $0)

# The command to execute that will publish the artifacts.
command=$1

# Temporary Git repository
git_dir=/tmp/lapis/repo

# JDK to publish the artifacts with, Java 6 by default
jdk=${2:-openjdk6}

# Ensure all commands complete successfully
set -e

# Make sure we're running the right Travis JDK version
[[ -z "$TRAVIS_JDK_VERSION" ||  "$TRAVIS_JDK_VERSION" = "$jdk" ]]

echo "Initializing Git environment..."

# Initialize the ssh-agent so we can use Git later for deploying
eval $(ssh_agent)
# Set up our Git environment
$deploy_scripts/setup_git.sh

# Clone our Maven repo repository
git clone git@github.com:LapisBlue/Repo.git $git_dir

# Setup repo path environment variables
export REPO_RELEASES="$git_dir/releases"
echo "Publishing releases to: $REPO_RELEASES"
export REPO_SNAPSHOTS="$git_dir/snapshots"
echo "Publishing snapshots to: $REPO_SNAPSHOTS"
export REPO_THIRDPARTY="$git_dir/thirdparty"
echo "Publishing third party artifacts to: $REPO_THIRDPARTY"

echo "Publishing artifacts..."

# Run the specified command to build the Javadocs
$command

echo "Successfully published artifacts, deploying to GitHub..."

# Stage all changed and removed files for commit
git add -A

# Commit the changes with a more detailed commit message only for Travis.
[[ "$TRAVIS" = "true" ]]
	&& message="Update to $TRAVIS_REPO_SLUG@$TRAVIS_COMMIT (Build $TRAVIS_BUILD_NUMBER)"
	|| message="Update $(date -u +"%Y-%m-%dT%H:%M:%SZ")" # -> ugly date

# Push the changes to GitHub
git push

# Kill the ssh-agent because we're done with deploying
ssh-agent -k

echo "Done! Successfully published artifacts to the GitHub Maven repository! ;)"
