#!/bin/bash
# new-api 一键重建部署脚本
# 用法: bash /root/new-api-rebuild.sh

set -e
cd /root/new-api

echo "📥 拉取最新代码..."
git pull

echo "🔨 构建镜像（约5-10分钟，限制内存 800MB）..."
DOCKER_BUILDKIT=1 docker build --memory 800m -t new-api:local .

echo "🔄 重启容器..."
docker stop new-api 2>/dev/null || true
docker rm new-api 2>/dev/null || true

docker run -d --name new-api --restart always \
  --network host \
  --memory 400m \
  -e PORT=6000 \
  -e SQL_DSN="root:123456@tcp(127.0.0.1:3306)/newapi?charset=utf8mb4&parseTime=true&loc=Local" \
  -e REDIS_CONN_STRING="redis://127.0.0.1:6379" \
  -e TZ=Asia/Shanghai \
  -e ERROR_LOG_ENABLED=true \
  -e BATCH_UPDATE_ENABLED=true \
  -e SESSION_SECRET="$(cat /root/new-api/.session_secret 2>/dev/null || (tr -dc A-Za-z0-9 </dev/urandom | head -c 32 | tee /root/new-api/.session_secret))" \
  -v /root/new-api/data:/data \
  -v /root/new-api/logs:/app/logs \
  new-api:local

sleep 5
echo "✅ 完成 — $(curl -s http://localhost:6000/api/status | grep -o '"version":"[^"]*"')"
