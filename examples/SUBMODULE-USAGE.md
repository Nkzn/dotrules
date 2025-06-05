# dotrules Submodule使用例

このドキュメントでは、dotrulesをgit submoduleとして活用する方法を詳しく説明します。

## 概要

git submoduleを使用することで、dotrulesをプロジェクトの一部として統合し、チーム全体で統一された開発環境を実現できます。

## 基本的なsubmodule使用フロー

### 1. 新規プロジェクトでのsubmodule導入

```bash
# 新規プロジェクトを作成
mkdir my-new-project
cd my-new-project
git init

# dotrulesをsubmoduleとして追加
./path/to/dotrules/scripts/setup-submodule.sh

# または手動で追加
git submodule add https://github.com/Nkzn/dotrules.git dotrules
git submodule update --init --recursive
```

### 2. 既存プロジェクトへのsubmodule追加

```bash
# 既存プロジェクトディレクトリに移動
cd existing-project

# dotrulesをsubmoduleとして追加
git submodule add https://github.com/Nkzn/dotrules.git dotrules

# CLAUDE.mdを作成（submodule用パス）
cp dotrules/templates/CLAUDE.md.template CLAUDE.md
sed -i 's|PATH_TO_DOTRULES|dotrules|g' CLAUDE.md

# コミット
git add .gitmodules dotrules CLAUDE.md
git commit -m "feat: dotrulesをsubmoduleとして追加"
```

## チーム開発でのsubmodule管理

### チームメンバーの初期セットアップ

```bash
# 新しいチームメンバーがリポジトリをクローン
git clone --recursive https://github.com/team/project.git

# または通常のクローン後にsubmoduleを初期化
git clone https://github.com/team/project.git
cd project
git submodule update --init --recursive
```

### submoduleの更新

```bash
# dotrulesの最新版に更新
git submodule update --remote dotrules
git add dotrules
git commit -m "chore: dotrulesを最新版に更新"

# プルリクエストを作成してチームに共有
git push origin feature/update-dotrules
```

### 特定バージョンへの固定

```bash
# 特定のタグ・バージョンに固定
cd dotrules
git checkout v1.2.3
cd ..

# 変更をコミット
git add dotrules
git commit -m "chore: dotrules v1.2.3に固定"

# タグ情報をチームと共有
git tag -a project-v1.0.0 -m "Project v1.0.0 with dotrules v1.2.3"
git push origin project-v1.0.0
```

## CLAUDE.mdでのsubmodule参照

### 基本的な参照パターン

```markdown
# CLAUDE.md

## ベストプラクティス参照

このプロジェクトは統合された [dotrules](dotrules/README.md) のベストプラクティスに従って開発されています：

- [テスト戦略](dotrules/best-practices/testing-strategy-best-practices.md)
- [HonoXパターン](dotrules/best-practices/honox-best-practices.md)
- [Prismaガイドライン](dotrules/best-practices/prisma-best-practices.md)
- [開発ワークフロー](dotrules/best-practices/development-commit-strategy.md)

> 💡 dotrulesバージョン: `git -C dotrules describe --tags` で確認可能
```

### プロジェクト固有のカスタマイズ

```markdown
# CLAUDE.md

## ベストプラクティス参照

### 基本方針
統合された [dotrules](dotrules/README.md) をベースに、以下のプロジェクト固有ルールを適用：

#### テスト戦略
- [基本方針](dotrules/best-practices/testing-strategy-best-practices.md)
- プロジェクト固有の追加事項：
  - E2Eテストは週末のCI/CDで実行
  - パフォーマンステストは月次で実施

#### コミット戦略  
- [基本方針](dotrules/best-practices/development-commit-strategy.md)
- プロジェクト固有の追加事項：
  - feat: 機能追加時は必ずJira番号を記載
  - hotfix: 本番緊急対応時のみ使用
```

## 実際のプロジェクト例

### HonoX + Prisma プロジェクトでの活用

