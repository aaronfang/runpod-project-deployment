import gradio as gr
import os
import subprocess

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

def create_interface():
    video_input = gr.inputs.Video(label="视频文件")
    start_time_input = gr.inputs.Textbox(label="开始时间")
    end_time_input = gr.inputs.Textbox(label="结束时间")
    fps_input = gr.inputs.Textbox(label="每秒截取图片的数量")
    extract_frames_button = gr.outputs.Button(label="导出图片帧", action=extract_frames)
    run_button = gr.outputs.Button(label="运行计算和训练", action=run_colmap_and_train)

    interface = gr.Interface(
        fn=[extract_frames, run_colmap_and_train],
        inputs=[video_input, start_time_input, end_time_input, fps_input],
        outputs=[extract_frames_button, run_button],
        title="Gaussian Splatting",
        description="导入视频，导出图片帧，运行计算和训练"
    )
    interface.launch(server_name="0.0.0.0", server_port=7860)

if __name__ == "__main__":
    create_interface()