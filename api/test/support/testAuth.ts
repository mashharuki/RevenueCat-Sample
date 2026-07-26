import { sign } from 'hono/jwt'
import { vi } from 'vitest'

const KID = 'test-key-1'
const RS256_PARAMS: SubtleCryptoGenerateKeyAlgorithm = {
  name: 'RSASSA-PKCS1-v1_5',
  hash: 'SHA-256',
  modulusLength: 2048,
  publicExponent: new Uint8Array([1, 0, 1]),
}

/** The Workers-runtime ambient `JsonWebKey` (from `src/types/env.d.ts`) has no `kid` field, but
 * `hono/jwt`'s `sign()` reads `kid` off a JWK-shaped `privateKey` to build the token header. */
type SigningJwk = JsonWebKey & { kid: string }

let privateJwk: SigningJwk
let publicJwk: SigningJwk

/** Generates the RSA keypair used to sign/verify test tokens. Call once, e.g. in `beforeAll`. */
export async function setUpTestJwks(): Promise<void> {
  // `generateKey`'s ambient Workers-runtime type returns `CryptoKey | CryptoKeyPair` regardless of
  // algorithm (no overload discrimination) — RSASSA-PKCS1-v1_5 always yields a key *pair*.
  const keyPair = (await crypto.subtle.generateKey(RS256_PARAMS, true, ['sign', 'verify'])) as CryptoKeyPair
  const exportedPrivate = (await crypto.subtle.exportKey('jwk', keyPair.privateKey)) as JsonWebKey
  const exportedPublic = (await crypto.subtle.exportKey('jwk', keyPair.publicKey)) as JsonWebKey
  privateJwk = { ...exportedPrivate, kid: KID }
  publicJwk = { ...exportedPublic, kid: KID }
}

/** Signs a test Firebase-ID-token-shaped JWT for `uid`, scoped to `projectId` (must match the
 * running app's `FIREBASE_PROJECT_ID` binding for `firebaseAuthMiddleware` to accept it). */
export async function signTestToken(
  projectId: string,
  uid: string,
  overrides: Record<string, unknown> = {}
): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  return sign(
    {
      iss: `https://securetoken.google.com/${projectId}`,
      aud: projectId,
      sub: uid,
      iat: now,
      exp: now + 3600,
      ...overrides,
    },
    privateJwk,
    'RS256'
  )
}

/**
 * Stubs `fetch` for the two outbound calls the real, unmodified request pipeline makes: the
 * Firebase JWKS lookup (`hono/jwk`, inside `firebaseAuthMiddleware`) and the RevenueCat subscriber
 * lookup (`RevenueCatClient`, only reached once `MemoService` hits the free-tier limit). Neither
 * `firebaseAuthMiddleware` nor `RevenueCatClient` are modified or reimplemented for testing — only
 * the network boundary is intercepted (same approach as task 8.1's `firebaseAuthMiddleware.test.ts`).
 */
export function stubJwksAndRevenueCatFetch(options: { hasActiveEntitlement: boolean; entitlementId: string }): void {
  vi.stubGlobal(
    'fetch',
    vi.fn(async (input: RequestInfo | URL) => {
      const url = typeof input === 'string' ? input : input instanceof URL ? input.toString() : input.url
      if (url.includes('googleapis.com/service_accounts')) {
        return Response.json({ keys: [publicJwk] })
      }
      if (url.includes('api.revenuecat.com')) {
        if (!options.hasActiveEntitlement) {
          return new Response(null, { status: 404 })
        }
        return Response.json({ subscriber: { entitlements: { [options.entitlementId]: { expires_date: null } } } })
      }
      throw new Error(`Unexpected fetch to ${url} in integration test`)
    })
  )
}
