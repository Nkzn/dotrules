# dotrules 使用例

このドキュメントでは、dotrulesを実際のプロジェクトで活用する具体的な使用例を紹介します。

## 基本的な使用フロー

### 1. dotrulesのセットアップ

```bash
# dotrulesをクローン
cd ~/dev  # または適切なディレクトリ
git clone https://github.com/Nkzn/dotrules.git

# 環境変数を設定（オプション）
echo 'export DOTRULES_PATH="$HOME/dev/dotrules"' >> ~/.bashrc
echo 'alias claude-setup="$DOTRULES_PATH/scripts/setup-project.sh"' >> ~/.bashrc
source ~/.bashrc
```

### 2. 新規プロジェクトでの使用

```bash
# 新規プロジェクトディレクトリを作成
mkdir my-honox-app
cd my-honox-app

# npm/pnpmでプロジェクト初期化
npm init -y
npm install hono @prisma/client
npm install -D honox prisma vitest typescript

# dotrulesセットアップスクリプトを実行
~/dev/dotrules/scripts/setup-project.sh

# または環境変数設定済みの場合
claude-setup
```

### 3. 既存プロジェクトでの使用

```bash
# 既存プロジェクトディレクトリに移動
cd existing-project

# ベストプラクティスリンクスクリプトを実行
~/dev/dotrules/scripts/link-practices.sh

# 生成されたCLAUDE.mdを編集してプロジェクト固有の情報を追加
```

## プロジェクトタイプ別の使用例

### HonoX + Prisma プロジェクト

```bash
# プロジェクト作成
mkdir my-web-app
cd my-web-app

# 依存関係のインストール
npm init -y
npm install hono @prisma/client
npm install -D honox @hono/vite-dev-server vite
npm install -D prisma vitest @vitest/ui vitest-environment-vprisma
npm install -D typescript @types/node tsx

# dotrulesセットアップ
~/dev/dotrules/scripts/setup-project.sh

# Prismaセットアップ
npx prisma init
# prisma/schema.prismaを編集
npx prisma migrate dev --name init
npm run prisma:generate

# HonoXプロジェクト構造を作成
mkdir -p app/routes app/islands src/lib
```

作成後のディレクトリ構造：
```
my-web-app/
├── CLAUDE.md                           # dotrulesテンプレートから生成
├── package.json
├── tsconfig.json                       # dotrulesテンプレート
├── vitest.config.ts                    # dotrulesテンプレート  
├── vitest.integration.config.ts        # dotrulesテンプレート
├── vitest.setup.ts                     # dotrulesテンプレート
├── vitest.integration.setup.ts         # dotrulesテンプレート
├── prisma/
│   └── schema.prisma
├── app/
│   ├── routes/
│   └── islands/
└── src/
    └── lib/
```

### 汎用TypeScriptプロジェクト

```bash
# プロジェクト作成
mkdir my-typescript-lib
cd my-typescript-lib

# 依存関係のインストール
npm init -y
npm install -D typescript @types/node tsx vitest

# dotrulesセットアップ
~/dev/dotrules/scripts/setup-project.sh

# ソースディレクトリ作成
mkdir -p src/__tests__
```

## CLAUDE.mdカスタマイズ例

### 実際のプロジェクト向けCLAUDE.md例

