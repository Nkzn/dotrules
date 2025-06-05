# HonoXベストプラクティス

このドキュメントは、HonoXを使用したフルスタックWebアプリケーション開発のベストプラクティスをまとめたものです。

## 基本原則

HonoXでは以下の原則を重視した開発を行います：

1. **Web標準準拠**: JavaScriptに依存しすぎず、HTML標準の動作を活用
2. **プログレッシブエンハンスメント**: JavaScriptが無効でも基本機能が動作
3. **最小限のJavaScript**: 必要最低限の状態管理とイベントハンドリング
4. **URL状態管理**: フォーム送信やリンク遷移でURL状態を管理

## Web標準準拠アプローチ

### 検索フォーム実装

```tsx
// ✅ 推奨: HTML標準のGETフォーム
<form method="get" class="flex gap-2">
  <input type="text" name="search" defaultValue={defaultValue} />
  <button type="submit">検索</button>
</form>

// ❌ 非推奨: JavaScript依存のアプローチ
<form onSubmit={handleSubmit}>
  <input value={searchTerm} onInput={setSearchTerm} />
  <button onClick={() => navigateWithJS()}>検索</button>
</form>
```

**理由**: HTML標準のGETフォームを使用することで、JavaScriptが無効でも検索機能が動作し、URLの共有も可能になります。

### ページネーション実装

```tsx
// ✅ 推奨: 標準リンクベース
<a href={createPageUrl(page)} class="pagination-link">
  {page}
</a>

// ❌ 非推奨: JavaScript onClick
<button onClick={() => handlePageChange(page)}>
  {page}
</button>
```

**理由**: 標準リンクを使用することで、右クリック→新しいタブで開く、ブックマーク、戻るボタンなどの基本的なブラウザ機能が正常に動作します。

## Islandコンポーネント設計原則

Islandコンポーネントは以下の原則に従って設計します：

### 1. 最小限のJavaScript
```tsx
// ✅ 推奨: 必要最低限のJavaScript
export default function SyncButton() {
  const [isLoading, setIsLoading] = useState(false);
  
  const handleSync = async () => {
    setIsLoading(true);
    try {
      await fetch('/api/sync', { method: 'POST' });
      window.location.reload(); // シンプルなページリロード
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <button onClick={handleSync} disabled={isLoading}>
      {isLoading ? '同期中...' : '同期'}
    </button>
  );
}
```

### 2. Web標準優先
```tsx
// ✅ 推奨: HTML標準の動作を活用
export default function SearchForm({ defaultValue }: { defaultValue?: string }) {
  return (
    <form method="get" class="search-form">
      <input 
        type="text" 
        name="search" 
        defaultValue={defaultValue}
        placeholder="検索キーワード"
      />
      <button type="submit">検索</button>
    </form>
  );
}

// JavaScript拡張が必要な場合のみIslandコンポーネント化
export default function EnhancedSearchForm({ defaultValue }: { defaultValue?: string }) {
  const [value, setValue] = useState(defaultValue || '');
  
  return (
    <form method="get" class="search-form">
      <input 
        type="text" 
        name="search" 
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder="検索キーワード"
      />
      <button type="submit">検索</button>
      {/* JavaScript拡張機能 */}
      {value && (
        <button type="button" onClick={() => setValue('')}>
          クリア
        </button>
      )}
    </form>
  );
}
```

### 3. プログレッシブエンハンスメント
```tsx
// ✅ 推奨: JavaScript無効でも基本機能が動作
export default function CartItemsManager() {
  const [selectedMonth, setSelectedMonth] = useState('');
  
  return (
    <div>
      {/* 基本機能: フォーム送信でサーバー処理 */}
      <form method="post" action="/api/cart-items/generate">
        <select name="month" onChange={(e) => setSelectedMonth(e.target.value)}>
          <option value="">月を選択</option>
          <option value="2025-01">2025年1月</option>
          <option value="2025-02">2025年2月</option>
        </select>
        <button type="submit">生成</button>
      </form>
      
      {/* JavaScript拡張: プレビュー機能 */}
      {selectedMonth && (
        <div class="preview">
          選択された月: {selectedMonth}
        </div>
      )}
    </div>
  );
}
```

## APIクエリパラメータ設計

サービス層でページネーション・検索に対応した統一的なAPI設計を行います：

