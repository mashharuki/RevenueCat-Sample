const REVENUECAT_API_BASE = 'https://api.revenuecat.com/v1'

export type SubscriberStatus = {
  hasActiveEntitlement: boolean
}

type RevenueCatSubscriberResponse = {
  subscriber?: {
    entitlements?: Record<string, { expires_date: string | null }>
  }
}

export type RevenueCatClientOptions = {
  secretKey: string
  entitlementId: string
}

/**
 * Looks up a RevenueCat subscriber's entitlement status via the REST API
 * (not the Management API — this is the `GET /v1/subscribers/{uid}` endpoint
 * authenticated with the project's secret API key). A 404 means RevenueCat
 * has no record of this subscriber, which is normalized to "no entitlement"
 * rather than treated as an error (design.md Implementation Notes).
 */
export async function getSubscriberStatus(
  uid: string,
  { secretKey, entitlementId }: RevenueCatClientOptions
): Promise<SubscriberStatus> {
  const response = await fetch(`${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(uid)}`, {
    headers: {
      Authorization: `Bearer ${secretKey}`,
    },
  })

  if (response.status === 404) {
    return { hasActiveEntitlement: false }
  }

  if (!response.ok) {
    throw new Error(`RevenueCat subscriber lookup failed with status ${response.status}`)
  }

  const body = (await response.json()) as RevenueCatSubscriberResponse
  const entitlement = body.subscriber?.entitlements?.[entitlementId]

  if (!entitlement) {
    return { hasActiveEntitlement: false }
  }

  const isActive = entitlement.expires_date === null || new Date(entitlement.expires_date) > new Date()
  return { hasActiveEntitlement: isActive }
}
