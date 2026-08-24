import type { H3Event } from 'h3'
import { createError, getCookie, getHeader, getMethod, getQuery, readBody, readRawBody } from 'h3'

function joinUrl(base: string, path: string) {
  return `${base.replace(/\/+$/, '')}/${path.replace(/^\/+/, '')}`
}

export function getBackendBase(event: H3Event) {
  const config = useRuntimeConfig(event)
  const apiBase = config.public.apiBase
  if (!apiBase) {
    throw createError({
      statusCode: 500,
      statusMessage: 'NUXT_PUBLIC_API_BASE belum diset (contoh: https://domain.com/api)'
    })
  }
  return apiBase as string
}

export async function backendRequest<T>(
  event: H3Event,
  path: string,
  init: { method?: string, body?: any, query?: Record<string, any> } = {}
): Promise<T> {
  const base = getBackendBase(event)
  const url = joinUrl(base, path)

  const method = (init.method || getMethod(event) || 'GET').toUpperCase()
  const headerAuthorization = getHeader(event, 'authorization')
  const cookieToken = getCookie(event, 'auth.token')
  const authorization = headerAuthorization || (cookieToken ? (cookieToken.includes(' ') ? cookieToken : `Bearer ${cookieToken}`) : undefined)

  const contentType = getHeader(event, 'content-type') || ''
  const isMultipart = contentType.toLowerCase().includes('multipart/form-data')

  let body: any
  const headers: Record<string, string> = {}

  if (init.body !== undefined) {
    body = init.body
  }
  else if (method === 'GET' || method === 'HEAD') {
    body = undefined
  }
  else if (isMultipart) {
    // Forward raw multipart (incl. uploaded files) with its original boundary
    // `false` is required here so H3 returns a Buffer. Reading multipart as
    // UTF-8 text corrupts binary files and makes Laravel's MIME detection fail.
    const raw = await readRawBody(event, false).catch(() => undefined)
    if (raw) {
      body = raw
      headers['content-type'] = contentType
    }
  }
  else {
    body = await readBody(event).catch(() => undefined)
  }

  const query = init.query ?? getQuery(event)

  return await $fetch<T>(url, {
    method: method as any,
    query,
    body,
    headers: {
      ...headers,
      ...(authorization ? { Authorization: authorization } : {})
    }
  })
}
