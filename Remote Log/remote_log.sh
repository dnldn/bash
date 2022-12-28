#!/bin/bash

# Get URL from user input.
read -p "Enter GitHub URL: " -r git_url
read -p "Enter branch name (or leave blank for master):" -r branch

# Get the repository name from the URL.
repo_name=$(echo "$git_url" | sed 's|.*/||')

# Check if the repository has already been cloned in current directory. Navigate to it to avoid deletion if it has.
if [ -d "$repo_name" ]; 
then
	cd "$repo_name" || exit
else
	if [ -n "$branch" ];
	then
		git clone --filter=blob:none --no-checkout --single-branch --branch "$branch" "$git_url"
		cd "$repo_name" || exit
	else
		git clone --filter=blob:none --no-checkout --single-branch --branch master "$git_url"
		cd "$repo_name" || exit
	fi
fi

# Print commit history to terminal and remove repository.
git log -s; cd ..; rm -rf "$repo_name"
