import { jwk } from 'hono/jwk'
import { HTTPException } from 'hono/http-exception'
import type { Context, Next } from 'hono'

/**
 * `hono/jwk` requires a real JWKS document (`{ keys: [...] }`). The similarly-named
 * `.../x509/securetoken@system.gserviceaccount.com` endpoint serves the *same* keys but as raw
 * X.509 PEM certificates (`{ <kid>: "-----BEGIN CERTIFICATE-----..." }`), which has no `keys`
 * field and makes `hono/jwk` throw `invalid JWKS response. "keys" field is missing` for every
 * real Firebase ID token — this only surfaces with a real signed-in user hitting the deployed
 * Worker, since local verification tests use a locally-generated JWKS instead of this URL.
 */
const FIREBASE_JWKS_URI =
  'https://www.googleapis.com/service_accounts/v1/metadata/jwk/securetoken@system.gserviceaccount.com'

export type VerifiedIdentity = {
  uid: string
}

type FirebaseAuthEnv = {
  Bindings: Env
  Variables: { identity: VerifiedIdentity; jwtPayload: Record<string, unknown> }
}

export const firebaseAuthMiddleware = (c: Context<FirebaseAuthEnv>, next: Next): Promise<Response | void> => {
  const projectId = c.env.FIREBASE_PROJECT_ID

  const verifyJwk = jwk({
    jwks_uri: FIREBASE_JWKS_URI,
    alg: ['RS256'],
    verification: {
      iss: `https://securetoken.google.com/${projectId}`,
      aud: projectId,
    },
  })

  return verifyJwk(c, async () => {
    const payload = c.get('jwtPayload')
    const sub = payload?.sub

    if (typeof sub !== 'string' || sub.length === 0) {
      throw new HTTPException(401, { message: 'token subject is missing' })
    }

    c.set('identity', { uid: sub })
    await next()
  })
}
