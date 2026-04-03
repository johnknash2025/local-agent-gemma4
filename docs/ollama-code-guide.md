# Ollama Code 使い方ガイド

Mac ローカル または NVIDIA リモートの Gemma 4 を使って、ターミナルからAIエージェントを動かすためのガイド。

## 目次

1. [起動方法](#起動方法)
2. [対話モード](#対話モード)
3. [非対話モード (ワンショット)](#非対話モード-ワンショット)
4. [主要オプション一覧](#主要オプション一覧)
5. [プロジェクトでの使い方](#プロジェクトでの使い方)
6. [モデルの選び方](#モデルの選び方)
7. [実行例](#実行例)
8. [便利なエイリアス設定](#便利なエイリアス設定)
9. [トラブルシューティング](#トラブルシューティング)

---

## 起動方法

### Mac ローカル (推奨・簡単)

NVIDIAマシンなしで、Mac単体で動作します。

```bash
# スクリプトで起動 (トンネル不要)
cd ~/local-agent-gemma4
./start-agent-mac.sh              # gemma4:26b (デフォルト)
./start-agent-mac.sh gemma4:31b   # 最高性能
./start-agent-mac.sh gemma4:e2b   # 軽量・高速
```

スクリプトを使わず直接起動する場合:

```bash
# 環境変数を指定して起動
OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:26b
```

### NVIDIAマシン経由 (RTX 3090 で高速推論)

```bash
cd ~/local-agent-gemma4
./start-agent.sh                  # gemma4:26b (SSHトンネル自動)
./start-agent.sh gemma4:31b       # 31B (GPU推論で高速)
```

---

## 対話モード

スクリプトまたはコマンドを実行すると、対話プロンプトが表示されます。
自然言語で指示を出して、AIがコードの読み書き・ファイル操作・質問応答をします。

```
$ ./start-agent-mac.sh
==========================================
  Gemma 4 Agent - Mac Local
  Model: gemma4:26b
==========================================
[OK] Ollama 稼働中
[OK] モデル gemma4:26b 準備完了

--- Ollama Code を起動します ---

> ここに質問や指示を入力
```

### 対話モードでの操作例

```
> このプロジェクトのディレクトリ構造を説明して

> main.py のバグを見つけて修正して

> RESTful APIのエンドポイントを追加して

> このコードにユニットテストを書いて

> README.md を日本語で作成して

> git logの最近の変更を要約して

> package.json の依存関係をチェックして
```

### 終了方法

- `Ctrl+C` で終了
- または `exit` と入力

---

## 非対話モード (ワンショット)

`-p` オプションで1回だけ質問して結果を受け取れます。
スクリプトやパイプラインに組み込むときに便利。

```bash
# 1回だけ質問
OLLAMA_BASE_URL=http://localhost:11434/v1 \
  ollama-code -m gemma4:e2b -p "Pythonでフィボナッチ数列を生成する関数を書いて"

# ファイルの内容を渡して質問
cat main.py | OLLAMA_BASE_URL=http://localhost:11434/v1 \
  ollama-code -m gemma4:26b -p "このコードのバグを見つけて"
```

### 質問後に対話モードを継続

`-i` オプションを使うと、最初の質問を実行した後に対話モードに入ります。

```bash
OLLAMA_BASE_URL=http://localhost:11434/v1 \
  ollama-code -m gemma4:26b -i "このプロジェクトの構造を教えて"
# → 回答表示後、そのまま対話モードに入る
```

---

## 主要オプション一覧

| オプション | 短縮 | 説明 |
|-----------|------|------|
| `--model <名前>` | `-m` | 使用モデル (例: `gemma4:31b`) |
| `--prompt <テキスト>` | `-p` | 非対話モード。質問して結果だけ返す |
| `--prompt-interactive <テキスト>` | `-i` | 質問実行後、対話モードを継続 |
| `--all-files` | `-a` | 現在のディレクトリの全ファイルをコンテキストに含める |
| `--yolo` | `-y` | 全アクション自動承認 (確認なしでファイル編集等を実行) |
| `--checkpointing` | `-c` | ファイル編集のチェックポイント有効化 (ロールバック可能) |
| `--sandbox` | `-s` | サンドボックスモードで実行 |
| `--debug` | `-d` | デバッグ情報を表示 |
| `--list-extensions` | `-l` | 利用可能な拡張機能一覧 |
| `--openai-base-url <URL>` | | カスタムAPIエンドポイント |
| `--version` | `-v` | バージョン表示 |
| `--help` | `-h` | ヘルプ表示 |

---

## プロジェクトでの使い方

Ollama Code は **カレントディレクトリ** のファイルを読み書きします。
作業したいプロジェクトに移動してから起動してください。

```bash
# 例1: Plant Doctor API プロジェクトで使う
cd ~/plant-doctor-api
~/local-agent-gemma4/start-agent-mac.sh

# 例2: 任意のプロジェクトで31Bモデル
cd ~/my-awesome-project
~/local-agent-gemma4/start-agent-mac.sh gemma4:31b

# 例3: 全ファイルをコンテキストに含めて起動
cd ~/small-project
OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:26b --all-files
```

### --all-files について

- 小さいプロジェクト → `--all-files` を付けるとAIがプロジェクト全体を把握できて便利
- 大きいプロジェクト → 付けない方がよい (コンテキストが溢れる)
- 迷ったら付けずに起動し、必要なファイルをAIに都度伝える

### --yolo (自動承認モード) について

```bash
# 通常: ファイル編集前に確認プロンプトが出る
ollama-code -m gemma4:26b

# YOLO: 確認なしで全アクションを実行 (注意して使う)
ollama-code -m gemma4:26b -y
```

> **注意:** `--yolo` はファイルの書き換えを確認なしで行います。gitで管理されたプロジェクトでのみ使うことを推奨します。

---

## モデルの選び方

### Mac ローカル (M1 Max 64GB)

| モデル | メモリ使用 | 速度 | 品質 | おすすめ用途 |
|--------|----------|------|------|-------------|
| `gemma4:31b` | ~25GB | 遅め | 最高 | 複雑なリファクタリング・設計相談 |
| `gemma4:26b` | ~22GB | 普通 | 高い | **普段使い (おすすめ)** |
| `gemma4:e2b` | ~10GB | 速い | 普通 | クイックな質問・簡単な修正 |

### NVIDIA RTX 3090 (24GB VRAM)

| モデル | VRAM使用 | 速度 | 品質 | おすすめ用途 |
|--------|---------|------|------|-------------|
| `gemma4:31b` | ~19GB | 速い (GPU) | 最高 | 複雑なタスク (GPU推論は高速) |
| `gemma4:26b` | ~17GB | 速い (GPU) | 高い | **普段使い (おすすめ)** |
| `gemma4:e4b` | ~9.6GB | 非常に速い | 普通 | マルチモーダル (画像・音声) |
| `gemma4:e2b` | ~7.2GB | 最速 | 基本 | テスト・簡単な質問 |

### 判断フローチャート

```
31Bモデルが必要？
  ├─ Yes → NVIDIAマシンが起動中？
  │         ├─ Yes → ./start-agent.sh gemma4:31b (GPU高速)
  │         └─ No  → ./start-agent-mac.sh gemma4:31b (Mac CPU、遅めだが動く)
  └─ No  → 普段使い
            └─ ./start-agent-mac.sh (26b、Mac単体で十分)
```

---

## 実行例

### コード生成

```bash
$ OLLAMA_BASE_URL=http://localhost:11434/v1 \
  ollama-code -m gemma4:e2b -p "Pythonでフィボナッチ数列を生成する関数を書いて"

def fibonacci(n):
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    sequence = [0, 1]
    while len(sequence) < n:
        next_fib = sequence[-1] + sequence[-2]
        sequence.append(next_fib)
    return sequence
```

### コードレビュー

```bash
cat app.py | OLLAMA_BASE_URL=http://localhost:11434/v1 \
  ollama-code -m gemma4:26b -p "セキュリティの問題がないかレビューして"
```

### 対話モードでリファクタリング

```bash
$ cd ~/my-project
$ ~/local-agent-gemma4/start-agent-mac.sh gemma4:31b

> main.py の handle_request 関数が長すぎるのでリファクタリングして
> テストも書いて
> 変更内容をまとめて
```

---

## 便利なエイリアス設定

`~/.zshrc` に追加すると、どこからでも簡単に起動できます:

```bash
# ~/.zshrc に追加
alias gemma='OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:26b'
alias gemma31='OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:31b'
alias gemma-fast='OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:e2b'
alias gemma-gpu='~/local-agent-gemma4/start-agent.sh'
```

設定後:
```bash
source ~/.zshrc

# どこからでも使える
cd ~/my-project
gemma                      # 26b 対話モード
gemma31                    # 31b 対話モード
gemma-fast -p "1+1は？"    # e2b ワンショット
gemma-gpu gemma4:31b       # NVIDIA GPU経由
```

---

## トラブルシューティング

### 「Ollama が起動できません」

```bash
# Ollama アプリが起動しているか確認
curl http://localhost:11434/api/tags

# 起動していなければ
open -a Ollama
```

### 「モデルが見つかりません」

```bash
# ダウンロード済みモデル一覧
ollama list

# モデルをダウンロード
ollama pull gemma4:26b
```

### 応答が遅い

- `gemma4:31b` → `gemma4:26b` または `gemma4:e2b` に変更
- NVIDIA GPUを使う: `./start-agent.sh gemma4:31b`
- 他のアプリがメモリを大量消費していないか確認

### DEBUG出力が邪魔

`[DEBUG]` 行はstderrに出力されるので、リダイレクトで消せます:
```bash
OLLAMA_BASE_URL=http://localhost:11434/v1 ollama-code -m gemma4:26b 2>/dev/null
```

### Ollama Code のアップデート

```bash
npm update -g @tcsenpai/ollama-code
ollama-code --version
```
