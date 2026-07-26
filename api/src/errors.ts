import { HTTPException } from 'hono/http-exception'
import type { Context } from 'hono'

/**
 * Formats any error that escapes route-level handling (e.g. `FirebaseAuthMiddleware` throwing on
 * an invalid token, or an unexpected exception) into the same `{ error, message? }` JSON shape
 * `routes.ts` already uses for expected `MemoServiceError`s, so every response the client sees —
 * expected or not — has a consistent, parseable body (design.md Error Handling; Requirement 5.2:
 * failures must never be silent).
 */
export function handleError(err: unknown, c: Context): Response {
  if (err instanceof HTTPException) {
    return c.json({ error: statusToErrorKind(err.status), message: err.message }, err.status)
  }

  console.error('Unhandled error', err)
  return c.json({ error: 'internal_error' }, 500)
}

function statusToErrorKind(status: number): string {
  switch (status) {
    case 401:
      return 'unauthorized'
    case 403:
      return 'forbidden'
    case 404:
      return 'not_found'
    default:
      return status >= 500 ? 'internal_error' : 'bad_request'
  }
}
