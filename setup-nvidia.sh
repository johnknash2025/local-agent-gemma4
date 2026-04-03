#!/bin/bash
# =============================================================
# Gemma 4 ローカルエージェント セットアップ (NVIDIAマシン用)
# RTX 3090 (24GB VRAM) @ 192.168.10.114
# =============================================================
set -e

echo "=========================================="
echo "  Gemma 4 Local Agent Setup"
echo "  Target: RTX 3090 (24GB VRAM)"
echo "=========================================="

# ----- 1. Ollamaが起動しているか確認 -----
echo ""
echo "[1/3] Ollama の状態を確認..."
if ! command -v ollama &> /dev/null; then
    echo "ERROR: ollama が見つかりません。先にインストールしてください。"
    echo "  curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Ollama サービスを起動します..."
    ollama serve &
    sleep 3
fi
echo "  -> Ollama OK ($(ollama --version))"

# ----- 2. Gemma 4 モデルをダウンロード -----
echo ""
echo "[2/3] Gemma 4 モデルをダウンロード..."
echo "  (初回は時間がかかります)"
echo ""

echo "--- gemma4:31b (Dense最高性能, 19GB) ---"
ollama pull gemma4:31b

echo ""
echo "--- gemma4:26b (MoEバランス型, 17GB) ---"
ollama pull gemma4:26b

echo ""
echo "--- gemma4:e4b (マルチモーダル+音声, 9.6GB) ---"
ollama pull gemma4:e4b

echo ""
echo "--- gemma4:e2b (軽量・高速, 7.2GB) ---"
ollama pull gemma4:e2b

echo ""
echo "  -> モデルダウンロード完了"

# ----- 3. Open WebUI をDockerで起動 -----
echo ""
echo "[3/3] Open WebUI をセットアップ..."

if ! command -v docker &> /dev/null; then
    echo "WARNING: Docker が見つかりません。"
    echo "  Docker をインストールしてから再実行してください:"
    echo "  curl -fsSL https://get.docker.com | sh"
    echo "  sudo usermod -aG docker \$USER"
    exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
    echo "  既存の open-webui コンテナを更新します..."
    docker stop open-webui 2>/dev/null || true
    docker rm open-webui 2>/dev/null || true
fi

echo "  Open WebUI を起動中..."
docker run -d \
    --name open-webui \
    --restart always \
    --network host \
    -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
    -v open-webui-data:/app/backend/data \
    ghcr.io/open-webui/open-webui:main

echo "  -> Open WebUI 起動完了"

# ----- 完了 -----
echo ""
echo "=========================================="
echo "  セットアップ完了!"
echo "=========================================="
echo ""
echo "  利用可能なモデル:"
echo "    - gemma4:31b  (Dense最高性能, 19GB VRAM)"
echo "    - gemma4:26b  (MoEバランス型, 17GB)"
echo "    - gemma4:e4b  (マルチモーダル+音声, 9.6GB)"
echo "    - gemma4:e2b  (軽量・高速, 7.2GB)"
echo ""
echo "  WebUI:  http://192.168.10.114:8080"
echo ""
echo "  Mac から Ollama Code で使う場合:"
echo "    cd ~/local-agent-gemma4"
echo "    ./start-agent.sh gemma4:31b"
echo ""
