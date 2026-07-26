import { afterEach, describe, expect, it, vi } from 'vitest'
import { getSubscriberStatus } from '../src/billing/revenueCatClient'

const OPTIONS = { secretKey: 'test-secret', entitlementId: 'memo_premium' }

describe('getSubscriberStatus', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('should normalize a 404 (unknown subscriber) to no active entitlement, not an error (design.md Implementation Notes)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => new Response(null, { status: 404 }))
    )

    const result = await getSubscriberStatus('unknown-uid', OPTIONS)

    expect(result).toEqual({ hasActiveEntitlement: false })
  })

  it('should report an active entitlement with no expiry as active (lifetime/promotional grant)', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        Response.json({ subscriber: { entitlements: { memo_premium: { expires_date: null } } } })
      )
    )

    const result = await getSubscriberStatus('known-uid', OPTIONS)

    expect(result).toEqual({ hasActiveEntitlement: true })
  })

  it('should report an entitlement with a future expiry as active', async () => {
    const future = new Date(Date.now() + 60_000).toISOString()
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        Response.json({ subscriber: { entitlements: { memo_premium: { expires_date: future } } } })
      )
    )

    const result = await getSubscriberStatus('known-uid', OPTIONS)

    expect(result).toEqual({ hasActiveEntitlement: true })
  })

  it('should report an entitlement with a past expiry as inactive (Requirement 4.6 — re-apply the limit without deleting data)', async () => {
    const past = new Date(Date.now() - 60_000).toISOString()
    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        Response.json({ subscriber: { entitlements: { memo_premium: { expires_date: past } } } })
      )
    )

    const result = await getSubscriberStatus('known-uid', OPTIONS)

    expect(result).toEqual({ hasActiveEntitlement: false })
  })

  it('should report no active entitlement when the subscriber has no matching entitlement id', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => Response.json({ subscriber: { entitlements: {} } }))
    )

    const result = await getSubscriberStatus('known-uid', OPTIONS)

    expect(result).toEqual({ hasActiveEntitlement: false })
  })
})
