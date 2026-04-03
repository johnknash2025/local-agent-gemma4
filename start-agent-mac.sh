#!/bin/bash
# =============================================================
# Gemma 4 エージェント起動スクリプト (Mac ローカル版)
# Mac の Ollama を直接使用 (SSHトンネル不要)
# =============================================================

MODEL="${1:-gemma4:26b}"

echo "=========================================="
echo "  Gemma 4 Agent - Mac Local"
echo "  Model: ${MODEL}"
echo "=========================================="

# ----- 1. Ollama確認 -----
if ! curl -s --connect-timeout 3 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "[..] Ollama を起動中..."
    open -a Ollama
    sleep 3
    if ! curl -s --connect-timeout 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "[ERROR] Ollama が起動できません"
        echo "  /Applications/Ollama.app を手動で起動してください"
        exit 1
    fi
fi
echo "[OK] Ollama 稼働中"

# ----- 2. モデル確認 -----
if ! ollama list | grep -q "${MODEL}"; then
    echo "[..] モデル ${MODEL} をダウンロード中..."
    ollama pull "${MODEL}"
fi
echo "[OK] モデル ${MODEL} 準備完了"

# ----- 3. Ollama Code 起動 -----
echo ""
echo "--- Ollama Code を起動します ---"
echo "  Ctrl+C で終了"
echo ""

export OLLAMA_BASE_URL="http://localhost:11434/v1"
export OLLAMA_MODEL="${MODEL}"

ollama-code
