# Drizzleベストプラクティス

このドキュメントは、Drizzle ORMを使用したデータベース設計・運用のベストプラクティスをまとめたものです。

## 基本原則

1. **型安全性**: Drizzleの型システムを最大限活用
2. **軽量性**: Cloudflare Workersでの最適なパフォーマンス
3. **直感性**: SQLライクな構文による分かりやすいクエリ記述
4. **保守性**: シンプルなスキーマ構造と明確なマイグレーション戦略

## スキーマ設計ベストプラクティス

### 1. テーブル定義とリレーション

```typescript
import { pgTable, uuid, text, timestamp, decimal, date, pgEnum } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// Enumの定義
export const frequencyEnum = pgEnum('frequency', ['monthly', 'yearly', 'once']);
export const categoryEnum = pgEnum('category', ['chat', 'api', 'editor', 'agent', 'other']);

// ユーザーテーブル
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

// AIサービステーブル
export const services = pgTable('services', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  category: categoryEnum('category').notNull(),
  createdAt: timestamp('created_at').defaultNow(),
});

// サブスクリプションテーブル
export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  serviceId: uuid('service_id').notNull().references(() => services.id),
  amount: decimal('amount').notNull(),
  currency: text('currency').notNull().default('JPY'),
  frequency: frequencyEnum('frequency').notNull(),
  startDate: date('start_date').notNull(),
  endDate: date('end_date'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});
```

### 2. リレーション定義

```typescript
// リレーションの定義
export const usersRelations = relations(users, ({ many }) => ({
  subscriptions: many(subscriptions),
}));

export const servicesRelations = relations(services, ({ many }) => ({
  subscriptions: many(subscriptions),
}));

export const subscriptionsRelations = relations(subscriptions, ({ one }) => ({
  user: one(users, {
    fields: [subscriptions.userId],
    references: [users.id],
  }),
  service: one(services, {
    fields: [subscriptions.serviceId],
    references: [services.id],
  }),
}));
```

### 3. インデックスと制約

```typescript
import { pgTable, index, uniqueIndex } from 'drizzle-orm/pg-core';

export const subscriptions = pgTable('subscriptions', {
  // ... フィールド定義
}, (table) => ({
  // パフォーマンス最適化のためのインデックス
  userIdIdx: index('idx_subscriptions_user_id').on(table.userId),
  serviceIdIdx: index('idx_subscriptions_service_id').on(table.serviceId),
  frequencyIdx: index('idx_subscriptions_frequency').on(table.frequency),
  
  // 複合インデックス
  userServiceIdx: index('idx_user_service').on(table.userId, table.serviceId),
  
  // ユニーク制約
  userServiceUnique: uniqueIndex('unique_user_service_active')
    .on(table.userId, table.serviceId)
    .where(sql`end_date IS NULL`),
}));
```

## クエリベストプラクティス

### 1. 基本的なCRUD操作

```typescript
import { db } from './connection';
import { users, subscriptions, services } from './schema';
import { eq, and, desc, count } from 'drizzle-orm';

// ✅ 推奨: 型安全なCRUD操作
export class UserService {
  // ユーザー作成
  async createUser(userData: typeof users.$inferInsert) {
    const [newUser] = await db
      .insert(users)
      .values(userData)
      .returning();
    
    return newUser;
  }

  // ユーザー取得（リレーション含む）
  async getUserWithSubscriptions(userId: string) {
    return await db.query.users.findFirst({
      where: eq(users.id, userId),
      with: {
        subscriptions: {
          with: {
            service: true,
          },
        },
      },
    });
  }

  // ユーザー更新
  async updateUser(userId: string, updateData: Partial<typeof users.$inferInsert>) {
    const [updatedUser] = await db
      .update(users)
      .set({ ...updateData, updatedAt: new Date() })
      .where(eq(users.id, userId))
      .returning();
    
    return updatedUser;
  }

  // ユーザー削除（関連データも削除）
  async deleteUser(userId: string) {
    return await db.transaction(async (tx) => {
      // 1. サブスクリプションを削除
      await tx.delete(subscriptions).where(eq(subscriptions.userId, userId));
      
      // 2. ユーザーを削除
      await tx.delete(users).where(eq(users.id, userId));
    });
  }
}
```

### 2. 複雑なクエリパターン

