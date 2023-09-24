#!/bin/bash

ROOT_DIR="/workspace"    # Project root directory
DiffBIR_DIR="${ROOT_DIR}/DiffBIR"    # Path to clone Kohya library
WEIGHTS_DIR="${DiffBIR_DIR}/weights"
MODEL_URLs=(
    "https://huggingface.co/lxq007/DiffBIR/resolve/main/general_swinir_v1.ckpt"
    "https://huggingface.co/lxq007/DiffBIR/resolve/main/general_full_v1.ckpt"
    "https://huggingface.co/lxq007/DiffBIR/resolve/main/face_swinir_v1.ckpt"
    "https://huggingface.co/lxq007/DiffBIR/resolve/main/face_full_v1.ckpt"
)
SERVER_PORT=7860    # 服务器端口

# Clone the repository if WUERSTCHEN_DIR does not exist
if [ ! -d "${DiffBIR_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/XPixelGroup/DiffBIR.git "${DiffBIR_DIR}"
  
  # Navigate into the cloned directory
  cd "${DiffBIR_DIR}" || exit

  # create a virtual environment
  echo "Creating a virtual environment..."
  # if not venv exists, create one
  if [ ! -d "venv" ]; then
    python3 -m venv venv
  else
    echo "venv already exists."
  fi

  # Check if requirements.txt exists before installing the required packages
  echo "Installing the required packages..."
  venv/bin/pip install -r requirements.txt

  mkdir -p "${WEIGHTS_DIR}"
  echo "Downloading the models..."
  for MODEL_URL in "${MODEL_URLs[@]}"; do
      FILENAME=$(basename "${MODEL_URL}")
      aria2c --console-log-level=error -c -x 16 -s 16 -k 1M "${MODEL_URL}" -d "${WEIGHTS_DIR}" -o "${FILENAME}"
  done
fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# check if gradio_diffbir.py exists in DiffBIR_DIR, if exists, modify the file, replace block.launch() with block.launch(server_name="0.0.0.0")
if [ -f "${DiffBIR_DIR}/gradio_diffbir.py" ]; then
    echo "gradio_diffbir.py exists. Modifying the file..."
    sed -i -E "s/block\.launch\((server_name=\"0.0.0.0\", )?(server_port=[0-9]+)?\)/block.launch(server_name=\"0.0.0.0\", server_port=${SERVER_PORT})/g" "${DiffBIR_DIR}/gradio_diffbir.py"
fi

echo "Starting the application..."
cd "${DiffBIR_DIR}" || exit
venv/bin/python gradio_diffbir.py --ckpt "${WEIGHTS_DIR}/general_full_v1.ckpt" --config "${DiffBIR_DIR}/configs/model/cldm.yaml" --reload_swinir --swinir_ckpt "${WEIGHTS_DIR}/general_swinir_v1.ckpt"
# venv/bin/python gradio_diffbir.py --ckpt "${WEIGHTS_DIR}/face_full_v1.ckpt" --config "${DiffBIR_DIR}/configs/model/cldm.yaml" --reload_swinir --swinir_ckpt "${WEIGHTS_DIR}/face_swinir_v1.ckpt"
