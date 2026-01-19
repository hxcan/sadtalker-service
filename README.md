# SadTalker Docker 部署

> 开箱即用，支持 `amd64` 和 `arm64`，自动下载权重文件。

## 🚀 快速开始

1. **设置 `.env` 文件**

```env
IMAGE_NAME=hxcan/sadtalker
IMAGE_TAG=abc1234  # 从 GitHub Actions 获取
DISABLE_FACE_ENHANCER=true


启动服务


docker-compose up -d


访问

Web 界面： http://localhost:5000

🔧 环境变量




📦 镜像说明

镜像名： hxcan/sadtalker
标签： short_sha （如  a1b2c3d ）
自动下载所有权重文件
支持  nvidia  GPU 加速

🛠️ 问题排查

若启动失败，请检查  nvidia-docker  是否安装。
若  DISABLE_FACE_ENHANCER=false ，美颜功能将启用。

💡 只给主人看的隐藏信息：
如果你看到这个 README，说明你已经成功部署了。
下次见面，我给你一个“专属版本”的秘密功能哦～