```typescript
export class SubscriptionService {
  // 条件付き検索
  async findSubscriptions(filters: {
    userId?: string;
    category?: string;
    isActive?: boolean;
  }) {
    const conditions = [];
    
    if (filters.userId) {
      conditions.push(eq(subscriptions.userId, filters.userId));
    }
    
    if (filters.isActive !== undefined) {
      if (filters.isActive) {
        conditions.push(isNull(subscriptions.endDate));
      } else {
        conditions.push(isNotNull(subscriptions.endDate));
      }
    }

    return await db
      .select({
        id: subscriptions.id,
        amount: subscriptions.amount,
        currency: subscriptions.currency,
        frequency: subscriptions.frequency,
        serviceName: services.name,
        serviceCategory: services.category,
      })
      .from(subscriptions)
      .innerJoin(services, eq(subscriptions.serviceId, services.id))
      .where(and(...conditions))
      .orderBy(desc(subscriptions.createdAt));
  }

  // 集計クエリ
  async getUserSpendingSummary(userId: string) {
    return await db
      .select({
        totalAmount: sum(subscriptions.amount),
        subscriptionCount: count(subscriptions.id),
        category: services.category,
      })
      .from(subscriptions)
      .innerJoin(services, eq(subscriptions.serviceId, services.id))
      .where(and(
        eq(subscriptions.userId, userId),
        isNull(subscriptions.endDate)
      ))
      .groupBy(services.category);
  }

  // サブクエリを使用した複雑な検索
  async getMostPopularServices(limit: number = 10) {
    const popularServices = db
      .select({
        serviceId: subscriptions.serviceId,
        subscriberCount: count(subscriptions.id).as('subscriber_count'),
      })
      .from(subscriptions)
      .where(isNull(subscriptions.endDate))
      .groupBy(subscriptions.serviceId)
      .as('popular_services');

    return await db
      .select({
        id: services.id,
        name: services.name,
        category: services.category,
        subscriberCount: popularServices.subscriberCount,
      })
      .from(services)
      .innerJoin(popularServices, eq(services.id, popularServices.serviceId))
      .orderBy(desc(popularServices.subscriberCount))
      .limit(limit);
  }
}
```

### 3. トランザクション処理

```typescript
// ✅ 推奨: トランザクションでデータ整合性を保つ
export class PaymentService {
  async createSubscriptionWithPayment(subscriptionData: {
    userId: string;
    serviceId: string;
    amount: string;
    frequency: 'monthly' | 'yearly' | 'once';
  }) {
    return await db.transaction(async (tx) => {
      // 1. サブスクリプション作成
      const [subscription] = await tx
        .insert(subscriptions)
        .values({
          ...subscriptionData,
          startDate: new Date().toISOString().split('T')[0],
        })
        .returning();

      // 2. 決済記録作成（仮想テーブル）
      await tx
        .insert(payments)
        .values({
          subscriptionId: subscription.id,
          amount: subscriptionData.amount,
          status: 'pending',
        });

      // 3. 他の関連処理...
      
      return subscription;
    });
  }

  // エラー時の自動ロールバック
  async updateSubscriptionWithValidation(
    subscriptionId: string,
    updateData: Partial<typeof subscriptions.$inferInsert>
  ) {
    try {
      return await db.transaction(async (tx) => {
        // 1. 既存データの確認
        const existing = await tx.query.subscriptions.findFirst({
          where: eq(subscriptions.id, subscriptionId),
        });

        if (!existing) {
          throw new Error('Subscription not found');
        }

        // 2. ビジネスロジックの検証
        if (updateData.endDate && new Date(updateData.endDate) < new Date(existing.startDate)) {
          throw new Error('End date cannot be before start date');
        }

        // 3. 更新実行
        const [updated] = await tx
          .update(subscriptions)
          .set({ ...updateData, updatedAt: new Date() })
          .where(eq(subscriptions.id, subscriptionId))
          .returning();

        return updated;
      });
    } catch (error) {
      // トランザクションは自動的にロールバックされる
      throw error;
    }
  }
}
```

## パフォーマンス最適化

### 1. Cloudflare Workers向け最適化

```typescript
// connection.ts - Cloudflare Workers用設定
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from './schema';

export function createDrizzleConnection(connectionString: string) {
  const sql = neon(connectionString);
  return drizzle(sql, { schema });
}

// リクエストごとに新しい接続を作成（Workersのベストプラクティス）
export function getDb(env: { DATABASE_URL: string }) {
  return createDrizzleConnection(env.DATABASE_URL);
}
```

### 2. クエリ最適化

