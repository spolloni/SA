#!/bin/bash

git status
echo "Running main.py on AWS Server at $(date +%H:%M--%h%m)"
git commit -a -m "Running main.py on AWS Server at $(date +%H:%M--%h%m)"
git push

#ssh -i "/Users/stefanopolloni/SAkey.pem" \
#ubuntu@ec2-18-216-131-130.us-east-2.compute.amazonaws.com \
#'bash -s' << \EOF

# CD into code directory
#cd $HOME/analysis/Code

# update from git 
#git pull

# run main.py


#EOF