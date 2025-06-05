# テスト戦略ベストプラクティス

このドキュメントは、Vitest + Prisma + HonoXプロジェクトにおけるテスト戦略のベストプラクティスをまとめたものです。

## 概要

**ユニットテスト**と**統合テスト**を明確に分離した二層テスト戦略を採用し、高速で安定したテスト環境を構築します。

## テスト戦略の三層構造

### 1. ユニットテスト (`*.test.ts`)
- **目的**: ビジネスロジック、エラーハンドリング、データ検証
- **特徴**: 高速実行（~4ms）、外部依存なし、**DB操作なし**
- **モック**: 外部APIクライアントのみ、Prismaは空オブジェクト
- **実行**: `pnpm test:run`
- **対象**:
  - 外部APIデータの変換・検証ロジック
  - APIエラーハンドリング
  - データバリデーション
  - エラー回復処理
  - エッジケース処理

### 2. 統合テスト (`*.integration.test.ts`)
- **目的**: 実際のDB操作、データ整合性、E2E動作
- **特徴**: 実際のPrisma使用、実DB接続、トランザクション分離
- **技術**: `vitest-environment-vprisma`による自動ロールバック
- **実行**: `pnpm test:integration`
- **対象**:
  - CRUD操作の完全動作
  - DB制約の検証
  - 外部API同期の実際の動作
  - データの永続化確認

### 3. REST APIテスト (`*.api.test.ts`)
- **目的**: HTTPエンドポイントの動作検証、レスポンス形式確認
- **技術**: Honoの`app.request()`メソッドによるリクエストシミュレーション
- **特徴**: 実際のHTTPリクエスト/レスポンスサイクルをテスト
- **実行**: 統合テストと同じコマンド（`pnpm test:integration`）

## テストファイルの命名規則と責任分離

```
src/lib/__tests__/
├── service.test.ts              # ユニットテスト（ビジネスロジック特化）
├── service.integration.test.ts  # 統合テスト（DB操作・実際の動作）
└── service.api.test.ts          # APIテスト（HTTPエンドポイント）
```

## テスト作成ガイドライン

- **ユニットテスト**: DB操作を含まず、純粋なロジックのみテスト
- **統合テスト**: 実際のPrisma・DB制約・データ永続化をテスト
- **モック戦略**: ユニットテストではPrismaを空オブジェクト、統合テストでは外部APIのみモック
- **速度重視**: ユニットテスト4ms、統合テスト170ms程度を目安

## 統合テスト安定化の必須パターン

vitest-environment-vprismaを使用する統合テストでは、以下のパターンを**必ず適用**してください：

### 1. 動的ID生成（必須）
```typescript
// ✅ 必須: 完全ユニークなID生成
const externalId = `test-${modelName}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

// ❌ 禁止: 固定値（重複エラーの原因）
const externalId = '1';
```

### 2. beforeEach明示的クリーンアップ（必須）
```typescript
beforeEach(async () => {
  // 外部キー制約の順序で削除
  await globalThis.vPrisma.client.childProduct.deleteMany({});
  await globalThis.vPrisma.client.parentProduct.deleteMany({});
  
  service = new ServiceClass(undefined, globalThis.vPrisma.client);
  vi.clearAllMocks();
});
```

### 3. 外部キー制約対応
外部キー関係のあるモデルは必ず親オブジェクトを先に作成：
```typescript
// ✅ 正しい順序
const parent = await prisma.parentProduct.create({...});
const child = await prisma.childProduct.create({
  data: { parentId: parent.id, ... }
});
```

## Prisma Fabbrica（テストファクトリー）

統合テストでは[Prisma Fabbrica](https://github.com/Quramy/prisma-fabbrica)を使用してテストデータを生成します。

### 基本的な使用方法

```typescript
import { initialize, defineProductFactory } from '../../__generated__/fabbrica/index.js';

// テストファイルの初期化
initialize({
  prisma: () => globalThis.vPrisma.client,
});

// ファクトリー定義
const ProductFactory = defineProductFactory();

// テスト内でのデータ作成
const model = await ProductFactory.create(); // デフォルト値で作成
const customProduct = await ProductFactory.create({
  code: 'CUSTOM001',
  name: 'カスタムモデル',
}); // カスタム値で作成

