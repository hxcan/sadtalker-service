# 使用官方的 Python 基础镜像（支持 arm64）
FROM nvidia/cuda:11.3.1-base-ubuntu20.04

# 设置非交互式安装模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    ffmpeg \
    git \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 手动设置时区为 Asia/Shanghai
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 安装 Python 3.8 + pip
RUN apt-get update && apt-get install -y python3 python3-pip && \
    ln -sf python3 /usr/bin/python

# ✅ 关键：使用 torch==1.12.1+cu113 的 Python 3.8 版本
RUN pip install torch==1.12.1+cu113 \
    torchvision==0.13.1+cu113 \
    torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113 \
    --force-reinstall \
    --no-cache-dir

# ✅ 直接安装 Flask
RUN pip install flask

# Step 1: 复制 requirements.txt
COPY ./SadTalker/requirements.txt /app/

# Step 2.3: 安装项目依赖
RUN pip install -r /app/requirements.txt

# Step 3: 复制代码
COPY ./SadTalker /app
COPY ./serve.py /app/serve.py

# ✅ 在构建时自动下载权重文件
RUN chmod +x /app/scripts/download_models.sh && \
    /app/scripts/download_models.sh

# 暴露端口
EXPOSE 5000

# 启动服务
CMD ["python", "serve.py"]
