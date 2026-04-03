#!/bin/bash
# =============================================================
# SSHトンネル管理 (Mac -> NVIDIAマシン Ollama)
# sudo不要でOllamaにアクセス可能にする
# =============================================================

NVIDIA_HOST="192.168.10.114"
NVIDIA_USER="johnkhappy"
LOCAL_PORT=11435

case "${1}" in
    start)
        if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
            echo "トンネル既に稼働中"
            lsof -i :${LOCAL_PORT} | grep ssh
        else
            echo "SSHトンネル起動中..."
            ssh -f -N -L ${LOCAL_PORT}:localhost:11434 ${NVIDIA_USER}@${NVIDIA_HOST}
            sleep 1
            if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
                echo "起動完了: localhost:${LOCAL_PORT} -> ${NVIDIA_HOST}:11434"
            else
                echo "起動失敗"
                exit 1
            fi
        fi
        ;;
    stop)
        PID=$(lsof -t -i :${LOCAL_PORT} 2>/dev/null | head -1)
        if [ -n "$PID" ]; then
            kill $PID
            echo "トンネル停止 (PID: ${PID})"
        else
            echo "稼働中のトンネルなし"
        fi
        ;;
    status)
        if lsof -i :${LOCAL_PORT} > /dev/null 2>&1; then
            echo "稼働中"
            curl -s http://localhost:${LOCAL_PORT}/api/tags | python3 -c "
import json,sys
for m in json.load(sys.stdin).get('models',[]):
    print(f'  - {m[\"name\"]}')
" 2>/dev/null
        else
            echo "停止中"
        fi
        ;;
    *)
        echo "使い方: $0 {start|stop|status}"
        ;;
esac
