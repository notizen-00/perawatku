import { backendRequest } from '../../utils/backend'

export default defineEventHandler(async (event): Promise<any> => {
  const payload = await readBody(event)

  const data = await backendRequest<any>(event, '/admin/login', {
    method: 'POST',
    body: payload
  })

  const token =
    data?.token ||
    data?.access_token ||
    data?.user_api_token ||
    data?.data?.token ||
    data?.data?.access_token ||
    data?.data?.user_api_token

  if (!token) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Response login tidak mengandung token (expected key: user_api_token / token / access_token)'
    })
  }

  return {
    token,
    ...data
  }
})
