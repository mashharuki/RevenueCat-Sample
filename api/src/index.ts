import { Hono } from 'hono'
import { handleError } from './errors'
import { memosRoutes } from './memos/routes'

const app = new Hono()

app.get('/health', (c) => c.json({ status: 'ok' }))

app.route('/api/memos', memosRoutes)

app.onError(handleError)

export default app
