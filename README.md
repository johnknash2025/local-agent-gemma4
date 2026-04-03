# Gemma 4 ローカルエージェント

Google Gemma 4 を RTX 3090 で動かし、Mac から **Ollama Code (CLIエージェント)** と **Open WebUI (ブラウザチャット)** で利用するためのセットアップ一式。

## 構成図

```
┌─────────────────────────────────┐
│  Mac (クライアント)               │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Ollama Code (CLIエージェント) │  │
│  │ ファイル編集・コード生成・質問応答   │  │
│  └──────────┬────────────────┘  │
│             │ SSHトンネル            │
│             │ localhost:11435       │
│             │                      │
│  ┌──────────┴────────────────┐  │
│  │ ブラウザ (Open WebUI)        │  │
│  │ http://192.168.10.114:8080  │  │
│  └───────────────────────────┘  │
└──────────────┬──────────────────┘
               │
               │ LAN (192.168.10.x)
               │
┌──────────────▼──────────────────┐
│  NVIDIAマシン (192.168.10.114)    │
│  RTX 3090 (24GB VRAM)           │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Ollama (ポート 11434)       │  │
│  │  ├ gemma4:31b (19GB)       │  │
│  │  ├ gemma4:26b (17GB)       │  │
│  │  ├ gemma4:e4b (9.6GB)     │  │
│  │  └ gemma4:e2b (7.2GB)     │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Open WebUI (Docker :8080)  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

## 利用可能なモデル

| モデル | サイズ | 特徴 | おすすめ用途 |
|--------|--------|------|-------------|
| `gemma4:31b` | 19GB | Dense最高性能。マルチモーダル対応 | 複雑な推論・コード生成・長文 |
| `gemma4:26b` | 17GB | MoE (アクティブ4B)。性能/効率バランス最良 | 普段使い（推奨デフォルト） |
| `gemma4:e4b` | 9.6GB | マルチモーダル+音声対応 | 画像・音声を含むタスク |
| `gemma4:e2b` | 7.2GB | 軽量・高速。3倍速 | テスト・簡単な質問 |

> **注意:** `gemma4:31b` はVRAMをほぼフル使用 (19/24GB)。Plant Doctor API等と同時使用する場合は `gemma4:26b` 以下を推奨。

---

## クイックスタート

### 前提条件

- **NVIDIAマシン:** Ollama インストール済み、Docker インストール済み
- **Mac:** Node.js 20+、SSH接続設定済み

### Step 1: NVIDIAマシンのセットアップ

```bash
# NVIDIAマシンにSSH
ssh johnkhappy@192.168.10.114

# Ollamaを最新版に更新
curl -fsSL https://ollama.com/install.sh | sh

# Gemma 4 モデルをダウンロード
ollama pull gemma4:31b    # 最高性能 (19GB)
ollama pull gemma4:26b    # バランス型 (17GB)
ollama pull gemma4:e4b    # 中量級 (9.6GB)
ollama pull gemma4:e2b    # 軽量 (7.2GB)

# Open WebUI 起動 (ブラウザチャット用)
docker run -d \
  --name open-webui \
  --restart always \
  --network host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui-data:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

### Step 2: Mac に Ollama Code をインストール

```bash
npm install -g @tcsenpai/ollama-code
```

### Step 3: エージェント起動

```bash
cd ~/local-agent-gemma4
./start-agent.sh              # デフォルト: gemma4:26b
./start-agent.sh gemma4:31b   # 31Bモデルで起動
./start-agent.sh gemma4:e2b   # 軽量モデルで起動
```

---

## 使い方ガイド

### Ollama Code (CLIエージェント)

Ollama Code は Gemini CLI のフォークで、ターミナルから対話的にAIを使えるCLIエージェントです。

#### 起動方法

```bash
# 方法1: start-agent.sh を使う (SSHトンネル自動管理)
./start-agent.sh gemma4:31b

# 方法2: 手動で起動 (トンネル起動済みの場合)
OLLAMA_BASE_URL=http://localhost:11435/v1 ollama-code -m gemma4:31b

# 方法3: 環境変数をexport
export OLLAMA_BASE_URL="http://localhost:11435/v1"
export OLLAMA_MODEL="gemma4:26b"
ollama-code
```

#### 主要オプション

```bash
ollama-code [オプション]

  -m, --model <名前>         使用モデル (例: gemma4:31b)
  -p, --prompt <テキスト>     非対話モード (1回だけ質問して終了)
  -i, --prompt-interactive   質問実行後、対話モードを継続
  -a, --all-files            現在のディレクトリの全ファイルをコンテキストに含める
  -y, --yolo                 全アクション自動承認 (確認なし)
  -c, --checkpointing        ファイル編集のチェックポイント有効化
  -s, --sandbox              サンドボックスモードで実行
  -d, --debug                デバッグモード
  -l, --list-extensions      利用可能な拡張機能一覧
  -v, --version              バージョン表示
  -h, --help                 ヘルプ表示
```

#### 使用例

