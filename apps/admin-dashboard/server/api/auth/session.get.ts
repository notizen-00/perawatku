import { backendRequest } from '../../utils/backend'

export default defineEventHandler(async (event): Promise<any> => {
  const data = await backendRequest<any>(event, '/shared/me', { method: 'GET' })
  return data
})
