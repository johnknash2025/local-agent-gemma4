#!/bin/bash
# =============================================================
# Gemma 4 エージェント起動スクリプト (Mac用)
# SSHトンネル経由でNVIDIAマシンのOllamaに接続
# =============================================================

NVIDIA_HOST="192.168.10.114"
NVIDIA_USER="johnkhappy"
LOCAL_PORT=11435
MODEL="${1:-gemma4:26b}"

echo "=========================================="
echo "  Gemma 4 Agent (Ollama Code)"
echo "  Model: ${MODEL}"
echo "=========================================="

# ----- 1. SSHトンネル確認・起動 -----
if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
    echo "[OK] SSHトンネル既に稼働中 (port ${LOCAL_PORT})"
else
    echo "[..] SSHトンネルを起動中..."
    ssh -f -N -L ${LOCAL_PORT}:localhost:11434 ${NVIDIA_USER}@${NVIDIA_HOST}
    sleep 1
    if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
        echo "[OK] SSHトンネル起動完了"
    else
        echo "[ERROR] SSHトンネル起動失敗"
        echo "  手動で試してください: ssh -L 11434:localhost:11434 ${NVIDIA_USER}@${NVIDIA_HOST}"
        exit 1
    fi
fi

# ----- 2. Ollama接続テスト -----
echo "[..] Ollama接続テスト..."
if curl -s --connect-timeout 5 http://localhost:${LOCAL_PORT}/api/tags > /dev/null 2>&1; then
    echo "[OK] Ollama接続成功"
else
    echo "[ERROR] Ollamaに接続できません"
    exit 1
fi

# ----- 3. Ollama Code 起動 -----
echo ""
echo "--- Ollama Code を起動します ---"
echo "  /help でコマンド一覧"
echo "  Ctrl+C で終了"
echo ""

export OLLAMA_BASE_URL="http://localhost:${LOCAL_PORT}/v1"
export OLLAMA_MODEL="${MODEL}"

ollama-code
