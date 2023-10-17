#!/bin/bash

ROOT_DIR="/workspace"    # Project root directory
DREAMGAUSSIAN_DIR="${ROOT_DIR}/dreamgaussian"
SERVER_PORT=7860    # 服务器端口

# Clone the repository if RERENDER_A_VIDEO_DIR does not exist
if [ ! -d "${DREAMGAUSSIAN_DIR}" ]; then
    cd "${ROOT_DIR}" || exit
    echo "Cloning main repository..."
    git lfs install
    # git clone https://huggingface.co/spaces/jiawei011/dreamgaussian "${DREAMGAUSSIAN_DIR}"
    git clone https://github.com/dreamgaussian/dreamgaussian.git "${DREAMGAUSSIAN_DIR}"

    # create a virtual environment
    cd "${DREAMGAUSSIAN_DIR}" || exit
    echo "Creating a virtual environment..."
    # if not venv exists, create one
    if [ ! -d "venv" ]; then
        python -m venv venv
    else
        echo "venv already exists."
    fi

    # Install dependencies
    # venv/bin/pip install -r requirements.txt

    venv/bin/pip install torch-ema einops tensorboardX plyfile dearpygui huggingface_hub diffusers accelerate transformers xatlas torchvision
    venv/bin/pip install trimesh PyMCubes pymeshlab rembg[gpu,cli] omegaconf ninja gradio
    venv/bin/pip install https://github.com/camenduru/diff-gaussian-rasterization/releases/download/v1.0/diff_gaussian_rasterization-0.0.0-cp310-cp310-linux_x86_64.1.whl
    venv/bin/pip install https://github.com/camenduru/diff-gaussian-rasterization/releases/download/v1.0/simple_knn-0.0.0-cp310-cp310-linux_x86_64.1.whl
    venv/bin/pip install https://github.com/camenduru/diff-gaussian-rasterization/releases/download/v1.0/nvdiffrast-0.3.1-py3-none-any.whl
    venv/bin/pip install https://github.com/camenduru/diff-gaussian-rasterization/releases/download/v1.0/kiui-0.1.8-py3-none-any.whl
    apt install -qq -y xvfb

    # # a modified gaussian splatting (+ depth, alpha rendering)
    # git clone --recursive https://github.com/ashawkey/diff-gaussian-rasterization
    # venv/bin/pip install ./diff-gaussian-rasterization

    # # simple-knn
    # venv/bin/pip install ./simple-knn

    # # nvdiffrast
    # venv/bin/pip install git+https://github.com/NVlabs/nvdiffrast/

    # # kiuikit
    # venv/bin/pip install git+https://github.com/ashawkey/kiuikit

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# check if gradio_diffbir.py exists in DiffBIR_DIR, if exists, modify the file, replace block.launch() with block.launch(server_name="0.0.0.0")
if [ -f "${DREAMGAUSSIAN_DIR}/gradio_app.py" ]; then
    cd "${DREAMGAUSSIAN_DIR}" || exit
    echo "gradio_app.py exists. Modifying the file..."
    sed -i -E "s/demo\.queue\(\)\.launch\((server_name=\"0.0.0.0\", )?(server_port=[0-9]+)?\)/demo.queue().launch(server_name=\"0.0.0.0\", server_port=${SERVER_PORT})/g" "${DREAMGAUSSIAN_DIR}/gradio_app.py"
fi

# Run the server
echo "Running the server..."
cd "${DREAMGAUSSIAN_DIR}" || exit
venv/bin/python gradio_app.py