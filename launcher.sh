#!/bin/bash

#### init ####
if [ ! -d "runpod-project-deployment" ]; then
    echo "clone repo"
    git clone https://github.com/aaronfang/runpod-project-deployment.git
    
    apt-get update
    apt-get install -y unzip
    apt-get install lsof
    apt-get install dos2unix
    apt-get install -y git
    apt-get install -y aria2

    pip install requests tqdm gdown
fi

cd runpod-project-deployment || exit
python main.py