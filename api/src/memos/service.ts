import type { Memo, MemoRepository } from './repository'

export type MemoServiceError =
  | { kind: 'validation'; message: string }
  | { kind: 'forbidden' }
  | { kind: 'not_found' }
  | { kind: 'limit_reached'; limit: number }

export type Result<T, E> = { ok: true; data: T } | { ok: false; error: E }

export type MemoService = {
  listMemos(uid: string): Promise<Memo[]>
  createMemo(uid: string, content: string): Promise<Result<Memo, MemoServiceError>>
  updateMemo(uid: string, memoId: string, content: string): Promise<Result<Memo, MemoServiceError>>
  deleteMemo(uid: string, memoId: string): Promise<Result<void, MemoServiceError>>
}

export type MemoServiceDeps = {
  repository: MemoRepository
  /** Checked only when the free-tier limit is reached (design.md invariant: never queried on every create). */
  getSubscriberStatus: (uid: string) => Promise<{ hasActiveEntitlement: boolean }>
  freeTierLimit: number
}

function isEmptyContent(content: string): boolean {
  return content.trim().length === 0
}

export function createMemoService(deps: MemoServiceDeps): MemoService {
  const { repository, getSubscriberStatus, freeTierLimit } = deps

  async function checkOwnership(uid: string, memoId: string): Promise<MemoServiceError | null> {
    const ownerId = await repository.findOwnerId(memoId)
    if (ownerId === null) return { kind: 'not_found' }
    if (ownerId !== uid) return { kind: 'forbidden' }
    return null
  }

  return {
    async listMemos(uid) {
      return repository.listByUser(uid)
    },

    async createMemo(uid, content) {
      if (isEmptyContent(content)) {
        return { ok: false, error: { kind: 'validation', message: 'content must not be empty' } }
      }

      const count = await repository.countByUser(uid)
      if (count >= freeTierLimit) {
        const status = await getSubscriberStatus(uid)
        if (!status.hasActiveEntitlement) {
          return { ok: false, error: { kind: 'limit_reached', limit: freeTierLimit } }
        }
      }

      const now = new Date().toISOString()
      const memo: Memo = { id: crypto.randomUUID(), userId: uid, content, createdAt: now, updatedAt: now }
      await repository.insert(memo)
      return { ok: true, data: memo }
    },

    async updateMemo(uid, memoId, content) {
      if (isEmptyContent(content)) {
        return { ok: false, error: { kind: 'validation', message: 'content must not be empty' } }
      }

      const ownershipError = await checkOwnership(uid, memoId)
      if (ownershipError) return { ok: false, error: ownershipError }

      const updated = await repository.update(uid, memoId, content, new Date().toISOString())
      if (!updated) return { ok: false, error: { kind: 'not_found' } }
      return { ok: true, data: updated }
    },

    async deleteMemo(uid, memoId) {
      const ownershipError = await checkOwnership(uid, memoId)
      if (ownershipError) return { ok: false, error: ownershipError }

      const deleted = await repository.delete(uid, memoId)
      if (!deleted) return { ok: false, error: { kind: 'not_found' } }
      return { ok: true, data: undefined }
    },
  }
}