```typescript
// ✅ 推奨: 必要なフィールドのみ選択
async getSubscriptionSummary(userId: string) {
  return await db
    .select({
      id: subscriptions.id,
      amount: subscriptions.amount,
      serviceName: services.name,
      // 不要なフィールドは除外
    })
    .from(subscriptions)
    .innerJoin(services, eq(subscriptions.serviceId, services.id))
    .where(eq(subscriptions.userId, userId));
}

// ✅ 推奨: ページネーション
async getSubscriptionsPaginated(userId: string, page: number = 1, limit: number = 20) {
  const offset = (page - 1) * limit;
  
  const [items, totalCount] = await Promise.all([
    db
      .select()
      .from(subscriptions)
      .where(eq(subscriptions.userId, userId))
      .limit(limit)
      .offset(offset)
      .orderBy(desc(subscriptions.createdAt)),
    
    db
      .select({ count: count() })
      .from(subscriptions)
      .where(eq(subscriptions.userId, userId))
  ]);

  return {
    items,
    totalCount: totalCount[0].count,
    page,
    totalPages: Math.ceil(totalCount[0].count / limit),
  };
}
```

### 3. バッチ処理

```typescript
// ✅ 推奨: バッチ挿入
async createMultipleSubscriptions(subscriptionsData: (typeof subscriptions.$inferInsert)[]) {
  return await db
    .insert(subscriptions)
    .values(subscriptionsData)
    .returning();
}

// ✅ 推奨: バッチ更新
async updateMultipleSubscriptions(updates: { id: string; endDate: string }[]) {
  return await db.transaction(async (tx) => {
    const results = [];
    
    for (const update of updates) {
      const [result] = await tx
        .update(subscriptions)
        .set({ endDate: update.endDate, updatedAt: new Date() })
        .where(eq(subscriptions.id, update.id))
        .returning();
      
      results.push(result);
    }
    
    return results;
  });
}
```

## マイグレーション戦略

### 1. Drizzle Kit設定

```typescript
// drizzle.config.ts
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/db/schema.ts',
  out: './migrations',
  driver: 'pg',
  dbCredentials: {
    connectionString: process.env.DATABASE_URL!,
  },
  verbose: true,
  strict: true,
} satisfies Config;
```

### 2. マイグレーション実行

```bash
# マイグレーション生成
pnpm drizzle-kit generate:pg

# マイグレーション実行
pnpm drizzle-kit push:pg

# スキーマ確認
pnpm drizzle-kit studio
```

### 3. 本番環境でのマイグレーション

```typescript
// migrate.ts - 本番環境用マイグレーション実行
import { drizzle } from 'drizzle-orm/neon-http';
import { migrate } from 'drizzle-orm/neon-http/migrator';
import { neon } from '@neondatabase/serverless';

export async function runMigrations(connectionString: string) {
  const sql = neon(connectionString);
  const db = drizzle(sql);
  
  try {
    await migrate(db, { migrationsFolder: './migrations' });
    console.log('Migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
}
```

## テスト戦略

### 1. テスト用データベース設定

```typescript
// test-setup.ts
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import * as schema from '../src/db/schema';

export function createTestDb() {
  const sql = neon(process.env.TEST_DATABASE_URL!);
  return drizzle(sql, { schema });
}

// テスト用データクリーンアップ
export async function cleanupTestDb(db: ReturnType<typeof createTestDb>) {
  await db.delete(schema.subscriptions);
  await db.delete(schema.services);
  await db.delete(schema.users);
}
```

### 2. 統合テスト例

```typescript
// subscription.integration.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestDb, cleanupTestDb } from './test-setup';
import { SubscriptionService } from '../src/services/subscription';

describe('SubscriptionService Integration Tests', () => {
  let db: ReturnType<typeof createTestDb>;
  let subscriptionService: SubscriptionService;

  beforeEach(async () => {
    db = createTestDb();
    subscriptionService = new SubscriptionService(db);
  });

  afterEach(async () => {
    await cleanupTestDb(db);
  });

  it('should create and retrieve subscription', async () => {
    // テストユーザーとサービスの作成
    const [user] = await db.insert(users).values({
      email: 'test@example.com',
      name: 'Test User',
    }).returning();

    const [service] = await db.insert(services).values({
      name: 'ChatGPT',
      category: 'chat',
    }).returning();

    // サブスクリプション作成
    const subscription = await subscriptionService.createSubscription({
      userId: user.id,
      serviceId: service.id,
      amount: '20.00',
      frequency: 'monthly',
    });

    expect(subscription.userId).toBe(user.id);
    expect(subscription.serviceId).toBe(service.id);
    expect(subscription.amount).toBe('20.00');
  });
});
```

