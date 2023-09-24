#!/bin/bash

ROOT_DIR="/workspace"    # Project root directory
RERENDER_A_VIDEO_DIR="${ROOT_DIR}/Rerender_A_Video"
DEPS_DIR="${RERENDER_A_VIDEO_DIR}/deps"
SERVER_PORT=7860    # 服务器端口

# Clone the repository if RERENDER_A_VIDEO_DIR does not exist
if [ ! -d "${RERENDER_A_VIDEO_DIR}" ]; then
    echo "Cloning main repository..."
    git clone https://github.com/williamyang1991/Rerender_A_Video.git "${RERENDER_A_VIDEO_DIR}"

    cd "${DEPS_DIR}" || exit

    echo "Cloning deps repositories.."
    # edit the .gitmodules file, replace the url of the submodule with the http url
    git clone https://github.com/lllyasviel/ControlNet "${DEPS_DIR}"
    git clone https://github.com/SingleZombie/ebsynth "${DEPS_DIR}"
    git clone https://github.com/haofeixu/gmflow "${DEPS_DIR}"

    cd "${RERENDER_A_VIDEO_DIR}" || exit

    # create a virtual environment
    echo "Creating a virtual environment..."
    python3 -m venv venv

    # Check if requirements.txt exists before installing the required packages
    echo "Installing the required packages..."
    venv/bin/pip install -r requirements.txt
    venv/bin/pip install -r requirements.txt
    venv/bin/pip uninstall --yes torch torchvision torchaudio
    venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    venv/bin/pip install xformers
    venv/bin/pip uninstall --yes gradio
    venv/bin/pip install gradio==3.44.3

    venv/bin/python install.py

    # download checkpoint to ./models directory https://civitai.com/api/download/models/130072  realisticVisionV51_v51VAE.safetensors
    wget https://civitai.com/api/download/models/130072 -O ./models/Realistic_Vision_V5.1.safetensors

    # replace content between {} in sd_model_cfg.py with the following
    # {'Realistic_Vision_V5_1' : 'models/realisticVisionV51_v51VAE.safetensors',}
    sed -i 's/{}/{'"'"'Realistic_Vision_V5_1'"'"' : '"'"'models\/Realistic_Vision_V5.1.safetensors'"'"',}/g' sd_model_cfg.py

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# check if gradio_diffbir.py exists in DiffBIR_DIR, if exists, modify the file, replace block.launch() with block.launch(server_name="0.0.0.0")
if [ -f "${RERENDER_A_VIDEO_DIR}/webUI.py" ]; then
    echo "webUI.py exists. Modifying the file..."
    sed -i -E "s/block\.launch\((server_name=\"0.0.0.0\", )?(server_port=[0-9]+)?\)/block.launch(server_name=\"0.0.0.0\", server_port=${SERVER_PORT})/g" "${RERENDER_A_VIDEO_DIR}/webUI.py"
fi

# Start the application
venv/bin/python webUI.py

