import { getCookie, getHeader, setHeader, setResponseStatus } from 'h3'
import { getBackendBase } from '../../../../../../utils/backend'

function joinUrl(base: string, path: string) {
  return `${base.replace(/\/+$/, '')}/${path.replace(/^\/+/, '')}`
}

function guessContentType(path: string) {
  const ext = path.split('?')[0]?.split('#')[0]?.split('.').pop()?.toLowerCase()
  if (ext === 'jpg' || ext === 'jpeg') return 'image/jpeg'
  if (ext === 'png') return 'image/png'
  if (ext === 'webp') return 'image/webp'
  if (ext === 'gif') return 'image/gif'
  if (ext === 'svg') return 'image/svg+xml'
  if (ext === 'avif') return 'image/avif'
  return 'application/octet-stream'
}

export default defineEventHandler(async (event) => {
  const user = String(event.context.params?.user || '')
  const type = String(event.context.params?.type || '')

  const apiBase = getBackendBase(event)
  const url = joinUrl(
    apiBase,
    `/shared/secure-image/partners/${encodeURIComponent(user)}/documents/${encodeURIComponent(type)}`
  )

  const headerAuthorization = getHeader(event, 'authorization')
  const cookieToken = getCookie(event, 'auth.token')
  const authorization = headerAuthorization || (cookieToken ? (cookieToken.includes(' ') ? cookieToken : `Bearer ${cookieToken}`) : undefined)

  const res = await $fetch.raw<ArrayBuffer>(url, {
    responseType: 'arrayBuffer',
    headers: {
      ...(authorization ? { Authorization: authorization } : {})
    }
  })

  setResponseStatus(event, res.status)

  const upstreamType = res.headers.get('content-type')
  setHeader(event, 'Content-Type', upstreamType || guessContentType(type))

  const cacheControl = res.headers.get('cache-control')
  if (cacheControl) setHeader(event, 'Cache-Control', cacheControl)

  const body = res._data ?? new ArrayBuffer(0)
  return new Uint8Array(body)
})
