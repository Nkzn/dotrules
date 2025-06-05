# Prismaベストプラクティス

このドキュメントは、Prisma ORMを使用したデータベース設計・運用のベストプラクティスをまとめたものです。

## 基本原則

1. **型安全性**: Prismaの型システムを最大限活用
2. **一貫性**: 命名規則とパターンの統一
3. **パフォーマンス**: 効率的なクエリとリレーション設計
4. **保守性**: 明示的な制約名と分かりやすいスキーマ構造

## スキーマ設計ベストプラクティス

### 1. ユニーク制約の命名と参照

Prismaスキーマでユニーク制約を定義する際は、明示的な名前を付けて一貫性を保つ：

```prisma
model ShoppingCart {
  id        Int    @id @default(autoincrement())
  yearMonth String
  supplierId  Int
  supplier    Supplier @relation(fields: [supplierId], references: [id])
  
  // ✅ 推奨: 明示的な制約名
  @@unique([yearMonth, supplierId], name: "unique_year_month_supplier")
}

model UserProfile {
  id     Int    @id @default(autoincrement())
  userId Int
  email  String
  
  // ✅ 推奨: 意味のある制約名
  @@unique([userId], name: "unique_user_profile")
  @@unique([email], name: "unique_profile_email")
}
```

コードでの参照時は、スキーマで定義した名前と一致させる：

```typescript
// ✅ 正しい: スキーマの制約名と一致
const cart = await prisma.shoppingCart.findUnique({
  where: {
    unique_year_month_supplier: { yearMonth: "2025-06", supplierId: 1 }
  }
});

// ❌ 間違い: 自動生成される名前を推測
const cart = await prisma.shoppingCart.findUnique({
  where: {
    yearMonth_supplierId: { yearMonth: "2025-06", supplierId: 1 }
  }
});
```

### 2. リレーション設計

```prisma
model Supplier {
  id           Int            @id @default(autoincrement())
  code         String         @unique
  name         String
  
  // 一対多のリレーション
  orders       Order[]
  shoppingCarts ShoppingCart[]
  
  @@map("suppliers") // テーブル名の明示的マッピング
}

model Order {
  id          Int      @id @default(autoincrement())
  orderCode   String   @unique
  title       String
  orderAmount Int
  orderDate   DateTime
  
  // 外部キー
  supplierId    Int
  customerId   Int
  
  // リレーション定義
  supplier      Supplier   @relation(fields: [supplierId], references: [id])
  customer     Customer  @relation(fields: [customerId], references: [id])
  
  // 複合インデックス
  @@index([supplierId, orderDate], name: "idx_supplier_order_date")
  @@map("orders")
}
```

### 3. 適切なデータ型の選択

```prisma
model Product {
  id          Int      @id @default(autoincrement())
  
  // 文字列フィールド
  code        String   @db.VarChar(50)  // 長さ制限を明示
  name        String   @db.VarChar(255)
  description String?  @db.Text         // 長いテキスト用
  
  // 数値フィールド
  price       Int                       // 金額は整数（円単位）
  weight      Decimal  @db.Decimal(10, 2) // 重量は小数点2桁
  
  // 日付フィールド
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  
  // 列挙型
  status      Status   @default(ACTIVE)
  
  @@map("products")
}

enum Status {
  ACTIVE
  INACTIVE
  ARCHIVED
}
```

## クエリベストプラクティス

### 1. 外部キー制約と削除順序

関連データの削除では、外部キー制約を考慮した順序で実行する：

```typescript
// ✅ 正しい削除順序
async deleteCartItems(targetMonth: string): Promise<number> {
  // 1. 子テーブル（外部キーを持つ側）を先に削除
  const result = await this.prisma.orderItem.deleteMany({
    where: { targetMonth }
  });
  
  // 2. 親テーブル（参照される側）を後から削除
  await this.shoppingCartService.deleteCartsByMonth(targetMonth);
  
  return result.count;
}

// ❌ 間違った順序: 外部キー制約エラーが発生
async deleteCartItemsWrong(targetMonth: string): Promise<number> {
  // 親テーブルを先に削除しようとするとエラー
  await this.shoppingCartService.deleteCartsByMonth(targetMonth);
  
  const result = await this.prisma.orderItem.deleteMany({
    where: { targetMonth }
  });
  
  return result.count;
}
```

### 2. 効率的なリレーション取得

