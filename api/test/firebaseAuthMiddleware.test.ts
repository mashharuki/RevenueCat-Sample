import { Hono } from 'hono'
import { sign } from 'hono/jwt'
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest'
import { firebaseAuthMiddleware, type VerifiedIdentity } from '../src/middleware/firebaseAuth'

const PROJECT_ID = 'test-project'
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
let otherPrivateJwk: SigningJwk

async function generateSigningKeyPair(kid: string): Promise<{ privateJwk: SigningJwk; publicJwk: SigningJwk }> {
  // `generateKey`'s ambient Workers-runtime type returns `CryptoKey | CryptoKeyPair` regardless of
  // algorithm (no overload discrimination) — RSASSA-PKCS1-v1_5 always yields a key *pair*.
  const keyPair = (await crypto.subtle.generateKey(RS256_PARAMS, true, ['sign', 'verify'])) as CryptoKeyPair
  const exportedPrivate = (await crypto.subtle.exportKey('jwk', keyPair.privateKey)) as JsonWebKey
  const exportedPublic = (await crypto.subtle.exportKey('jwk', keyPair.publicKey)) as JsonWebKey
  return {
    privateJwk: { ...exportedPrivate, kid },
    publicJwk: { ...exportedPublic, kid },
  }
}

/**
 * Verifies the actual shipped `firebaseAuthMiddleware` (unmodified) against locally-signed tokens
 * instead of the real Firebase JWKS endpoint, by stubbing `fetch` for the `jwks_uri` lookup that
 * `hono/jwk` performs internally — see tasks.md Implementation Notes 2.1/2.2/2.3 for why a real
 * Firebase ID token cannot be scripted in this environment (Google Sign-In only).
 */
beforeAll(async () => {
  const pair = await generateSigningKeyPair(KID)
  privateJwk = pair.privateJwk
  publicJwk = pair.publicJwk

  otherPrivateJwk = (await generateSigningKeyPair(KID)).privateJwk
})

afterEach(() => {
  vi.unstubAllGlobals()
})

function stubJwksFetch(): void {
  vi.stubGlobal(
    'fetch',
    vi.fn(async () => Response.json({ keys: [publicJwk] }))
  )
}

type TestEnv = { Bindings: Env; Variables: { identity: VerifiedIdentity; jwtPayload: Record<string, unknown> } }

function buildApp() {
  const app = new Hono<TestEnv>()
  app.use('*', firebaseAuthMiddleware)
  app.get('/', (c) => c.json({ uid: c.get('identity').uid }))
  return app
}

/** Only `FIREBASE_PROJECT_ID` is exercised by this middleware; the rest of `Env` is unused here. */
function testEnv(): Env {
  return { FIREBASE_PROJECT_ID: PROJECT_ID } as unknown as Env
}

async function signToken(payload: Record<string, unknown>, key: SigningJwk = privateJwk): Promise<string> {
  return sign(payload, key, 'RS256')
}

function validPayload(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  const now = Math.floor(Date.now() / 1000)
  return {
    iss: `https://securetoken.google.com/${PROJECT_ID}`,
    aud: PROJECT_ID,
    sub: 'firebase-uid-123',
    iat: now,
    exp: now + 3600,
    ...overrides,
  }
}

describe('firebaseAuthMiddleware', () => {
  it('should set the verified uid and reach the handler for a valid token', async () => {
    stubJwksFetch()
    const token = await signToken(validPayload())
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(200)
    expect(await res.json()).toEqual({ uid: 'firebase-uid-123' })
  })

  it('should return 401 when the Authorization header is missing (Requirement 1.6, 5.1)', async () => {
    stubJwksFetch()
    const app = buildApp()

    const res = await app.request('/', {}, testEnv())

    expect(res.status).toBe(401)
  })

  it('should return 401 for an expired token', async () => {
    stubJwksFetch()
    const now = Math.floor(Date.now() / 1000)
    const token = await signToken(validPayload({ iat: now - 7200, exp: now - 3600 }))
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(401)
  })

  it('should return 401 when the audience does not match the Firebase project id', async () => {
    stubJwksFetch()
    const token = await signToken(validPayload({ aud: 'some-other-project' }))
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(401)
  })

  it('should return 401 when the issuer does not match the expected Firebase issuer', async () => {
    stubJwksFetch()
    const token = await signToken(validPayload({ iss: 'https://securetoken.google.com/some-other-project' }))
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(401)
  })

  it('should return 401 for a token signed with a key not present in the JWKS (tampered/forged signature)', async () => {
    stubJwksFetch()
    // Signed with a *different* private key than the one whose public JWK is served — same `kid`,
    // so the middleware finds a "matching" JWKS entry by kid but signature verification must fail.
    const token = await signToken(validPayload(), otherPrivateJwk)
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(401)
  })

  it('should return 401 when the token subject (sub) is missing', async () => {
    stubJwksFetch()
    const payload = validPayload()
    delete payload.sub
    const token = await signToken(payload)
    const app = buildApp()

    const res = await app.request('/', { headers: { Authorization: `Bearer ${token}` } }, testEnv())

    expect(res.status).toBe(401)
  })
})
