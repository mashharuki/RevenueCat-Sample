import { env } from 'cloudflare:workers'
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest'
import app from '../src/index'
import { setUpTestJwks, signTestToken, stubJwksAndRevenueCatFetch } from './support/testAuth'

const JSON_HEADERS = { 'Content-Type': 'application/json' }

beforeAll(async () => {
  await setUpTestJwks()
})

afterEach(() => {
  vi.unstubAllGlobals()
})

async function authFor(uid: string): Promise<Record<string, string>> {
  const token = await signTestToken(env.FIREBASE_PROJECT_ID, uid)
  return { Authorization: `Bearer ${token}` }
}

/** Uses a distinct RevenueCat entitlement stub per call site to keep tests independent regardless
 * of Miniflare's isolated-storage semantics between individual `it()` blocks. */
function stubEntitlement(hasActiveEntitlement: boolean): void {
  stubJwksAndRevenueCatFetch({ hasActiveEntitlement, entitlementId: env.RC_ENTITLEMENT_ID })
}

describe('Memos API against local D1 (Requirements 2.1, 2.2, 2.3, 2.4)', () => {
  it('should create, list, update, and delete a memo end-to-end for one user', async () => {
    stubEntitlement(false)
    const auth = await authFor('uid-crud-flow')

    const createRes = await app.request(
      '/api/memos',
      { method: 'POST', headers: { ...auth, ...JSON_HEADERS }, body: JSON.stringify({ content: 'first memo' }) },
      env
    )
    expect(createRes.status).toBe(201)
    const created = (await createRes.json()) as { id: string; content: string }
    expect(created.content).toBe('first memo')
    // design.md's API Data Transfer contract omits userId from client-facing responses.
    expect(created).not.toHaveProperty('userId')

    const listRes = await app.request('/api/memos', { headers: auth }, env)
    expect(listRes.status).toBe(200)
    const list = (await listRes.json()) as Array<{ id: string }>
    expect(list.map((m) => m.id)).toEqual([created.id])

    const patchRes = await app.request(
      `/api/memos/${created.id}`,
      { method: 'PATCH', headers: { ...auth, ...JSON_HEADERS }, body: JSON.stringify({ content: 'updated memo' }) },
      env
    )
    expect(patchRes.status).toBe(200)
    expect(((await patchRes.json()) as { content: string }).content).toBe('updated memo')

    const deleteRes = await app.request(`/api/memos/${created.id}`, { method: 'DELETE', headers: auth }, env)
    expect(deleteRes.status).toBe(204)

    const listAfterDeleteRes = await app.request('/api/memos', { headers: auth }, env)
    expect(await listAfterDeleteRes.json()).toEqual([])
  })

  it('should not show one user’s memos in another user’s list (Requirement 2.2, 5.1 data isolation)', async () => {
    stubEntitlement(false)
    const authA = await authFor('uid-isolation-a')
    const authB = await authFor('uid-isolation-b')

    await app.request(
      '/api/memos',
      { method: 'POST', headers: { ...authA, ...JSON_HEADERS }, body: JSON.stringify({ content: 'a-only' }) },
      env
    )

    const listAsB = (await (await app.request('/api/memos', { headers: authB }, env)).json()) as unknown[]
    expect(listAsB).toEqual([])

    const listAsA = (await (await app.request('/api/memos', { headers: authA }, env)).json()) as Array<{
      content: string
    }>
    expect(listAsA).toHaveLength(1)
    expect(listAsA[0]?.content).toBe('a-only')
  })
})

describe('Free-tier limit against local D1 (Requirements 3.1, 3.3)', () => {
  it('should return 201 under the limit, 403 limit_reached at the limit without an entitlement, then 201 once entitled', async () => {
    stubEntitlement(false)
    const auth = await authFor('uid-limit-flow')
    const limit = env.FREE_TIER_MEMO_LIMIT

    for (let i = 0; i < limit; i++) {
      const res = await app.request(
        '/api/memos',
        { method: 'POST', headers: { ...auth, ...JSON_HEADERS }, body: JSON.stringify({ content: `memo ${i}` }) },
        env
      )
      expect(res.status).toBe(201)
    }

    const blockedRes = await app.request(
      '/api/memos',
      { method: 'POST', headers: { ...auth, ...JSON_HEADERS }, body: JSON.stringify({ content: 'blocked' }) },
      env
    )
    expect(blockedRes.status).toBe(403)
    expect(((await blockedRes.json()) as { error: string }).error).toBe('limit_reached')

    stubEntitlement(true)
    const unlockedRes = await app.request(
      '/api/memos',
      { method: 'POST', headers: { ...auth, ...JSON_HEADERS }, body: JSON.stringify({ content: 'unlocked' }) },
      env
    )
    expect(unlockedRes.status).toBe(201)
  })
})

describe('Cross-user ownership enforcement against local D1 (Requirement 2.6)', () => {
  it('should reject another user’s update/delete with 403 and report 404 for a nonexistent memo', async () => {
    stubEntitlement(false)
    const owner = await authFor('uid-owner')
    const intruder = await authFor('uid-intruder')

    const createRes = await app.request(
      '/api/memos',
      { method: 'POST', headers: { ...owner, ...JSON_HEADERS }, body: JSON.stringify({ content: 'owned by owner' }) },
      env
    )
    const memo = (await createRes.json()) as { id: string }

    const patchAsIntruder = await app.request(
      `/api/memos/${memo.id}`,
      { method: 'PATCH', headers: { ...intruder, ...JSON_HEADERS }, body: JSON.stringify({ content: 'hijack' }) },
      env
    )
    expect(patchAsIntruder.status).toBe(403)

    const deleteAsIntruder = await app.request(`/api/memos/${memo.id}`, { method: 'DELETE', headers: intruder }, env)
    expect(deleteAsIntruder.status).toBe(403)

    // The memo must survive the rejected delete attempt.
    const listAsOwner = (await (await app.request('/api/memos', { headers: owner }, env)).json()) as unknown[]
    expect(listAsOwner).toHaveLength(1)

    const patchMissing = await app.request(
      '/api/memos/does-not-exist',
      { method: 'PATCH', headers: { ...owner, ...JSON_HEADERS }, body: JSON.stringify({ content: 'x' }) },
      env
    )
    expect(patchMissing.status).toBe(404)
  })
})
