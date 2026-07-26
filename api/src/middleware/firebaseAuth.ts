import { jwk } from 'hono/jwk'
import { HTTPException } from 'hono/http-exception'
import type { Context, Next } from 'hono'

const FIREBASE_JWKS_URI =
  'https://www.googleapis.com/service_accounts/v1/metadata/x509/securetoken@system.gserviceaccount.com'

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
