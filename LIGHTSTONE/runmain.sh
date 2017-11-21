#!/bin/bash

#push code to git
git commit -a -m "Running main.py on AWS Server at $(date +%H:%M--%h%m)"
git push

#ssh into server
ssh -i "/Users/stefanopolloni/SAkey.pem" \
ubuntu@ec2-18-216-131-130.us-east-2.compute.amazonaws.com \
'bash -s' << \EOF

#CD into code directory
cd $HOME/analysis/Code

#pull code from git 
git pull

# run main.py
python ./LIGHTSTONE/main.py


EOF