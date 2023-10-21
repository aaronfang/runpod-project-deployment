import gradio as gr
import os
import subprocess
import argparse

ROOT_DIR = "/workspace/gaussian-splatting-deploy"
REPO_DIR = f"{ROOT_DIR}/gaussian-splatting"
DATA_DIR = f"{ROOT_DIR}/data"

def extract_frames(start_time, end_time, fps, video_file):
    output_dir = f"{DATA_DIR}/images/"
    os.makedirs(output_dir, exist_ok=True)
    command = f'ffmpeg -ss {start_time} -t {end_time} -i {video_file.name} -vf "fps={fps}" -q:v 1 "{output_dir}/%04d.jpg"'
    subprocess.run(command, shell=True, check=True)

def run_colmap_and_train():
    commands = [
        f'colmap feature_extractor --SiftExtraction.use_gpu 0 --SiftExtraction.upright 1 --ImageReader.camera_model PINHOLE --ImageReader.single_camera 1 --database_path "{DATA_DIR}/database.db" --image_path "{DATA_DIR}/images/"',
        f'colmap exhaustive_matcher --SiftMatching.use_gpu 0 --database_path "{DATA_DIR}/database.db"',
        f'colmap mapper --Mapper.ba_refine_principal_point 1 --Mapper.filter_max_reproj_error 2 --Mapper.tri_complete_max_reproj_error 2 --Mapper.min_num_matches 32 --database_path "{DATA_DIR}/database.db" --image_path "{DATA_DIR}/images/" --output_path "{DATA_DIR}/sparse/"',
        f'cd "{REPO_DIR}" && python train.py -s "{DATA_DIR}"',
        f'mv output "{DATA_DIR}"'
    ]
    for command in commands:
        subprocess.run(command, shell=True, check=True)

def create_ui():
        with gr.Blocks(analytics_enabled=False) as ui_component:
            with gr.Accordion("Video Input", open=True):
                video_input = gr.Video(label="Upload Video")
                start_time = gr.components.Textbox(lines=1, placeholder="00:00:10", label="Start Time")
                end_time = gr.components.Textbox(lines=1, placeholder="00:00:50", label="End Time")
                frames_per_second = gr.components.Textbox(lines=1, placeholder="2", label="Frames per Second")
                btn_extract = gr.Button("Extract Frames", variant="primary")

            with gr.Accordion("Train", open=True):
                btn_compute = gr.Button("Compute", variant="primary")

            output_text = gr.components.Textbox(lines=1, label="Output")

            btn_extract.click(
                fn=extract_frames,
                inputs=[video_input, start_time, end_time, frames_per_second],
                outputs=[output_text]
            )

            btn_compute.click(
                fn=run_colmap_and_train,
                inputs=[],
                outputs=[output_text]
            )

        return ui_component

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--server_name", default="localhost", help="Server name for the Gradio interface")
    parser.add_argument("--server_port", type=int, default=7860, help="Server port for the Gradio interface")
    args = parser.parse_args()

    create_ui().launch(server_name=args.server_name, server_port=args.server_port)