```bash
# プロジェクト初期化
mkdir ecommerce-api
cd ecommerce-api
git init

# dotrulesをsubmoduleとして統合
git submodule add https://github.com/Nkzn/dotrules.git dotrules

# プロジェクト構造を作成
mkdir -p {app,src/lib,prisma}
npm init -y

# dotrulesテンプレートを活用
cp dotrules/templates/package.json.snippets ./package-scripts-reference.md
cp dotrules/templates/tsconfig.json.template ./tsconfig.json
cp dotrules/templates/vitest.config.ts.template ./vitest.config.ts
cp dotrules/templates/vitest.integration.config.ts.template ./vitest.integration.config.ts

# CLAUDE.mdを作成
cat > CLAUDE.md << 'EOF'
# CLAUDE.md

## プロジェクト概要
ECサイト向けAPI。注文管理・在庫管理・ユーザー管理機能を提供。

## アーキテクチャ
- HonoX (フルスタック) + Prisma ORM + PostgreSQL
- 統合された dotrules ベストプラクティスに準拠

## ベストプラクティス参照
- [テスト戦略](dotrules/best-practices/testing-strategy-best-practices.md)
- [HonoXパターン](dotrules/best-practices/honox-best-practices.md)
- [Prismaガイドライン](dotrules/best-practices/prisma-best-practices.md)
- [開発ワークフロー](dotrules/best-practices/development-commit-strategy.md)

## ドメイン固有ルール
- 注文確定後の商品変更は禁止
- 在庫数は負の値を取れない
- 月次レポートは毎月1日自動生成
EOF

# 初期コミット
git add .
git commit -m "feat: プロジェクト初期化

- dotrulesをsubmoduleとして統合
- TypeScript + Vitest環境をセットアップ
- ECサイトAPI向けCLAUDE.mdを作成"
```

### 既存プロジェクトでの段階的導入

```bash
# 既存プロジェクトに移動
cd legacy-project

# 現在の状態をバックアップ
git checkout -b backup-before-dotrules

# mainブランチでdotrulesを導入
git checkout main
git submodule add https://github.com/Nkzn/dotrules.git dotrules

# 段階的にベストプラクティスを適用
# 1. まずCLAUDE.mdを作成
cp dotrules/templates/CLAUDE.md.template CLAUDE.md
sed -i 's|PATH_TO_DOTRULES|dotrules|g' CLAUDE.md

# 2. テスト設定を段階的に移行
cp dotrules/templates/vitest.config.ts.template vitest.config.new.ts
# 既存設定とマージ

# 3. TypeScript設定を確認・更新
diff tsconfig.json dotrules/templates/tsconfig.json.template || true

git add .
git commit -m "feat: dotrulesベストプラクティスを段階的に導入"
```

## トラブルシューティング

### submodule関連の問題

#### 1. submoduleが空のディレクトリになる

```bash
# 解決方法: submoduleを初期化
git submodule update --init --recursive

# または強制的に再取得
git submodule deinit dotrules
git rm dotrules
git submodule add https://github.com/Nkzn/dotrules.git dotrules
```

#### 2. submoduleの更新がチームに反映されない

```bash
# チームメンバーは以下を実行
git pull
git submodule update --recursive

# または自動化するためのgit hook設定
echo 'git submodule update --recursive' > .git/hooks/post-merge
chmod +x .git/hooks/post-merge
```

#### 3. 異なるdotrulesバージョンでのコンフリクト

```bash
# 現在のdotrulesバージョンを確認
git -C dotrules describe --tags

# チーム全体で統一するバージョンを決定
cd dotrules
git checkout v1.2.3
cd ..
git add dotrules
git commit -m "fix: dotrules v1.2.3で統一"

# プルリクエスト経由でチームに展開
```

## 高度な活用方法

### 複数環境での設定管理

```bash
# 開発環境用の設定
git -C dotrules checkout develop
git add dotrules
git commit -m "chore: dotrules開発版を使用"

# プロダクション環境用の設定
git -C dotrules checkout v1.2.3
git add dotrules  
git commit -m "chore: dotrules安定版v1.2.3を使用"
```

### カスタムdotrulesフォークの使用

```bash
# チーム独自のdotrulesフォークを使用
git submodule set-url dotrules https://github.com/team/dotrules-custom.git
git submodule update --remote

# またはfork作成時から設定
git submodule add https://github.com/team/dotrules-custom.git dotrules
```

## 運用のベストプラクティス

### 1. **定期的な更新サイクル**
```bash
# 月次でdotrulesを更新
git submodule update --remote dotrules
# レビュー後にマージ
```

### 2. **バージョン固定の判断基準**
- 開発中: 最新版を追従
- 本番リリース前: 安定版に固定
- 重要なプロジェクト: 十分にテストされたバージョンで固定

### 3. **チーム内での情報共有**
```markdown
# プロジェクトREADME.md
## dotrules管理

現在使用中のdotrulesバージョン: v1.2.3

更新手順:
1. `git submodule update --remote dotrules`
2. 変更内容を確認
3. プルリクエスト作成
4. チームレビュー後マージ
```

## まとめ

git submoduleを活用することで：

1. **統一された開発環境**: チーム全体で同じベストプラクティスを共有
2. **バージョン管理**: dotrulesのバージョンをプロジェクトと一緒に管理
3. **自動更新**: スクリプトによる効率的なセットアップと更新
4. **カスタマイズ**: プロジェクト固有のニーズに合わせた柔軟な運用

dotrulesのsubmodule統合により、AI駆動開発の品質と効率を大幅に向上させることができます。