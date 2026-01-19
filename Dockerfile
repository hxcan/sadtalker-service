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

# 安装 Miniconda
RUN curl -o /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

# 设置环境变量
ENV PATH="/opt/conda/bin:$PATH"

# 创建并激活 Conda 环境
RUN conda create -n sadtalker python=3.8 -y
ENV CONDA_DEFAULT_ENV=sadtalker
ENV PATH="/opt/conda/envs/sadtalker/bin:$PATH"

# Step 2.1: 安装 PyTorch（CUDA 113）
RUN pip install torch==1.12.1+cu113 \
    torchvision==0.13.1+cu113 \
    torchaudio==0.12.1 \
    --extra-index-url https://download.pytorch.org/whl/cu113

# Step 2.2: 安装 Flask（单独一层，便于后续更新）
RUN pip install flask

# Step 1: 复制 requirements.txt
COPY ./SadTalker/requirements.txt /app/

# Step 2.3: 安装项目依赖
RUN pip install -r /app/requirements.txt

# Step 3: 复制代码
COPY ./SadTalker /app
COPY ./serve.py /app/serve.py

# ✅ 关键：在构建时自动下载权重文件
RUN chmod +x /app/scripts/download_models.sh && \
    /app/scripts/download_models.sh

# 暴露端口
EXPOSE 5000

# 启动服务
CMD ["python", "serve.py"]
