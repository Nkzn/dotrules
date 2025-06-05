# 開発・コミット戦略ベストプラクティス

このドキュメントは、効率的で品質の高いソフトウェア開発を実現するための開発・コミット戦略をまとめたものです。

## 基本原則

1. **小さく頻繁なコミット**: 問題の特定と修正を容易にする
2. **テストと実装のセット**: 品質を保ちながら開発を進める
3. **一貫したメッセージ形式**: 変更履歴の可読性向上
4. **継続的な品質管理**: エラーを早期に発見・修正

## コミット戦略の基本原則

### 1. 小さく頻繁なコミット

```bash
# ✅ 推奨: 機能単位での小さなコミット
git add src/lib/customer-service.ts
git commit -m "feat(customer): 顧客検索機能を追加"

git add src/lib/__tests__/customer-service.test.ts
git commit -m "test(customer): 顧客検索機能のユニットテスト追加"

git add apps/web/app/routes/users.tsx
git commit -m "feat(ui): 顧客一覧画面を実装"

# ❌ 非推奨: 大きな変更を一度にコミット
git add .
git commit -m "顧客機能実装"
```

**メリット**:
- 問題発生時の切り戻しが容易
- レビューしやすい変更サイズ
- 変更履歴が分かりやすい

### 2. テストとセットでコミット

```bash
# ✅ 推奨: 実装 + テストのセット
# 1. ビジネスロジック実装
git add src/lib/price-calculator.ts
git commit -m "feat(cart): 商品価格計算ロジックを実装"

# 2. ユニットテスト追加
git add src/lib/__tests__/price-calculator.test.ts
git commit -m "test(cart): 商品価格計算のユニットテスト追加"

# 3. 統合テスト追加
git add src/lib/__tests__/price-calculator.integration.test.ts
git commit -m "test(cart): 商品価格計算の統合テスト追加"

# ❌ 非推奨: テストを後回し
git add src/lib/price-calculator.ts
git commit -m "feat(cart): 商品価格計算ロジックを実装"
# ... 他の作業を進めてしまい、テストを忘れる
```

### 3. 動作する状態でコミット

```bash
# ✅ 推奨: 各コミット時点でビルド・テストが通る
npm run build  # ビルド成功を確認
npm test       # テスト成功を確認
git commit -m "feat(api): 新しいエンドポイントを追加"

# ❌ 非推奨: 壊れた状態でコミット
git commit -m "wip: とりあえず途中までの変更をコミット"
# -> 他の開発者がこのコミットをpullするとビルドエラーになる
```

## コミットメッセージの統一

### Conventional Commitsベースの形式

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### 基本的なタイプ

```bash
# 新機能追加
feat(customer): 顧客登録機能を実装

# バグ修正
fix(auth): ログイン時のセッション有効期限を修正

# テスト追加
test(cart): 支払処理の統合テスト追加

# リファクタリング
refactor(database): データベース接続処理を整理

# ドキュメント更新
docs(api): REST API仕様書を更新

# スタイル修正（機能に影響なし）
style(ui): コードフォーマットを統一

# パフォーマンス改善
perf(query): データベースクエリを最適化

# ビルド・設定変更
build(deps): Prismaを6.9.0にアップデート

# CI/CD関連
ci(github): テストワークフローを追加
```

### スコープの例

```bash
# 機能別スコープ
feat(auth): ログイン機能
feat(customer): 顧客管理
feat(cart): 支払処理
feat(order): 注文管理

# 技術別スコープ
feat(api): REST API
feat(ui): 顧客インターフェース
feat(db): データベース
feat(config): 設定

# ファイル別スコープ
feat(customer-service): 顧客サービス
test(order-api): 注文APIテスト
```

### 具体的な例

```bash
# 良い例: 具体的で分かりやすい
feat(order): 注文検索にステータスフィルター機能を追加
fix(cart): 商品価格計算時の消費税計算エラーを修正
test(customer): 顧客削除機能の統合テスト追加
refactor(auth): JWT認証ロジックをサービスクラスに分離

# 悪い例: 曖昧で情報不足
feat: 機能追加
fix: バグ修正
update: 更新
improve: 改善
```

## WIP (Work In Progress) の活用

### 作業の中断・再開時

```bash
# 作業途中でコミット
git add .
git commit -m "wip(cart): ショッピングカート生成機能の実装を開始"

# 後で適切なコミットメッセージに修正
git commit --amend -m "feat(cart): ショッピングカート生成の基本ロジックを実装"
```

### 実験的な実装

```bash
# 実験的な実装をコミット
git commit -m "wip(experiment): 新しいアーキテクチャパターンを試行"

# 成功した場合
git commit --amend -m "refactor(architecture): サービス層をDIパターンに変更"

# 失敗した場合
git reset HEAD~1  # コミットを取り消し
```

## エラー対応の記録

### 問題解決過程の記録

```bash
# エラー発生を記録
git commit -m "fix(build): TypeScriptコンパイルエラーに対応

- Customer型の定義が重複していた問題を解決
- src/types/customer.tsとsrc/models/customer.tsの型定義を統合
- 影響範囲: 顧客関連の全コンポーネント

Closes #123"

# パフォーマンス問題の解決
git commit -m "perf(query): 注文一覧取得の性能を改善

- N+1問題を解決するためincludeクエリを最適化
- 実行時間を2000ms→200msに短縮
- 大量データ(10,000件)での動作確認済み"
```

