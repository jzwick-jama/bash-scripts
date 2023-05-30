Describe-and-Archive.sh or daa.sh 

(Written by J. Zwick, jzwick@jamasoftware.com. May 2023.)

(Written for Bash/Debian and Ubuntu)
====================================
(See instructions in comments in the bottom or the readme.md with the script.)

INSTALLATION
============

Steps:

1. sudo chmod 777 ./daa.sh 
	[Run from script's folder]

2. From the CLI, type: '$PATH', confirm '/bin' is in your $PATH. 
	(Otherwise copy to another folder in $PATH)

3. 'cp ./daa.sh /bin/daa.sh && chmod 777 /bin/daa.sh'


Now you should be able to invoke: 

	'./daa.sh [/path/to/archive/directory] [archive_name]'



To create the readme.md file and archive a directory, simply replace '/path/to/'.. with the actual path to store the compressed archive, and if you like, name the archive as well.


Use with BASH:
==============

	'./daa.sh /path/to/directory [archive_name]'

Replace /path/to/directory with the path to the directory you want to archive, and optionally, you can provide an archive_name as the second argument. 

	[The script will generate a timestamped default name for the archive by default otherwise.]

The script creates a 'readme.md' file in the root directory of the specified directory and populate it with the author's information, company, original path, timestamp, and additional notes. It will then compress the entire directory, including the readme.md file, into an archive with the specified or generated name.

[Admin Note:v Please note that this script assumes you have the necessary permissions to create files and directories in the specified locations.]