import { Hono, type Context } from 'hono'
import { firebaseAuthMiddleware, type VerifiedIdentity } from '../middleware/firebaseAuth'
import { createMemoRepository, type Memo } from './repository'
import { createMemoService, type MemoServiceError } from './service'
import { getSubscriberStatus } from '../billing/revenueCatClient'

type MemosEnv = {
  Bindings: Env
  Variables: { identity: VerifiedIdentity; jwtPayload: Record<string, unknown> }
}

/** design.md's API Data Transfer contract omits userId (the caller only ever receives their own memos). */
type MemoDto = {
  id: string
  content: string
  createdAt: string
  updatedAt: string
}

function toMemoDto(memo: Memo): MemoDto {
  return { id: memo.id, content: memo.content, createdAt: memo.createdAt, updatedAt: memo.updatedAt }
}

function buildService(c: Context<MemosEnv>) {
  const repository = createMemoRepository(c.env.memo_app_db)
  return createMemoService({
    repository,
    freeTierLimit: c.env.FREE_TIER_MEMO_LIMIT,
    getSubscriberStatus: (uid) =>
      getSubscriberStatus(uid, { secretKey: c.env.RC_SECRET_KEY, entitlementId: c.env.RC_ENTITLEMENT_ID }),
  })
}

function errorResponse(error: MemoServiceError): { status: 400 | 403 | 404; body: Record<string, unknown> } {
  switch (error.kind) {
    case 'validation':
      return { status: 400, body: { error: 'validation', message: error.message } }
    case 'forbidden':
      return { status: 403, body: { error: 'forbidden' } }
    case 'not_found':
      return { status: 404, body: { error: 'not_found' } }
    case 'limit_reached':
      return { status: 403, body: { error: 'limit_reached', limit: error.limit } }
  }
}

async function readContent(c: Context<MemosEnv>): Promise<string> {
  const body = await c.req.json<{ content?: unknown }>().catch(() => ({ content: undefined }))
  return typeof body.content === 'string' ? body.content : ''
}

export const memosRoutes = new Hono<MemosEnv>()

memosRoutes.use('*', firebaseAuthMiddleware)

memosRoutes.get('/', async (c) => {
  const service = buildService(c)
  const memos = await service.listMemos(c.get('identity').uid)
  return c.json(memos.map(toMemoDto))
})

memosRoutes.post('/', async (c) => {
  const content = await readContent(c)
  const service = buildService(c)
  const result = await service.createMemo(c.get('identity').uid, content)
  if (!result.ok) {
    const { status, body } = errorResponse(result.error)
    return c.json(body, status)
  }
  return c.json(toMemoDto(result.data), 201)
})

memosRoutes.patch('/:id', async (c) => {
  const content = await readContent(c)
  const service = buildService(c)
  const result = await service.updateMemo(c.get('identity').uid, c.req.param('id'), content)
  if (!result.ok) {
    const { status, body } = errorResponse(result.error)
    return c.json(body, status)
  }
  return c.json(toMemoDto(result.data), 200)
})

memosRoutes.delete('/:id', async (c) => {
  const service = buildService(c)
  const result = await service.deleteMemo(c.get('identity').uid, c.req.param('id'))
  if (!result.ok) {
    const { status, body } = errorResponse(result.error)
    return c.json(body, status)
  }
  return c.body(null, 204)
})
