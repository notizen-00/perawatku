import { backendRequest } from '../utils/backend'

export default defineEventHandler(async (event): Promise<any> => {
  return await backendRequest<any>(event, '/members')
})
