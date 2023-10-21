#!/bin/bash

ROOT_DIR="/workspace/gaussian-splatting-deploy"
REPO_DIR="${ROOT_DIR}/gaussian-splatting"
DATA_DIR="${ROOT_DIR}/data"
SERVER_PORT=7860


# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${REPO_DIR}" ]; then
    echo "Cloning the repository..."
    git clone --recursive https://github.com/camenduru/gaussian-splatting "${REPO_DIR}"

    # Install colmap
    apt update
    apt install colmap

    # Navigate into the cloned directory
    cd "${REPO_DIR}" || exit
    python -m venv venv

    echo "installing requirements..."
    venv/bin/pip install -q plyfile ffmpeg
    venv/bin/pip install -q https://huggingface.co/camenduru/gaussian-splatting/resolve/main/diff_gaussian_rasterization-0.0.0-cp310-cp310-linux_x86_64.whl
    venv/bin/pip install -q https://huggingface.co/camenduru/gaussian-splatting/resolve/main/simple_knn-0.0.0-cp310-cp310-linux_x86_64.whl

    echo "Creating data directory..."
    mkdir -p "${DATA_DIR}"

    echo "Creating images directory..."
    mkdir -p "${DATA_DIR}/images"

    echo "Creating sparse directory..."
    mkdir -p "${DATA_DIR}/sparse"

    echo "Creating output directory..."
    mkdir -p "${ROOT_DIR}/output"
fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"