### エラーログとスタックトレースの記録

```bash
git commit -m "fix(api): ショッピングカートAPI実行時の500エラーを修正

エラー内容:
PrismaClientKnownRequestError: 
Foreign key constraint failed on the field: supplierId

原因:
削除されたサプライヤーを参照するショッピングカートを作成しようとしていた

解決方法:
- サプライヤー存在チェックを事前に実行
- 不正なサプライヤーIDの場合は400エラーを返却"
```

## コミットタイミングの具体例

### データベース関連の開発

```bash
# 1. マイグレーションファイル作成
git add prisma/migrations/
git commit -m "feat(db): ShoppingCartテーブルを追加"

# 2. Prismaスキーマ更新
git add prisma/schema.prisma
git commit -m "feat(db): ShoppingCartモデル定義を追加"

# 3. 型生成
npm run prisma:generate
git add src/__generated__/
git commit -m "build(prisma): ShoppingCart型を生成"
```

### 機能実装の段階的コミット

```bash
# 1. サービスクラスの基本構造
git add src/lib/shopping-cart-service.ts
git commit -m "feat(cart): ShoppingCartServiceの基本構造を作成"

# 2. 作成機能の実装
git add src/lib/shopping-cart-service.ts
git commit -m "feat(cart): ショッピングカート作成機能を実装"

# 3. 検索機能の実装
git add src/lib/shopping-cart-service.ts
git commit -m "feat(cart): ショッピングカート検索機能を実装"

# 4. バリデーション追加
git add src/lib/shopping-cart-service.ts
git commit -m "feat(cart): ショッピングカートデータのバリデーションを追加"

# 5. エラーハンドリング追加
git add src/lib/shopping-cart-service.ts
git commit -m "feat(cart): ショッピングカート処理のエラーハンドリングを強化"
```

### テスト実装の段階的コミット

```bash
# 1. ユニットテストファイル作成
git add src/lib/__tests__/shopping-cart-service.test.ts
git commit -m "test(cart): ShoppingCartServiceのテストファイル作成"

# 2. 基本的なテストケース追加
git add src/lib/__tests__/shopping-cart-service.test.ts
git commit -m "test(cart): ショッピングカート作成機能のユニットテスト追加"

# 3. エラーケースのテスト追加
git add src/lib/__tests__/shopping-cart-service.test.ts
git commit -m "test(cart): ショッピングカート作成時のエラーハンドリングテスト追加"

# 4. 統合テスト追加
git add src/lib/__tests__/shopping-cart-service.integration.test.ts
git commit -m "test(cart): ショッピングカート機能の統合テスト追加"
```

### UI/API実装の段階的コミット

```bash
# 1. APIルート定義
git add apps/web/app/routes/api.ts
git commit -m "feat(api): ショッピングカートAPIエンドポイントを追加"

# 2. フロントエンド画面作成
git add apps/web/app/routes/shopping-carts.tsx
git commit -m "feat(ui): ショッピングカート一覧画面を実装"

# 3. 詳細画面作成
git add apps/web/app/routes/shopping-carts/[id].tsx
git commit -m "feat(ui): ショッピングカート詳細画面を実装"

# 4. 検索フォーム追加
git add apps/web/app/islands/shopping-cart-search-form.tsx
git commit -m "feat(ui): ショッピングカート検索フォームを実装"
```

## 品質管理の自動化

### プリコミットフック

```bash
# .pre-commit-config.yaml や package.json scripts での自動チェック

# TypeScriptコンパイルチェック
npm run typecheck

# リンターチェック
npm run lint

# テスト実行
npm run test

# フォーマット自動修正
npm run format

# 全チェック通過後にコミット実行
git commit -m "feat(customer): 顧客管理機能を追加"
```

### CI/CDでの品質チェック

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run typecheck
      
      - name: Lint
        run: npm run lint
      
      - name: Unit tests
        run: npm run test:run
      
      - name: Integration tests
        run: npm run test:integration
```

## ブランチ戦略

### Feature Branch Workflow

```bash
# 1. メインブランチから新機能ブランチを作成
git checkout main
git pull origin main
git checkout -b feature/shopping-cart

# 2. 機能開発（小さく頻繁なコミット）
git commit -m "feat(cart): ShoppingCartモデルを追加"
git commit -m "test(cart): ShoppingCartのユニットテスト追加"
git commit -m "feat(api): ショッピングカートAPIエンドポイントを実装"

# 3. プルリクエスト作成前の最終チェック
npm run test:run && npm run test:integration
npm run lint
npm run typecheck

# 4. リモートブランチにプッシュ
git push origin feature/shopping-cart

# 5. プルリクエスト作成
gh pr create --title "ショッピングカート機能の実装" --body "..."
```

## まとめ

この開発・コミット戦略により、以下を実現できます：

1. **高い開発効率**: 小さく頻繁なコミットによる問題の早期発見
2. **優れたコード品質**: テストとセットでの開発による品質保証
3. **明確な変更履歴**: 一貫したコミットメッセージによる可読性向上
4. **チーム協調**: 標準化されたワークフローによる円滑な協業
5. **継続的改善**: エラー対応記録による知識蓄積と再発防止

計画的で品質の高いソフトウェア開発を継続的に実現できます。