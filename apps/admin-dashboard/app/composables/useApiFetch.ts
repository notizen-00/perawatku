export function useApiFetch<T>(
  path: string,
  // Nuxt's `$fetch` options are slightly different from `ofetch`'s types
  // (Nitro extends & narrows them), so we keep it loose here.
  options: Record<string, any> = {}
) {
  const config = useRuntimeConfig()
  const { token } = useAuthState()

  const baseURL = config.public.apiBase || config.public.auth?.baseURL || ''

  return $fetch<T>(path, {
    baseURL,
    credentials: 'omit',
    ...options,
    headers: {
      ...(options.headers || {}),
      ...(token.value ? { Authorization: `Bearer ${token.value}` } : {})
    }
  })
}
