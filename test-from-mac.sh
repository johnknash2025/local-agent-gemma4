#!/bin/bash
# =============================================================
# Mac から Gemma 4 の動作テスト
# SSHトンネル経由でNVIDIAマシンに接続
# =============================================================

LOCAL_PORT=11435
WEBUI_URL="http://192.168.10.114:8080"

echo "=========================================="
echo "  Gemma 4 接続テスト (Mac -> NVIDIA)"
echo "=========================================="

# ----- 1. SSHトンネル確認 -----
echo ""
echo "[1/4] SSHトンネル確認..."
if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
    echo "  -> トンネル稼働中 (port ${LOCAL_PORT})"
else
    echo "  -> トンネル未起動。起動します..."
    ./tunnel.sh start
fi

# ----- 2. Ollama API 疎通確認 -----
echo ""
echo "[2/4] Ollama API 疎通確認..."
if curl -s --connect-timeout 5 "http://localhost:${LOCAL_PORT}/api/tags" > /dev/null 2>&1; then
    echo "  -> Ollama API OK"
else
    echo "  -> ERROR: Ollama API に接続できません"
    echo "     ./tunnel.sh start を実行してください"
    exit 1
fi

# ----- 3. 利用可能なモデル一覧 -----
echo ""
echo "[3/4] 利用可能なモデル:"
curl -s "http://localhost:${LOCAL_PORT}/api/tags" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for m in data.get('models', []):
    size_gb = m.get('size', 0) / (1024**3)
    print(f'  - {m[\"name\"]:30s} ({size_gb:.1f} GB)')
" 2>/dev/null || echo "  (python3が必要です)"

# ----- 4. Gemma 4 チャットテスト -----
echo ""
echo "[4/4] Gemma 4 チャットテスト (gemma4:e2b)..."
echo "  質問: 「こんにちは、自己紹介して」"
echo ""

RESPONSE=$(curl -s "http://localhost:${LOCAL_PORT}/api/chat" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gemma4:e2b",
        "messages": [
            {"role": "user", "content": "こんにちは、一言で自己紹介して"}
        ],
        "stream": false
    }' --max-time 60)

echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
msg = data.get('message', {}).get('content', 'No response')
print(f'  Gemma 4 応答: {msg}')
total = data.get('total_duration', 0) / 1e9
print(f'  応答時間: {total:.1f}秒')
" 2>/dev/null || echo "$RESPONSE"

# ----- Open WebUI 確認 -----
echo ""
echo "[追加] Open WebUI: ${WEBUI_URL}"

echo ""
echo "=========================================="
echo "  テスト完了"
echo "=========================================="
echo ""
echo "  エージェント起動:"
echo "    ./start-agent.sh              # gemma4:26b (デフォルト)"
echo "    ./start-agent.sh gemma4:31b   # 31Bモデル"
echo ""
