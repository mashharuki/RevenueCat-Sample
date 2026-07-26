export type Memo = {
  id: string
  userId: string
  content: string
  createdAt: string
  updatedAt: string
}

type MemoRow = {
  id: string
  user_id: string
  content: string
  created_at: string
  updated_at: string
}

function toMemo(row: MemoRow): Memo {
  return {
    id: row.id,
    userId: row.user_id,
    content: row.content,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

export type MemoRepository = {
  listByUser(userId: string): Promise<Memo[]>
  countByUser(userId: string): Promise<number>
  insert(memo: Memo): Promise<void>
  /** Returns only the owning user_id (never memo content) — used to distinguish 403 vs 404. */
  findOwnerId(memoId: string): Promise<string | null>
  update(userId: string, memoId: string, content: string, updatedAt: string): Promise<Memo | null>
  delete(userId: string, memoId: string): Promise<boolean>
}

/**
 * All data-returning queries (list, insert, update, delete) are scoped by
 * user_id so a caller can structurally never read or mutate another user's
 * memos (design.md MemoRepository constraint). findOwnerId() is a narrow,
 * deliberate exception: it returns only the owner's uid (never memo
 * content), letting MemoService distinguish "not found" from "forbidden"
 * without exposing another user's data.
 */
export function createMemoRepository(db: D1Database): MemoRepository {
  return {
    async listByUser(userId) {
      const { results } = await db
        .prepare('SELECT * FROM memos WHERE user_id = ? ORDER BY updated_at DESC')
        .bind(userId)
        .all<MemoRow>()
      return results.map(toMemo)
    },

    async countByUser(userId) {
      const row = await db
        .prepare('SELECT COUNT(*) as count FROM memos WHERE user_id = ?')
        .bind(userId)
        .first<{ count: number }>()
      return row?.count ?? 0
    },

    async insert(memo) {
      await db
        .prepare('INSERT INTO memos (id, user_id, content, created_at, updated_at) VALUES (?, ?, ?, ?, ?)')
        .bind(memo.id, memo.userId, memo.content, memo.createdAt, memo.updatedAt)
        .run()
    },

    async findOwnerId(memoId) {
      const row = await db.prepare('SELECT user_id FROM memos WHERE id = ?').bind(memoId).first<{ user_id: string }>()
      return row?.user_id ?? null
    },

    async update(userId, memoId, content, updatedAt) {
      await db
        .prepare('UPDATE memos SET content = ?, updated_at = ? WHERE id = ? AND user_id = ?')
        .bind(content, updatedAt, memoId, userId)
        .run()
      const row = await db
        .prepare('SELECT * FROM memos WHERE id = ? AND user_id = ?')
        .bind(memoId, userId)
        .first<MemoRow>()
      return row ? toMemo(row) : null
    },

    async delete(userId, memoId) {
      const result = await db.prepare('DELETE FROM memos WHERE id = ? AND user_id = ?').bind(memoId, userId).run()
      return (result.meta.changes ?? 0) > 0
    },
  }
}