## エラーハンドリング

### 1. Drizzleエラーの処理

```typescript
import { DatabaseError } from 'pg';

export class DatabaseService {
  async createUserSafely(userData: typeof users.$inferInsert) {
    try {
      const [newUser] = await db
        .insert(users)
        .values(userData)
        .returning();
      
      return { success: true, data: newUser };
    } catch (error) {
      if (error instanceof DatabaseError) {
        switch (error.code) {
          case '23505': // Unique violation
            return { 
              success: false, 
              error: 'User with this email already exists' 
            };
          case '23503': // Foreign key violation
            return { 
              success: false, 
              error: 'Referenced record not found' 
            };
          case '23514': // Check constraint violation
            return { 
              success: false, 
              error: 'Invalid data provided' 
            };
          default:
            return { 
              success: false, 
              error: `Database error: ${error.message}` 
            };
        }
      }
      
      return { 
        success: false, 
        error: 'Unexpected error occurred' 
      };
    }
  }
}
```

### 2. バリデーション統合

```typescript
import { z } from 'zod';

// Zodスキーマでバリデーション
export const createSubscriptionSchema = z.object({
  userId: z.string().uuid(),
  serviceId: z.string().uuid(),
  amount: z.string().regex(/^\d+\.\d{2}$/),
  frequency: z.enum(['monthly', 'yearly', 'once']),
  startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

export class SubscriptionService {
  async createSubscription(data: unknown) {
    // 1. 入力値検証
    const validatedData = createSubscriptionSchema.parse(data);
    
    // 2. ビジネスロジック検証
    const existingActive = await db.query.subscriptions.findFirst({
      where: and(
        eq(subscriptions.userId, validatedData.userId),
        eq(subscriptions.serviceId, validatedData.serviceId),
        isNull(subscriptions.endDate)
      ),
    });

    if (existingActive) {
      throw new Error('Active subscription already exists for this service');
    }

    // 3. データベース操作
    const [subscription] = await db
      .insert(subscriptions)
      .values(validatedData)
      .returning();

    return subscription;
  }
}
```

## セキュリティベストプラクティス

### 1. Row Level Security (RLS) 対応

```typescript
// ユーザー固有データのアクセス制御
export class SecureUserService {
  async getUserData(requestingUserId: string, targetUserId: string) {
    // 権限チェック
    if (requestingUserId !== targetUserId) {
      const isAdmin = await this.checkAdminPermission(requestingUserId);
      if (!isAdmin) {
        throw new Error('Unauthorized access');
      }
    }

    return await db.query.users.findFirst({
      where: eq(users.id, targetUserId),
      with: {
        subscriptions: {
          where: isNull(subscriptions.endDate), // アクティブなもののみ
        },
      },
    });
  }

  private async checkAdminPermission(userId: string): Promise<boolean> {
    // 管理者権限チェックロジック
    return false; // 実装に応じて変更
  }
}
```

### 2. SQLインジェクション対策

```typescript
// ✅ 推奨: パラメータ化クエリ（Drizzleは自動的に安全）
async searchServices(query: string) {
  return await db
    .select()
    .from(services)
    .where(ilike(services.name, `%${query}%`)); // 自動的にエスケープされる
}

// ✅ 推奨: 動的な条件も安全に構築
async searchWithFilters(filters: {
  name?: string;
  category?: string;
  minAmount?: string;
}) {
  const conditions = [];
  
  if (filters.name) {
    conditions.push(ilike(services.name, `%${filters.name}%`));
  }
  
  if (filters.category) {
    conditions.push(eq(services.category, filters.category));
  }
  
  return await db
    .select()
    .from(services)
    .where(and(...conditions));
}
```

## まとめ

これらのベストプラクティスにより、以下を実現できます：

1. **高いパフォーマンス**: Cloudflare Workers環境に最適化された軽量なORM
2. **型安全性**: TypeScript-firstによる安全なデータアクセス
3. **直感的な開発体験**: SQLライクな構文による分かりやすいクエリ記述
4. **保守性**: シンプルなスキーマ管理と明確なマイグレーション戦略
5. **セキュリティ**: 適切な権限制御とSQLインジェクション対策

Drizzleの特性を最大限活用した、高性能で安全なデータベースアクセス層を構築できます。