```typescript
// サービス層での統一パターン
interface PaginationOptions {
  page?: number;
  limit?: number;
  search?: string;
}

interface PaginatedResponse<T> {
  data: T[];
  totalCount: number;
  page: number;
  limit: number;
  totalPages: number;
}

async getProductsWithPagination(options: PaginationOptions = {}): Promise<PaginatedResponse<Product>> {
  // 安全な値の正規化
  const page = Math.max(1, options.page || 1);
  const limit = Math.min(100, Math.max(1, options.limit || 10));
  const skip = (page - 1) * limit;

  // 検索条件の構築
  const where: any = {};
  if (options.search) {
    where.OR = [
      { code: { contains: options.search, mode: 'insensitive' } },
      { name: { contains: options.search, mode: 'insensitive' } }
    ];
  }

  // 並列実行でパフォーマンス向上
  const [data, totalCount] = await Promise.all([
    this.prisma.model.findMany({ where, skip, take: limit }),
    this.prisma.model.count({ where })
  ]);

  return {
    data,
    totalCount,
    page,
    limit,
    totalPages: Math.ceil(totalCount / limit)
  };
}
```

## ルート設計パターン

### 1. リソースベースのルート構造
```
app/routes/
├── index.tsx              # トップページ
├── products.tsx             # モデル一覧
├── products/
│   └── [id].tsx          # モデル詳細
├── api.ts                # API統合エンドポイント
└── _renderer.tsx         # レイアウト
```

### 2. API統合エンドポイント
```typescript
// app/routes/api.ts - 全APIエンドポイントを統合
import { Hono } from 'hono';

const app = new Hono();

// RESTful APIパターン
app.get('/products', async (c) => {
  const page = Number(c.req.query('page')) || 1;
  const search = c.req.query('search') || '';
  
  const result = await productService.getProductsWithPagination({ page, search });
  return c.json(result);
});

app.post('/products', async (c) => {
  const data = await c.req.json();
  const model = await productService.createProduct(data);
  return c.json(model, 201);
});

app.get('/products/:id', async (c) => {
  const id = Number(c.req.param('id'));
  const model = await productService.getProductById(id);
  return c.json(model);
});

app.put('/products/:id', async (c) => {
  const id = Number(c.req.param('id'));
  const data = await c.req.json();
  const model = await productService.updateProduct(id, data);
  return c.json(model);
});

app.delete('/products/:id', async (c) => {
  const id = Number(c.req.param('id'));
  await productService.deleteProduct(id);
  return c.body(null, 204);
});

export default app;
```

## UIコンポーネント統一パターン

### 1. 検索フォーム（単一フィールド）
```tsx
// app/islands/search-form.tsx - 再利用可能な検索コンポーネント
interface SearchFormProps {
  placeholder?: string;
  defaultValue?: string;
  className?: string;
}

export default function SearchForm({ 
  placeholder = "検索キーワード", 
  defaultValue = "",
  className = "flex gap-2"
}: SearchFormProps) {
  return (
    <form method="get" class={className}>
      <input 
        type="text" 
        name="search" 
        defaultValue={defaultValue}
        placeholder={placeholder}
        class="border border-gray-300 rounded px-3 py-2"
      />
      <button 
        type="submit"
        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
      >
        検索
      </button>
    </form>
  );
}
```

### 2. 複合検索フォーム（複数フィールド）
```tsx
// app/islands/advanced-search-form.tsx - 専用の複合検索コンポーネント
interface AdvancedSearchFormProps {
  defaultValues?: {
    search?: string;
    category?: string;
    status?: string;
  };
}

export default function AdvancedSearchForm({ defaultValues = {} }: AdvancedSearchFormProps) {
  return (
    <form method="get" class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <input 
        type="text" 
        name="search" 
        defaultValue={defaultValues.search}
        placeholder="キーワード検索"
        class="border border-gray-300 rounded px-3 py-2"
      />
      <select 
        name="category" 
        defaultValue={defaultValues.category}
        class="border border-gray-300 rounded px-3 py-2"
      >
        <option value="">カテゴリー選択</option>
        <option value="A">カテゴリーA</option>
        <option value="B">カテゴリーB</option>
      </select>
      <select 
        name="status" 
        defaultValue={defaultValues.status}
        class="border border-gray-300 rounded px-3 py-2"
      >
        <option value="">ステータス選択</option>
        <option value="active">有効</option>
        <option value="inactive">無効</option>
      </select>
      <button 
        type="submit"
        class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 md:col-span-3"
      >
        検索
      </button>
    </form>
  );
}
```

