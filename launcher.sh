#!/bin/bash

#### init ####
apt-get update
apt-get install -y unzip
apt-get install lsof
apt-get install dos2unix
apt-get install -y git
apt-get install -y aria2

pip install requests tqdm gdown

#### launch gui ####
python main.py