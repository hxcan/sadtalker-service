#!/bin/bash

# 智能重试脚本：先拉取所有所需镜像，再启动服务
# 自动从 docker-compose.yml 提取镜像列表

MAX_RETRIES=0
RETRY_DELAY_SEC=10

# 获取当前目录下 compose 文件定义的所有镜像（去重）
get_images() {
    # 使用 docker compose config 输出标准化配置，再用 jq 提取 image 字段
    if ! docker compose config --format json | jq -r '.services[].image // empty' 2>/dev/null | sort -u; then
        echo "Error: Failed to parse docker-compose.yml. Please check syntax." >&2
        exit 1
    fi
}

# 重试拉取单个镜像
pull_image_with_retry() {
    local image=$1
    local attempt=1
    while true; do
        echo "Pulling image: $image (attempt $attempt)..."
        if docker pull "$image" >/dev/null 2>&1; then
            echo "✓ Pulled: $image"
            return 0
        else
            echo "✗ Failed to pull: $image"
            if [[ $MAX_RETRIES -gt 0 ]] && [[ $attempt -ge $MAX_RETRIES ]]; then
                echo "Reached max retries for image: $image" >&2
                return 1
            fi
            ((attempt++))
            sleep $RETRY_DELAY_SEC
        fi
    done
}

# 主流程
echo "🔍 Detecting required images from docker-compose.yml..."
images=()
while IFS= read -r img; do
    images+=("$img")
done < <(get_images)

if [[ ${#images[@]} -eq 0 ]]; then
    echo "⚠️  No 'image' fields found in services. Falling back to direct compose up."
else
    echo "📦 Found ${#images[@]} image(s): ${images[*]}"
    echo "🔄 Pulling all images before starting services..."

    for img in "${images[@]}"; do
        if ! pull_image_with_retry "$img"; then
            echo "❌ Aborting due to pull failure for image: $img"
            exit 1
        fi
    done
fi

echo "🛑 Stopping existing services..."
docker compose down >/dev/null 2>&1

echo "🚀 Starting services..."
if docker compose up -d; then
    echo "✅ Success: All services are up!"
    exit 0
else
    echo "💥 Failed to start services after successful pull." >&2
    exit 1
fi
