# runpod-project-deployment
> Deploy tool for various projects in Runpod

### Projects
- [Stable-Diffusion-Webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- [Kohya_ss](https://github.com/bmaltais/kohya_ss)
- [diffBIR](https://github.com/XPixelGroup/DiffBIR)
- [Wuerstchen](https://github.com/dome272/Wuerstchen)
- [Rerender_A_Video](https://github.com/williamyang1991/Rerender_A_Video)

### Usage
```bash
python main.py
```
It will launch a web server on port 4444. You can access it by visiting `http://localhost:4444` in your browser.

#### Or  

Copy `launcher.sh` to Runpod /workspace folder and run it.
```bash
chmod +x launcher.sh
./launcher.sh
```
It will automatic clone this repo and install all dependencies. Then launch a web server on port 4444. You can access it by visiting `http://0.0.0.0:4444` in your browser.