// 複数のデータを一度に作成
const products = await ProductFactory.createList(3);
```

### Fabbricaの利点
- **型安全**: Prismaスキーマから自動生成される型安全なファクトリー
- **簡潔**: 手動データ作成のボイラープレートを削減
- **一貫性**: 全モデルで統一されたテストデータ生成パターン
- **保守性**: モデル変更時の自動追従

### ファクトリー生成
Prismaスキーマ変更後に以下を実行してファクトリーを再生成：
```bash
pnpm prisma:generate
```

### 外部キー関係の制限
- **シンプルなモデル**: Fabbrica使用 ✅（外部キーなし）
- **複雑な関係モデル**: 手動作成 ✅（外部キー制限対応）
- **教訓**: 外部キー関係が複雑なモデルは手動Prisma作成が安全

## REST APIテストの基本パターン

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import app from '../index.js'; // Honoアプリケーション

describe('API Endpoints', () => {
  it('GET /api/products - should return products list', async () => {
    const res = await app.request('/api/products');
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toContain('application/json');
    
    const products = await res.json();
    expect(Array.isArray(products)).toBe(true);
  });

  it('POST /api/products - should create new model', async () => {
    const modelData = {
      code: 'MODEL001',
      name: 'Test Product',
      value: 100
    };

    const res = await app.request('/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(modelData)
    });

    expect(res.status).toBe(201);
    const created = await res.json();
    expect(created.code).toBe('MODEL001');
  });

  it('GET /api/products/:id - should return specific model', async () => {
    const res = await app.request('/api/products/1');
    expect(res.status).toBe(200);
    
    const model = await res.json();
    expect(model.id).toBe(1);
  });

  it('PUT /api/products/:id - should update model', async () => {
    const updateData = { name: 'Updated Product' };
    
    const res = await app.request('/api/products/1', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updateData)
    });

    expect(res.status).toBe(200);
    const updated = await res.json();
    expect(updated.name).toBe('Updated Product');
  });

  it('DELETE /api/products/:id - should delete model', async () => {
    const res = await app.request('/api/products/1', {
      method: 'DELETE'
    });
    expect(res.status).toBe(204);
  });
});
```

## APIテストの重要なポイント

1. **レスポンス検証**:
   - ステータスコード確認
   - Content-Typeヘッダー確認
   - レスポンスボディの構造検証

2. **エラーハンドリングテスト**:
   - 不正なリクエストデータ
   - 存在しないリソースへのアクセス
   - 認証エラー

3. **データベース状態確認**:
   - CUD操作後のデータベース状態検証
   - 関連データの整合性確認

## APIテストの依存性注入パターン

APIテストでは本番コードを直接テストし、テスト専用の重複実装を排除します：

```typescript
import { createApiApp } from '../app/routes/api.js';
import { ProductService } from '../src/lib/index.js';

export function createTestApp() {
  const app = new Hono()
  const prismaClient = globalThis.vPrisma?.client || {}
  
  // 本番と同じサービスインスタンスを作成（Prismaのみテスト用）
  const productService = new ProductService(undefined, prismaClient)
  
  // 本番APIコードを依存性注入で使用
  const apiApp = createApiApp({
    productService,
    // ...他のサービス
  })
  
  app.route('/api', apiApp)
  return app
}
```

## 自動生成機能のテスト戦略

複数のサービス間で連携する自動生成機能のテストでは、以下のパターンを適用：

### 1. 機能別統合テストファイル作成
```
src/lib/__tests__/
├── model.test.ts                    # ユニットテスト
├── model.integration.test.ts        # 統合テスト
└── auto-generation.integration.test.ts  # 自動生成機能専用
```

### 2. エンドツーエンド統合テスト
```typescript
it('should generate sources and auto-create related data', async () => {
  // 1. テストデータ準備
  const source = await createTestSource();
  
  // 2. 主機能実行
  const result = await service.generateSources('target-key');
  
  // 3. 主機能結果検証
  expect(result.generatedCount).toBe(1);
  
  // 4. 自動生成機能結果検証
  expect(result.relatedData.created).toBe(1);
  
  // 5. データベース状態検証
  const relatedData = await prisma.relatedProduct.findMany({...});
  expect(relatedData).toHaveLength(1);
  
  // 6. 関連データ整合性検証
  const sources = await prisma.sourceProduct.findMany({...});
  expect(sources[0].relatedId).toBe(relatedData[0].id);
});
```

### 3. エラー伝播テスト
自動生成でエラーが発生した場合の主機能への影響を検証：
```typescript
it('should handle auto-generation errors gracefully', async () => {
  // 自動生成機能をモックしてエラーを発生させる
  const mockError = vi.fn().mockRejectedValue(new Error('Mock error'));
  service['relatedService'] = { generateRelatedData: mockError };
  
  const result = await service.generateSources('target-key');
  
  // 主機能は成功、自動生成エラーはエラー配列に記録
  expect(result.generatedCount).toBe(1);
  expect(result.errors).toContain('Related data generation failed: Error: Mock error');
});
```

## まとめ

この三層テスト戦略により：

1. **ユニットテスト**: ビジネスロジック（~4ms）
2. **統合テスト**: データベース操作（~170ms）
3. **APIテスト**: HTTPエンドポイント（~200ms）

全てのテストでVitestを使用し、一貫したテスト体験と高い品質を実現できます。