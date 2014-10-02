#!/bin/bash

# Check if enough arguments have been given to the script.
[[ $# >= 3 ]] || {
	echo "Usage: $0 <name> <command> <dir> [Travis-JDK]"
	echo "e.g.: $0 project \"./gradlew javadoc\" build/docs/javadoc"
	exit 1
}

# This is where I am.
deploy_scripts=$(dirname $0)

# The name of the project, represents the folder in the repository.
name=$1
# The command to execute that will generate the Javadocs.
command=$2

# Folders
root_dir=$(pwd)
dir=$3
git_dir=/tmp/lapis/javadocs

# JDK to create the Javadocs with, Java 8 by default
jdk=${4:-oraclejdk8}

# Ensure all commands complete successfully
set -e

# Make sure we're running the right Travis JDK version
[[ -z "$TRAVIS_JDK_VERSION" ||  "$TRAVIS_JDK_VERSION" = "$jdk" ]]

echo "Initializing Git environment..."

# Initialize the ssh-agent so we can use Git later for deploying
eval $(ssh_agent)
# Set up our Git environment
$deploy_scripts/setup_git.sh

echo "Building Javadocs..."

# Run the specified command to build the Javadocs
$command

echo "Completed Javadoc generation, deploying to GitHub..."

# Clone our Javadocs repository
git clone git@github.com:LapisBlue/Javadocs.git $git_dir
cd $git_dir

echo "Javadocs location for this project: $git_dir/$name"

# Delete the old Javadocs so we have them completely clean again
git rm -r $name

# Copy the new generated Javadocs and add them to Git
cp -r $root_dir/$dir $name
git add -A

# Commit the changes with a more detailed commit message only for Travis.
[[ "$TRAVIS" = "true" ]]
	&& message="Update to $TRAVIS_REPO_SLUG@$TRAVIS_COMMIT (Build $TRAVIS_BUILD_NUMBER)"
	|| message="Update $(date -u +"%Y-%m-%dT%H:%M:%SZ")" # -> ugly date

# Push the changes to GitHub
git push

# Kill the ssh-agent because we're done with deploying
ssh-agent -k

echo "Done! Successfully deployed Javadocs to GitHub! ;)"
