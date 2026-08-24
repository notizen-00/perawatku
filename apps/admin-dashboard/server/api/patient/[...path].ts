import { backendRequest } from '../../utils/backend'

export default defineEventHandler(async (event): Promise<any> => {
  const params = event.context.params?.path
  const tail = Array.isArray(params) ? params.join('/') : (params || '')
  return await backendRequest<any>(event, `/patient/${tail}`)
})