```typescript
// ✅ 推奨: includeで必要なリレーションのみ取得
async getOrderWithDetails(orderId: number) {
  return await this.prisma.order.findUnique({
    where: { id: orderId },
    include: {
      supplier: true,
      customer: true,
      // 不要なリレーションは含めない
    }
  });
}

// ✅ 推奨: selectで必要なフィールドのみ取得
async getOrderSummary(orderId: number) {
  return await this.prisma.order.findUnique({
    where: { id: orderId },
    select: {
      id: true,
      orderCode: true,
      title: true,
      orderAmount: true,
      supplier: {
        select: {
          name: true,
          code: true
        }
      }
    }
  });
}

// ❌ 非推奨: 不要なデータまで取得
async getOrderInefficient(orderId: number) {
  return await this.prisma.order.findUnique({
    where: { id: orderId },
    include: {
      supplier: true,
      customer: true,
      orderItems: true, // 不要なリレーション
      // 他の重いリレーション...
    }
  });
}
```

### 3. バッチ処理の最適化

```typescript
// ✅ 推奨: createManyで一括挿入
async createMultipleRecords(records: CreateRecordData[]) {
  return await this.prisma.record.createMany({
    data: records,
    skipDuplicates: true // 重複をスキップ
  });
}

// ✅ 推奨: トランザクションで一貫性を保つ
async transferData(sourceId: number, targetId: number, amount: number) {
  return await this.prisma.$transaction([
    this.prisma.account.update({
      where: { id: sourceId },
      data: { balance: { decrement: amount } }
    }),
    this.prisma.account.update({
      where: { id: targetId },
      data: { balance: { increment: amount } }
    })
  ]);
}

// ❌ 非推奨: ループでの個別作成
async createMultipleRecordsInefficient(records: CreateRecordData[]) {
  const results = [];
  for (const record of records) {
    const created = await this.prisma.record.create({ data: record });
    results.push(created);
  }
  return results;
}
```

### 4. ページネーションとソート

```typescript
// ✅ 推奨: カーソルベースページネーション（大量データ用）
async getRecordsCursor(cursor?: number, limit: number = 20) {
  return await this.prisma.record.findMany({
    take: limit,
    skip: cursor ? 1 : 0,
    cursor: cursor ? { id: cursor } : undefined,
    orderBy: { id: 'asc' }
  });
}

// ✅ 推奨: オフセットベースページネーション（小〜中量データ用）
async getRecordsOffset(page: number = 1, limit: number = 20) {
  const skip = (page - 1) * limit;
  
  const [records, totalCount] = await Promise.all([
    this.prisma.record.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    }),
    this.prisma.record.count()
  ]);

  return {
    records,
    totalCount,
    page,
    totalPages: Math.ceil(totalCount / limit)
  };
}
```

## 依存性注入とテスト対応

### 1. 統一インスタンス管理

サービス間でPrismaクライアントを共有する場合は、コンストラクタで注入する：

```typescript
export class CartItemService {
  private prisma: PrismaClient;
  private shoppingCartService: ShoppingCartService;

  constructor(prismaClient?: PrismaClient) {
    this.prisma = prismaClient || new PrismaClient();
    // 同じPrismaインスタンスを共有
    this.shoppingCartService = new ShoppingCartService(this.prisma);
  }

  async generateCartItems(targetMonth: string) {
    // トランザクション内で複数サービスを協調
    return await this.prisma.$transaction(async (tx) => {
      // 主処理
      const items = await this.createCartItems(tx, targetMonth);
      
      // 関連処理
      const carts = await this.shoppingCartService.generateFromItems(tx, items);
      
      return { items, carts };
    });
  }

  private async createCartItems(tx: PrismaTransactionClient, targetMonth: string) {
    // トランザクション内での処理
    return await tx.orderItem.createMany({
      data: await this.buildCartItemData(targetMonth)
    });
  }
}
```

### 2. テスト用のモック対応

```typescript
// テスト用のサービス作成
export class TestableService {
  constructor(
    private prisma: PrismaClient,
    private externalApiClient?: ExternalApiClient
  ) {}

  async processData(id: number) {
    // Prismaは実際のDBまたはテスト用DBを使用
    const data = await this.prisma.model.findUnique({ where: { id } });
    
    // 外部APIはテスト時にモック化
    if (this.externalApiClient) {
      await this.externalApiClient.sendData(data);
    }
    
    return data;
  }
}

// テストでの使用例
describe('TestableService', () => {
  it('should process data correctly', async () => {
    const mockApiClient = {
      sendData: vi.fn().mockResolvedValue(true)
    };
    
    const service = new TestableService(
      globalThis.vPrisma.client, // テスト用Prismaクライアント
      mockApiClient as ExternalApiClient
    );
    
    const result = await service.processData(1);
    expect(mockApiClient.sendData).toHaveBeenCalledWith(result);
  });
});
```

## エラーハンドリング

### 1. Prismaエラーの適切な処理

```typescript
import { Prisma } from '@prisma/client';

async createRecord(data: CreateRecordData) {
  try {
    return await this.prisma.record.create({ data });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      switch (error.code) {
        case 'P2002':
          // ユニーク制約違反
          throw new Error(`Record with this ${error.meta?.target} already exists`);
        case 'P2025':
          // レコードが見つからない
          throw new Error('Referenced record not found');
        case 'P2003':
          // 外部キー制約違反
          throw new Error('Invalid reference to related record');
        default:
          throw new Error(`Database error: ${error.message}`);
      }
    }
    
    if (error instanceof Prisma.PrismaClientValidationError) {
      throw new Error(`Validation error: ${error.message}`);
    }
    
    // その他のエラー
    throw error;
  }
}
```