```bash
# プロジェクトディレクトリで対話モード起動
cd ~/my-project
OLLAMA_BASE_URL=http://localhost:11435/v1 ollama-code -m gemma4:31b

# 1回だけ質問 (非対話)
ollama-code -m gemma4:e2b -p "このプロジェクトの構造を説明して"

# 質問してからそのまま対話モードへ
ollama-code -m gemma4:26b -i "このコードのバグを見つけて"

# 全ファイルをコンテキストに含めて起動
ollama-code -m gemma4:26b --all-files

# 自動承認モード (ファイル編集を確認なしで実行)
ollama-code -m gemma4:26b -y
```

#### 対話モードでできること

起動後のプロンプトで、自然言語で指示を出します:

```
> このプロジェクトの構造を説明して

> main.py のエラーハンドリングを改善して

> RESTful APIのエンドポイントを追加して

> このコードのユニットテストを書いて

> git logの最近の変更をまとめて

> package.json の依存関係を更新して

> セキュリティの問題がないかチェックして
```

#### モデル別の使い分け

```bash
# 複雑なコードリファクタリング -> 31b
./start-agent.sh gemma4:31b
> この関数をリファクタリングして、SOLID原則に従うようにして

# 日常的な質問・コード生成 -> 26b
./start-agent.sh gemma4:26b
> FastAPIでCRUD APIを作って

# クイックな質問 -> e2b (高速)
./start-agent.sh gemma4:e2b
> この変数名をもっと分かりやすくして
```

### Open WebUI (ブラウザチャット)

ブラウザで `http://192.168.10.114:8080` を開く。

- 初回アクセス時にアカウント作成（最初のユーザーが管理者）
- チャット画面上部のドロップダウンでモデル選択
- マルチモーダル: 画像をアップロードして質問可能
- 会話履歴が自動保存される

### OpenAI互換 API

OllamaはOpenAI互換APIを提供するので、既存のツールやスクリプトからも使えます。

```bash
# SSHトンネル経由 (Mac)
curl http://localhost:11435/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:31b",
    "messages": [{"role": "user", "content": "こんにちは"}]
  }'
```

```python
# Python (openaiライブラリ)
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:11435/v1",
    api_key="unused"
)

response = client.chat.completions.create(
    model="gemma4:31b",
    messages=[{"role": "user", "content": "日本の農業の課題は？"}]
)
print(response.choices[0].message.content)
```

---

## SSHトンネル管理

Mac のポート 11434 は既にローカル Ollama が使用しているため、ポート **11435** でSSHトンネルを張ります。

```bash
# トンネル起動
./tunnel.sh start

# 状態確認 + モデル一覧表示
./tunnel.sh status

# トンネル停止
./tunnel.sh stop
```

手動でトンネルを張る場合:
```bash
ssh -f -N -L 11435:localhost:11434 johnkhappy@192.168.10.114
```

---

## ファイル構成

```
local-agent-gemma4/
├── README.md              # このドキュメント
├── start-agent.sh         # Ollama Code 起動 (Mac用、トンネル自動管理)
├── tunnel.sh              # SSHトンネル管理 (start/stop/status)
├── setup-nvidia.sh        # NVIDIAマシン初期セットアップ
├── test-from-mac.sh       # Macからの接続テスト
└── docker-compose.yml     # Open WebUI Docker構成 (NVIDIAマシン用)
```

---

## トラブルシューティング

### Ollama Code が接続できない

```bash
# 1. トンネルの状態確認
./tunnel.sh status

# 2. トンネルが停止していたら起動
./tunnel.sh start

# 3. NVIDIAマシンのOllamaが動いているか確認
ssh johnkhappy@192.168.10.114 "systemctl status ollama"
```

### VRAM不足でモデルが動かない

```bash
# 現在のGPU使用状況を確認
ssh johnkhappy@192.168.10.114 "nvidia-smi"

# 31bが動かない場合、26bに切り替え
./start-agent.sh gemma4:26b
```

### Ollama Code のバージョン確認・更新

```bash
ollama-code --version
npm update -g @tcsenpai/ollama-code
```

### Open WebUI にアクセスできない

```bash
# NVIDIAマシンでコンテナ確認
ssh johnkhappy@192.168.10.114 "docker ps | grep open-webui"

# 再起動
ssh johnkhappy@192.168.10.114 "docker restart open-webui"
```

### Open WebUI の更新

```bash
ssh johnkhappy@192.168.10.114 "docker pull ghcr.io/open-webui/open-webui:main && docker stop open-webui && docker rm open-webui"
# その後 setup-nvidia.sh のStep 4を再実行、または:
ssh johnkhappy@192.168.10.114 "docker run -d --name open-webui --restart always --network host -e OLLAMA_BASE_URL=http://127.0.0.1:11434 -v open-webui-data:/app/backend/data ghcr.io/open-webui/open-webui:main"
```

---

## 参考リンク

- [Ollama Code (GitHub)](https://github.com/tcsenpai/ollama-code)
- [Google Gemma 4 公式ブログ](https://blog.google/technology/developers/gemma-4/)
- [Ollama Gemma 4 モデル](https://ollama.com/library/gemma4)
- [Open WebUI (GitHub)](https://github.com/open-webui/open-webui)
