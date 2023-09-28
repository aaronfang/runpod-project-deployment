import gradio as gr
import os
import subprocess
from func import download_files

class DeployApp:
    def __init__(self):

        self.session_dropdown = None

    def load_scripts(self):
        return [f for f in os.listdir('projects') if os.path.isfile(os.path.join('projects', f)) and f.endswith('.sh') and 'deploy' in f]

    def deploy(self, script):
        script = os.path.join('projects', script)
        subprocess.run(['chmod', '+x', script])
        subprocess.run(['bash', script])
        return {"message": "Deploy Complete"}

    def download(self, url, path):
        download_files([url], path)
        return "Download Complete"

    def kill_process_on_port(self, port):
        result = subprocess.run(['lsof', '-i', f':{port}'], capture_output=True, text=True)
        lines = result.stdout.splitlines()
        if len(lines) > 1:
            pid = lines[1].split()[1]
            subprocess.run(['kill', '-9', pid])
            return "Port Released"
        else:
            return "Port Not In Use"
    
    def send_files(self, paths):
        paths_list = paths.split(',')
        paths_list = [path.strip(' "\'') for path in paths_list]
        subprocess.run(['croc', 'send', '--code', 'runpod'] + paths_list)
        return "Files Sent"

    def create_ui(self):
        with gr.Blocks(analytics_enabled=False) as ui_component:
            with gr.Accordion("Projects to Deploy", open=True):
                deploy_dropdown = gr.components.Dropdown(choices=self.load_scripts(), value=self.load_scripts()[0], label="Select Deployment Script")
                btn_deploy = gr.Button("Deploy/Launch", variant="primary", )

            with gr.Accordion("Download Files", open=False):
                download_url = gr.components.Textbox(lines=1, placeholder="https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16", label="下载URL")
                url_dropdown = gr.components.Dropdown(choices=[
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_canny.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_canny_anime.safetensors",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_depth.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_depth_anime.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ip-adapter_sd15_plus.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ip-adapter_xl.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_blur.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_blur_anime.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ioclab_sd15_recolor.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_recolor_256lora.safetensors",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_openpose_anime_v2.safetensors",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_scribble.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_scribble_anime.safetensors",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_sketch_256lora.safetensors",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_softedge.pth",
                    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sargezt_xl_softedge.safetensors",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/blob/main/control_v11e_sd15_ip2p.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11e_sd15_shuffle.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_inpaint.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15s2_lineart_anime.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_mlsd.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_normalbae.pth",
                    "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_seg.pth",
                    ], label="Preset URLs")
                download_path = gr.components.Textbox(lines=1, placeholder="Select Destination Path", label="Download to ...")
                download_dropdown = gr.components.Dropdown(choices=[
                    '/workspace/stable-diffusion-webui/models/Stable-diffusion',
                    '/workspace/stable-diffusion-webui/models/Lora',
                    '/workspace/stable-diffusion-webui/models/VAE',
                    '/workspace/stable-diffusion-webui/embeddings',
                    '/workspace/stable-diffusion-webui/extensions/sd-webui-controlnet',
                    ], label="Preset Paths")
                btn_download = gr.Button("Download", variant="primary", )

            with gr.Accordion("Kill Process on Port", open=False):
                port_input = gr.components.Textbox(lines=1, placeholder="Enter Port Number", label="Port")
                btn_kill = gr.Button("Kill Process", variant="primary", )

            with gr.Accordion("Send Files", open=False):
                paths_input = gr.components.Textbox(lines=1, placeholder="Enter Paths Separated by Comma", label="Paths")
                btn_send = gr.Button("Send Files", variant="primary", )

            output_text = gr.components.Textbox(lines=1, label="Output")

            btn_deploy.click(
                fn=self.deploy,
                inputs=[deploy_dropdown],
                outputs=[output_text]
            )
        
            btn_download.click(
                fn=self.download,
                inputs=[download_url, download_path],
                outputs=[output_text]
            )

            url_dropdown.change(
                fn=lambda dropdown_selected: dropdown_selected,
                inputs=[url_dropdown],
                outputs=[download_url]
            )

            download_dropdown.change(
                fn=lambda dropdown_selected: dropdown_selected,
                inputs=[download_dropdown],
                outputs=[download_path]
            )

            btn_kill.click(
                fn=self.kill_process_on_port,
                inputs=[port_input],
                outputs=[output_text]
            )

            btn_send.click(
                fn=self.send_files,
                inputs=[paths_input],
                outputs=[output_text]
            )

        return ui_component


app = DeployApp()
iface = app.create_ui()
iface.launch(server_name="0.0.0.0", server_port=4444, share=True)