### 2. バリデーション

```typescript
// ✅ 推奨: 入力値の検証
async updateRecord(id: number, data: UpdateRecordData) {
  // 基本的な検証
  if (!id || id <= 0) {
    throw new Error('Invalid record ID');
  }

  // データの検証
  if (data.email && !this.isValidEmail(data.email)) {
    throw new Error('Invalid email format');
  }

  // 存在確認
  const existingRecord = await this.prisma.record.findUnique({
    where: { id }
  });
  
  if (!existingRecord) {
    throw new Error('Record not found');
  }

  // 更新実行
  return await this.prisma.record.update({
    where: { id },
    data: this.sanitizeUpdateData(data)
  });
}

private sanitizeUpdateData(data: UpdateRecordData): Prisma.RecordUpdateInput {
  // 不要なフィールドを除去し、安全なデータのみ返す
  const { id, createdAt, ...safeData } = data;
  return safeData;
}

private isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

## パフォーマンス最適化

### 1. インデックスの効果的な使用

```prisma
model Order {
  id          Int      @id @default(autoincrement())
  orderCode   String   @unique
  orderDate   DateTime
  supplierId    Int
  status      Status
  
  supplier      Supplier   @relation(fields: [supplierId], references: [id])
  
  // ✅ 推奨: よく使用される検索条件にインデックス
  @@index([supplierId, orderDate], name: "idx_supplier_order_date")
  @@index([status, orderDate], name: "idx_status_order_date")
  @@index([orderDate], name: "idx_order_date") // 単一カラムインデックス
}
```

### 2. クエリ最適化

```typescript
// ✅ 推奨: 並列実行で高速化
async getOrderSummary(supplierId: number, year: number) {
  const startDate = new Date(year, 0, 1);
  const endDate = new Date(year + 1, 0, 1);

  const [orders, totalAmount, orderCount] = await Promise.all([
    this.prisma.order.findMany({
      where: {
        supplierId,
        orderDate: { gte: startDate, lt: endDate }
      },
      select: {
        id: true,
        orderCode: true,
        orderAmount: true,
        orderDate: true
      },
      orderBy: { orderDate: 'desc' }
    }),
    this.prisma.order.aggregate({
      where: {
        supplierId,
        orderDate: { gte: startDate, lt: endDate }
      },
      _sum: { orderAmount: true }
    }),
    this.prisma.order.count({
      where: {
        supplierId,
        orderDate: { gte: startDate, lt: endDate }
      }
    })
  ]);

  return {
    orders,
    totalAmount: totalAmount._sum.orderAmount || 0,
    orderCount
  };
}
```

### 3. 接続プール管理

```typescript
// prisma/client設定例
export const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  },
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

// アプリケーション終了時のクリーンアップ
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});
```

## セキュリティベストプラクティス

### 1. 行レベルセキュリティ（RLS）

```typescript
// ユーザー固有データの取得
async getUserOrders(userId: number, requestingUserId: number) {
  // 権限チェック
  if (userId !== requestingUserId && !await this.isAdmin(requestingUserId)) {
    throw new Error('Unauthorized access');
  }

  return await this.prisma.order.findMany({
    where: { 
      userId,
      // 追加の条件でデータアクセスを制限
      status: { not: 'DELETED' }
    }
  });
}
```

### 2. SQLインジェクション対策

```typescript
// ✅ 推奨: Prismaの型安全なクエリ
async searchRecords(query: string) {
  return await this.prisma.record.findMany({
    where: {
      OR: [
        { title: { contains: query, mode: 'insensitive' } },
        { description: { contains: query, mode: 'insensitive' } }
      ]
    }
  });
}

// ❌ 禁止: 生のSQL（SQLインジェクションのリスク）
async searchRecordsUnsafe(query: string) {
  return await this.prisma.$queryRaw`
    SELECT * FROM records 
    WHERE title LIKE '%${query}%' 
    OR description LIKE '%${query}%'
  `;
}
```

## まとめ

これらのベストプラクティスにより、以下を実現できます：

1. **型安全性**: TypeScriptとPrismaの型システムを活用した安全なデータアクセス
2. **高いパフォーマンス**: 効率的なクエリとインデックス設計
3. **保守性**: 一貫した命名規則と明確なスキーマ構造
4. **テスタビリティ**: 依存性注入によるテスト対応
5. **セキュリティ**: 適切な権限制御とSQLインジェクション対策

Prismaの特性を最大限活用した、安全で高性能なデータベースアクセス層を構築できます。