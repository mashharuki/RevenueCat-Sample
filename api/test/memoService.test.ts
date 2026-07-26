import { describe, expect, it, vi } from 'vitest'
import { createMemoService } from '../src/memos/service'
import type { Memo, MemoRepository } from '../src/memos/repository'

const FREE_TIER_LIMIT = 20

function makeMemo(overrides: Partial<Memo> = {}): Memo {
  return {
    id: 'memo-1',
    userId: 'user-a',
    content: 'hello',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    ...overrides,
  }
}

/** In-memory fake — lets tests assert on call counts without a real D1 binding. */
function makeRepository(overrides: Partial<MemoRepository> = {}): MemoRepository {
  return {
    listByUser: vi.fn(async () => []),
    countByUser: vi.fn(async () => 0),
    insert: vi.fn(async () => {}),
    findOwnerId: vi.fn(async () => null),
    update: vi.fn(async () => null),
    delete: vi.fn(async () => false),
    ...overrides,
  }
}

describe('createMemoService.createMemo', () => {
  it('should reject empty content without touching the repository or RevenueCat (Requirement 2.5)', async () => {
    const repository = makeRepository()
    const getSubscriberStatus = vi.fn()
    const service = createMemoService({ repository, getSubscriberStatus, freeTierLimit: FREE_TIER_LIMIT })

    const result = await service.createMemo('user-a', '   ')

    expect(result).toEqual({ ok: false, error: { kind: 'validation', message: 'content must not be empty' } })
    expect(repository.insert).not.toHaveBeenCalled()
    expect(getSubscriberStatus).not.toHaveBeenCalled()
  })

  it('should create immediately without checking RevenueCat when under the free-tier limit (Requirement 3.1, 3.4)', async () => {
    const repository = makeRepository({ countByUser: vi.fn(async () => FREE_TIER_LIMIT - 1) })
    const getSubscriberStatus = vi.fn()
    const service = createMemoService({ repository, getSubscriberStatus, freeTierLimit: FREE_TIER_LIMIT })

    const result = await service.createMemo('user-a', 'new memo')

    expect(result.ok).toBe(true)
    expect(repository.insert).toHaveBeenCalledTimes(1)
    expect(getSubscriberStatus).not.toHaveBeenCalled()
  })

  it('should create when at the limit but the entitlement is active (Requirement 3.2, 3.3)', async () => {
    const repository = makeRepository({ countByUser: vi.fn(async () => FREE_TIER_LIMIT) })
    const getSubscriberStatus = vi.fn(async () => ({ hasActiveEntitlement: true }))
    const service = createMemoService({ repository, getSubscriberStatus, freeTierLimit: FREE_TIER_LIMIT })

    const result = await service.createMemo('user-a', 'new memo')

    expect(result.ok).toBe(true)
    expect(repository.insert).toHaveBeenCalledTimes(1)
    expect(getSubscriberStatus).toHaveBeenCalledWith('user-a')
  })

  it('should reject with limit_reached when at the limit and the entitlement is inactive (Requirement 3.2, 4.6)', async () => {
    const repository = makeRepository({ countByUser: vi.fn(async () => FREE_TIER_LIMIT) })
    const getSubscriberStatus = vi.fn(async () => ({ hasActiveEntitlement: false }))
    const service = createMemoService({ repository, getSubscriberStatus, freeTierLimit: FREE_TIER_LIMIT })

    const result = await service.createMemo('user-a', 'new memo')

    expect(result).toEqual({ ok: false, error: { kind: 'limit_reached', limit: FREE_TIER_LIMIT } })
    expect(repository.insert).not.toHaveBeenCalled()
  })
})

describe('createMemoService ownership checks (Requirement 2.6, 5.1)', () => {
  it('should forbid updating a memo owned by a different user', async () => {
    const repository = makeRepository({ findOwnerId: vi.fn(async () => 'someone-else') })
    const service = createMemoService({
      repository,
      getSubscriberStatus: vi.fn(),
      freeTierLimit: FREE_TIER_LIMIT,
    })

    const result = await service.updateMemo('user-a', 'memo-1', 'edited content')

    expect(result).toEqual({ ok: false, error: { kind: 'forbidden' } })
    expect(repository.update).not.toHaveBeenCalled()
  })

  it('should forbid deleting a memo owned by a different user', async () => {
    const repository = makeRepository({ findOwnerId: vi.fn(async () => 'someone-else') })
    const service = createMemoService({
      repository,
      getSubscriberStatus: vi.fn(),
      freeTierLimit: FREE_TIER_LIMIT,
    })

    const result = await service.deleteMemo('user-a', 'memo-1')

    expect(result).toEqual({ ok: false, error: { kind: 'forbidden' } })
    expect(repository.delete).not.toHaveBeenCalled()
  })

  it('should report not_found when updating a memo that does not exist', async () => {
    const repository = makeRepository({ findOwnerId: vi.fn(async () => null) })
    const service = createMemoService({
      repository,
      getSubscriberStatus: vi.fn(),
      freeTierLimit: FREE_TIER_LIMIT,
    })

    const result = await service.updateMemo('user-a', 'missing-memo', 'edited content')

    expect(result).toEqual({ ok: false, error: { kind: 'not_found' } })
  })

  it('should update when the memo belongs to the caller', async () => {
    const updated = makeMemo({ content: 'edited content' })
    const repository = makeRepository({
      findOwnerId: vi.fn(async () => 'user-a'),
      update: vi.fn(async () => updated),
    })
    const service = createMemoService({
      repository,
      getSubscriberStatus: vi.fn(),
      freeTierLimit: FREE_TIER_LIMIT,
    })

    const result = await service.updateMemo('user-a', 'memo-1', 'edited content')

    expect(result).toEqual({ ok: true, data: updated })
  })
})
