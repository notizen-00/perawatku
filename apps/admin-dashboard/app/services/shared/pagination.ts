export type LaravelPaginationMeta = {
  current_page: number
  last_page: number
  per_page: number
  total: number
}

// Supports common Laravel shapes:
// - { data: T[], meta: { current_page, last_page, per_page, total }, links?: ... }
// - { data: T[], current_page, last_page, per_page, total, ... }
export type LaravelPaginated<T> = {
  data: T[]
  meta?: Partial<LaravelPaginationMeta>
  links?: any
  current_page?: number
  last_page?: number
  per_page?: number
  total?: number
}

export function normalizeLaravelPaginated<T>(payload: any): { items: T[], meta: LaravelPaginationMeta | null } {
  if (!payload) return { items: [], meta: null }

  if (Array.isArray(payload)) {
    return { items: payload as T[], meta: null }
  }

  const items = Array.isArray(payload.data) ? payload.data as T[] : []

  const metaLike = payload.meta || payload
  const current_page = Number(metaLike?.current_page)
  const last_page = Number(metaLike?.last_page)
  const per_page = Number(metaLike?.per_page)
  const total = Number(metaLike?.total)

  if ([current_page, last_page, per_page, total].every(n => Number.isFinite(n) && n >= 0)) {
    return {
      items,
      meta: {
        current_page,
        last_page,
        per_page,
        total
      }
    }
  }

  return { items, meta: null }
}

