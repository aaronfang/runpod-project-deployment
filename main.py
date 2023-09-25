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
                download_path = gr.components.Textbox(lines=1, placeholder="Select Destination Path", label="Download to ...")
                download_dropdown = gr.components.Dropdown(choices=[
                    '/workspace/stable-diffusion-webui/models/Stable-diffusion',
                    '/workspace/stable-diffusion-webui/models/Lora',
                    '/workspace/stable-diffusion-webui/models/VAE',
                    '/workspace/stable-diffusion-webui/embeddings',
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