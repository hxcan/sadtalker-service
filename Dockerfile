# ================================
#  SadTalker 服务镜像（支持 amd64 + arm64）
#  基于 hxcan/pytorch-cuda 统一构建
# ================================

FROM hxcan/pytorch-cuda:latest

# 设置非交互式安装模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y \
        ffmpeg \
        git \
        wget \
        curl \
        tzdata \
        libgl1 \
        libglib2.0-0 \
        # 编译 av 所需的开发工具链
        pkg-config \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libavdevice-dev \
        libavfilter-dev \
        libavutil-dev \
        libswresample-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置时区
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 复制原始项目依赖并安装
COPY ./SadTalker/requirements.txt /app/
RUN pip install -r /app/requirements.txt --break-system-packages

# ✅ 注入 torchvision 兼容层
RUN mkdir -p /usr/local/lib/python3.12/dist-packages/torchvision/transforms/functional_tensor && \
    echo 'from torchvision.transforms.functional import rgb_to_grayscale' > /usr/local/lib/python3.12/dist-packages/torchvision/transforms/functional_tensor/__init__.py

# 复制本地服务依赖
COPY ./requirements.local.txt .
RUN pip install -r requirements.local.txt --break-system-packages

# 复制代码
COPY ./SadTalker /app
COPY ./serve.py /app/serve.py

# 自动下载权重
RUN chmod +x /app/scripts/download_models.sh && \
    /app/scripts/download_models.sh

WORKDIR /app

EXPOSE 5000

CMD ["python3", "serve.py"]
