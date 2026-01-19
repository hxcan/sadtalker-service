from flask import Flask, request, send_file, jsonify
import subprocess
import os
import glob
import time

app = Flask(__name__)

# 检查 GPU 是否可用
def is_gpu_available():
    try:
        import torch
        return torch.cuda.is_available()
    except Exception as e:
        print(f"Error importing torch or checking CUDA: {e}")
        return False

@app.route('/animate', methods=['POST'])
def animate():
    try:
        # 获取上传的文件
        source_image = request.files.get('source_image')
        driven_audio = request.files.get('driven_audio')

        if not source_image or not driven_audio:
            return jsonify({"error": "Both source_image and driven_audio are required"}), 400

        # 创建唯一的输出目录
        output_dir = os.path.join("results", f"{int(time.time() * 1000)}")
        os.makedirs(output_dir, exist_ok=True)

        # 保存上传的文件
        image_path = os.path.join(output_dir, source_image.filename)
        audio_path = os.path.join(output_dir, driven_audio.filename)
        source_image.save(image_path)
        driven_audio.save(audio_path)

        # 读取环境变量：是否必须使用 GPU（默认为 true）
        require_gpu = os.getenv("REQUIRE_GPU", "true").lower() == "true"
        gpu_available = is_gpu_available()

        # 如果要求必须使用 GPU 但不可用，直接返回错误
        if require_gpu and not gpu_available:
            return jsonify({
                "error": "GPU is required but not available. "
                         "Please check if GPU is accessible in the container."
            }), 500

        # ✅ 不需要添加 --device cpu，SadTalker 会自动 fallback

        # 构建命令（完全交给 SadTalker 自动选择设备）
        command = [
            "python", "inference.py",
            "--driven_audio", audio_path,
            "--source_image", image_path,
            "--result_dir", output_dir
        ]

        # 可选：启用人脸增强
        disable_face_enhancer = os.getenv("DISABLE_FACE_ENHANCER", "false").lower() == "true"
        if not disable_face_enhancer:
            command += ["--enhancer", "gfpgan"]

        # 执行推理（SadTalker 内部会处理 device 选择）
        subprocess.run(command, check=True)

        # 查找生成的视频
        generated_videos = glob.glob(os.path.join(output_dir, "*.mp4"))
        if not generated_videos:
            return jsonify({"error": "No video file was generated"}), 500

        result_video = generated_videos[0]
        return send_file(result_video, as_attachment=True, download_name="result.mp4")

    except subprocess.CalledProcessError as e:
        return jsonify({"error": "Failed to generate animation", "details": str(e)}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
