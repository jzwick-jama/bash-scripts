#!/bin/bash

echo "Gitlab Runner Installer"
echo " "

function main_function(){
	while true; do
	    read -p "What's your GitLab Runner token? " token

    	if (( ${#token} < 25 || ${#token} > 25 )); then
        	echo "Error: Invalid token. Please try again."
        	main_function
    	else
        	gitlab-runner register  --url https://gitlab.com  --token $token
    	fi
	done
}