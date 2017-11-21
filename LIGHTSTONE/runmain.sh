#!/bin/bash

#push code to git
git commit -a -m "Running main.py on AWS Server at $(date +%H:%M--%h%m)"
git push

#ssh into server
#ssh -i "/Users/stefanopolloni/SAkey.pem" \
#ubuntu@ec2-18-216-234-87.us-east-2.compute.amazonaws.com \
#'source ~/.profile; bash -s' << \EOF
#
#	#CD into code directory
#	cd $HOME/analysis/Code
#
#	#pull code from git 
#	git pull
#
#	# run main.py
#	cd $HOME/analysis/Code/LIGHTSTONE
#	python main.py
#
#	#echo "$LD_LIBRARY_PATH"
#
#EOF

echo $PWD