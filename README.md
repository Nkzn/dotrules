# dotrules

Claude Code開発のためのベストプラクティス・テンプレート集

## 概要

`dotrules`は、dotfiles文化にインスパイアされたClaude Code開発のためのルール・ベストプラクティス集です。複数のプロジェクト・マシン間で一貫したAI駆動開発体験を実現します。

## 特徴

- 🧪 **テスト戦略**: Vitest + Prisma + HonoXでの三層テスト戦略
- ⚡ **HonoXパターン**: Web標準準拠のフルスタック開発手法
- 🗄️ **Prismaガイドライン**: 型安全で高性能なORM運用方法
- 📝 **コミット戦略**: 効率的な開発・品質管理フロー
- 📋 **テンプレート**: すぐに使える設定ファイル・CLAUDE.md

## インストール

### 1. リポジトリのクローン

```bash
# ホームディレクトリの下にクローン
cd ~
git clone https://github.com/Nkzn/dotrules.git

# または開発ディレクトリに
cd ~/dev
git clone https://github.com/Nkzn/dotrules.git
```

### 2. 環境変数の設定（オプション）

```bash
# .bashrc または .zshrc に追加
export DOTRULES_PATH="$HOME/dotrules"
# または
export DOTRULES_PATH="$HOME/dev/dotrules"

# エイリアスを設定
alias claude-setup="$DOTRULES_PATH/scripts/setup-project.sh"
alias claude-link="$DOTRULES_PATH/scripts/link-practices.sh"
```

## 使用方法

### 方法1: git submodule統合（推奨）

```bash
# プロジェクトディレクトリでsubmoduleとして追加
cd your-project
git submodule add https://github.com/Nkzn/dotrules.git dotrules

# または自動セットアップスクリプトを使用
~/dotrules/scripts/setup-submodule.sh
```

**submoduleのメリット:**
- チーム全体で同じdotrulesバージョンを共有
- プロジェクトと一緒にバージョン管理
- CLAUDE.mdから直接参照可能

詳細は [SUBMODULE-USAGE.md](examples/SUBMODULE-USAGE.md) を参照してください。

### 方法2: 外部参照

```bash
# プロジェクトディレクトリで実行
cd your-project
~/dotrules/scripts/setup-project.sh

# または環境変数を設定している場合
claude-setup
```

### 方法3: 既存プロジェクトへのベストプラクティス適用

```bash
# ベストプラクティスドキュメントをリンク
~/dotrules/scripts/link-practices.sh

# または
claude-link
```

### 手動セットアップ

```bash
# CLAUDE.mdテンプレートをコピー
cp ~/dotrules/templates/CLAUDE.md.template ./CLAUDE.md

# 設定ファイルテンプレートをコピー
cp ~/dotrules/templates/vitest.config.ts.template ./vitest.config.ts
cp ~/dotrules/templates/tsconfig.json.template ./tsconfig.json
```

## ディレクトリ構造

```
dotrules/
├── README.md                              # このファイル
├── best-practices/                        # ベストプラクティス集
│   ├── testing-strategy.md                # テスト戦略
│   ├── honox-patterns.md                  # HonoXパターン
│   ├── prisma-guidelines.md               # Prismaガイドライン
│   └── development-workflow.md            # 開発ワークフロー
├── templates/                             # テンプレートファイル
│   ├── CLAUDE.md.template                 # Claude設定テンプレート
│   ├── vitest.config.ts.template          # Vitestテンプレート
│   ├── tsconfig.json.template             # TypeScriptテンプレート
│   └── package.json.snippets             # package.jsonスニペット
├── scripts/                               # セットアップスクリプト
│   ├── setup-project.sh                  # 新規プロジェクトセットアップ
│   ├── setup-submodule.sh                # submodule統合セットアップ
│   ├── link-practices.sh                 # ベストプラクティスリンク
│   └── update-templates.sh               # テンプレート更新
└── examples/                              # 使用例
    ├── USAGE.md                           # 基本的な使用例
    └── SUBMODULE-USAGE.md                 # submodule活用例
```

## ベストプラクティス一覧

### 🧪 テスト戦略 (`best-practices/testing-strategy.md`)
- ユニットテスト・統合テスト・APIテストの三層構造
- vitest-environment-vprismaを使った安定した統合テスト
- Prisma Fabbricaによるテストデータ生成
- エラー伝播テストとE2E統合テスト

### ⚡ HonoXパターン (`best-practices/honox-patterns.md`)
- Web標準準拠アプローチ
- Islandコンポーネント設計原則
- APIクエリパラメータ設計
- プログレッシブエンハンスメント

### 🗄️ Prismaガイドライン (`best-practices/prisma-guidelines.md`)
- 型安全なスキーマ設計
- 効率的なクエリパターン
- 外部キー制約と削除順序
- パフォーマンス最適化

### 📝 開発ワークフロー (`best-practices/development-workflow.md`)
- 小さく頻繁なコミット戦略
- Conventional Commitsベースのメッセージ形式
- WIPコミットの活用方法
- 品質管理の自動化

## プロジェクトでの参照方法

### CLAUDE.mdでの参照例

```markdown
# CLAUDE.md

## ベストプラクティス参照

このプロジェクトは [dotrules](https://github.com/Nkzn/dotrules) のベストプラクティスに従って開発されています：

- [テスト戦略](../dotrules/best-practices/testing-strategy.md)
- [HonoXパターン](../dotrules/best-practices/honox-patterns.md)
- [Prismaガイドライン](../dotrules/best-practices/prisma-guidelines.md)
- [開発ワークフロー](../dotrules/best-practices/development-workflow.md)

## プロジェクト固有の設定

[プロジェクト固有の内容をここに記載]
```

### 相対パスでの参照

```bash
# dotrulesをホームディレクトリに配置した場合
~/dotrules/best-practices/testing-strategy.md

# 開発ディレクトリに配置した場合
~/dev/dotrules/best-practices/testing-strategy.md

# プロジェクトからの相対パス（例）
../../dotrules/best-practices/testing-strategy.md
```

## テンプレート活用

### CLAUDE.mdテンプレート

```bash
# テンプレートをコピーして編集
cp ~/dotrules/templates/CLAUDE.md.template ./CLAUDE.md

# プロジェクト固有の内容を追加
# - プロジェクト概要
# - 技術スタック
# - ドメイン固有のルール
```

### 設定ファイルテンプレート

```bash
# Vitestテンプレート
cp ~/dotrules/templates/vitest.config.ts.template ./vitest.config.ts

# TypeScriptテンプレート
cp ~/dotrules/templates/tsconfig.json.template ./tsconfig.json
```

## アップデート

```bash
# dotrulesリポジトリを更新
cd ~/dotrules  # または ~/dev/dotrules
git pull origin main

# 既存プロジェクトのテンプレートを更新
~/dotrules/scripts/update-templates.sh
```


## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

## 関連リンク

- [Claude Code](https://claude.ai/code) - Anthropic公式Claude CLI
- [HonoX](https://github.com/honojs/honox) - フルスタックWebフレームワーク
- [Prisma](https://www.prisma.io/) - 次世代TypeScript ORM
- [Vitest](https://vitest.dev/) - 高速テストフレームワーク

---

**dotrulesで、一貫したAI駆動開発体験を実現しましょう！** 🚀