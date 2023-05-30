#!/bin/bash

# Check if the directory argument is provided
if [ -z "$1" ]; then
  echo "Usage: daa.sh <directory> <archive_filename>"
  exit 1
fi

# Get the original path of the directory
original_path=$(realpath "$1")

# Prompt the user for any additional notes
echo -n "Enter additional notes for the readme: "
read -r additional_notes

# Generate the timestamp
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Create the readme.md file
readme_file="${original_path}/readme.md"
echo -e "Author: J. Zwick (jzwick@jamasoftware.com)\nCompany: Jama Software\nOriginal Path: ${original_path}\nDate/Time: ${timestamp}\nAdditional Notes: ${additional_notes}" > "$readme_file"

# Compress the directory recursively, including the readme file
if [ -n "$2" ]; then
  archive_name="$2"
else
  archive_name="archive_$(date +"%Y%m%d%H%M%S").tar.gz"
fi

tar -czf "$archive_name" -C "$1" .

echo "Archive created: $archive_name"