### 3. ページネーション
```tsx
// app/islands/pagination.tsx - URLSearchParams対応のページネーション
interface PaginationProps {
  currentPage: number;
  totalPages: number;
  baseUrl: string;
  searchParams?: URLSearchParams;
}

export default function Pagination({ 
  currentPage, 
  totalPages, 
  baseUrl,
  searchParams = new URLSearchParams()
}: PaginationProps) {
  const createPageUrl = (page: number) => {
    const params = new URLSearchParams(searchParams);
    params.set('page', page.toString());
    return `${baseUrl}?${params.toString()}`;
  };

  return (
    <nav class="flex justify-center gap-2">
      {/* 前のページ */}
      {currentPage > 1 && (
        <a 
          href={createPageUrl(currentPage - 1)}
          class="px-3 py-2 border border-gray-300 rounded hover:bg-gray-100"
        >
          前へ
        </a>
      )}

      {/* ページ番号 */}
      {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
        <a
          key={page}
          href={createPageUrl(page)}
          class={`px-3 py-2 border rounded ${
            page === currentPage 
              ? 'bg-blue-500 text-white border-blue-500' 
              : 'border-gray-300 hover:bg-gray-100'
          }`}
        >
          {page}
        </a>
      ))}

      {/* 次のページ */}
      {currentPage < totalPages && (
        <a 
          href={createPageUrl(currentPage + 1)}
          class="px-3 py-2 border border-gray-300 rounded hover:bg-gray-100"
        >
          次へ
        </a>
      )}
    </nav>
  );
}
```

## パフォーマンス最適化

### 1. 並列データ取得
```typescript
// ✅ 推奨: Promise.allで並列実行
async getPageData(page: number, search: string) {
  const [products, categories, statistics] = await Promise.all([
    this.getProductsWithPagination({ page, search }),
    this.getCategories(),
    this.getStatistics()
  ]);

  return { products, categories, statistics };
}

// ❌ 非推奨: 順次実行
async getPageData(page: number, search: string) {
  const products = await this.getProductsWithPagination({ page, search });
  const categories = await this.getCategories();
  const statistics = await this.getStatistics();

  return { products, categories, statistics };
}
```

### 2. レスポンスキャッシュ
```typescript
// 適切なHTTPヘッダーでキャッシュ制御
app.get('/api/categories', async (c) => {
  const categories = await categoryService.getCategories();
  
  // 5分間キャッシュ
  c.header('Cache-Control', 'public, max-age=300');
  
  return c.json(categories);
});
```

## エラーハンドリング

### 1. 統一されたエラーレスポンス
```typescript
interface ApiError {
  message: string;
  code?: string;
  details?: any;
}

app.onError((err, c) => {
  console.error(err);
  
  const error: ApiError = {
    message: err.message || 'Internal Server Error'
  };

  return c.json({ error }, 500);
});
```

### 2. バリデーションエラー
```typescript
app.post('/api/products', async (c) => {
  try {
    const data = await c.req.json();
    
    // バリデーション
    if (!data.name) {
      return c.json({ 
        error: { message: 'Name is required', code: 'VALIDATION_ERROR' } 
      }, 400);
    }

    const model = await productService.createProduct(data);
    return c.json(model, 201);
  } catch (error) {
    return c.json({ 
      error: { message: 'Failed to create model' } 
    }, 500);
  }
});
```

## セキュリティベストプラクティス

### 1. 入力値のサニタイズ
```typescript
// クエリパラメータの安全な処理
const page = Math.max(1, Math.min(1000, Number(c.req.query('page')) || 1));
const limit = Math.max(1, Math.min(100, Number(c.req.query('limit')) || 10));
const search = c.req.query('search')?.slice(0, 100) || ''; // 長さ制限
```

### 2. SQLインジェクション対策
```typescript
// ✅ 推奨: Prismaの型安全なクエリ
const products = await prisma.model.findMany({
  where: {
    name: { contains: search, mode: 'insensitive' }
  }
});

// ❌ 禁止: 生のSQL文字列結合
const products = await prisma.$queryRaw`
  SELECT * FROM model WHERE name LIKE '%${search}%'
`;
```

## まとめ

これらのベストプラクティスにより、以下を実現できます：

1. **Web標準準拠**: ブラウザの基本機能が正常に動作
2. **高いパフォーマンス**: 最小限のJavaScriptと効率的なデータ取得
3. **優れたUX**: プログレッシブエンハンスメントによる段階的機能向上
4. **保守性**: 一貫したパターンと再利用可能なコンポーネント
5. **セキュリティ**: 適切な入力値検証とサニタイズ

HonoXの特性を活かした、モダンで安全なWebアプリケーションを構築できます。