```markdown
# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## プロジェクト概要

ECサイト向けの在庫管理システムです。商品の在庫追跡、注文処理、レポート生成機能を提供します。

## アーキテクチャ

- **フロントエンド**: HonoX (SSR + Islands)
- **バックエンド**: Hono (REST API)
- **データベース**: PostgreSQL + Prisma ORM
- **テスト**: Vitest (三層テスト戦略)

## ベストプラクティス参照

このプロジェクトは [dotrules](https://github.com/Nkzn/dotrules) のベストプラクティスに従って開発されています：

- [テスト戦略](../dotrules/best-practices/testing-strategy-best-practices.md)
- [HonoXパターン](../dotrules/best-practices/honox-best-practices.md)
- [Prismaガイドライン](../dotrules/best-practices/prisma-best-practices.md)
- [開発ワークフロー](../dotrules/best-practices/development-commit-strategy.md)

## ドメイン固有のガイドライン

### ビジネスルール

1. **在庫管理**: 在庫数は負の値を取れません
2. **注文処理**: 注文確定後の商品変更は不可
3. **レポート**: 月次レポートは毎月1日に自動生成

### データモデル

- `Product`: 商品マスタ
- `Inventory`: 在庫情報
- `Order`: 注文データ
- `OrderItem`: 注文明細

### API設計

- RESTful設計に従う
- エラーレスポンスは統一フォーマット
- ページネーション対応必須

## 開発フロー

1. 機能実装前にテストケースを作成
2. ユニットテスト → 統合テスト → APIテストの順で実装
3. 品質チェック通過後にPR作成
```

## チーム開発での活用

### チームメンバーへの共有

```bash
# チーム全体でのdotrulesセットアップ
# 1. チームSlackでdotrulesリポジトリを共有
# 2. 各メンバーが個人環境にクローン
git clone https://github.com/Nkzn/dotrules.git ~/dev/dotrules

# 3. 既存プロジェクトにベストプラクティスを適用
cd team-project
~/dev/dotrules/scripts/link-practices.sh

# 4. CLAUDE.mdを編集してチーム固有のルールを追加
```

### プロジェクト標準化

```bash
# 新規プロジェクト作成時のテンプレート
mkdir new-feature-service
cd new-feature-service

# パッケージ初期化
npm init -y

# dotrulesセットアップ
~/dev/dotrules/scripts/setup-project.sh

# 推奨パッケージのインストール（package.json.snippetsを参考）
npm install hono @prisma/client
npm install -D honox vitest prisma typescript

# チーム固有のCLAUDE.mdテンプレートがある場合
cp ../team-templates/CLAUDE.md.team-template ./CLAUDE.md
```

## 継続的改善

### 定期的なアップデート

```bash
# 月1回程度の頻度でdotrulesとテンプレートを更新
cd ~/dev/dotrules
git pull origin main

# プロジェクトのテンプレートを更新
cd your-project
~/dev/dotrules/scripts/update-templates.sh

# 変更内容を確認してコミット
git diff
git add .
git commit -m "chore: dotrulesテンプレートを更新"
```

### ベストプラクティスのカスタマイズ

```bash
# チーム固有のベストプラクティスを追加
mkdir ~/dev/dotrules-custom
cp -r ~/dev/dotrules/* ~/dev/dotrules-custom/

# カスタムガイドラインを追加
echo "# チーム固有のガイドライン" > ~/dev/dotrules-custom/best-practices/team-specific.md

# CLAUDE.mdテンプレートにチーム固有の参照を追加
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. dotrulesディレクトリが見つからない

```bash
# エラー: dotrulesディレクトリが見つかりません
# 解決方法: 環境変数を設定
export DOTRULES_PATH="/path/to/your/dotrules"

# または直接パスを指定
/path/to/dotrules/scripts/setup-project.sh
```

#### 2. 相対パスが正しく設定されない

```bash
# CLAUDE.md内のパスを手動で修正
# 誤: ../dotrules/best-practices/...
# 正: ../../dotrules/best-practices/...

# または絶対パスを使用
# ~/dev/dotrules/best-practices/...
```

#### 3. テンプレートの更新で既存の設定が上書きされる

```bash
# バックアップから必要な内容を復元
cp vitest.config.ts.backup.20250101_120000 vitest.config.ts.custom
# 必要な設定を手動でマージ
```

## まとめ

dotrulesを活用することで：

1. **一貫した開発環境**: 全プロジェクトで統一されたツール設定
2. **品質の向上**: 実証済みのベストプラクティスの適用
3. **開発効率の向上**: テンプレートによる初期セットアップの自動化
4. **知識の共有**: チーム全体での開発ノウハウの標準化

継続的にdotrulesを更新・改善することで、さらなる開発体験の向上を実現できます。