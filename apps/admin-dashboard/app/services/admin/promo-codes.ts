export type PromoCodeStatus = 'active' | 'inactive'

export type PromoCode = {
  id: number
  name?: string | null
  code: string
  description?: string | null
  discount_type: 'percentage' | 'fixed'
  discount_value: number
  min_transaction?: number | null
  max_discount?: number | null
  valid_from: string
  valid_until: string
  usage_limit?: number | null
  usage_count: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export type CreatePromoCodePayload = {
  name: string
  code: string
  description?: string
  discount_type: 'percentage' | 'fixed'
  discount_value: number
  min_transaction?: number
  max_discount?: number
  valid_from: string
  valid_until: string
  usage_limit?: number
}

export type UpdatePromoCodePayload = Partial<CreatePromoCodePayload> & {
  is_active?: boolean
}

export type ApiListResponse<T> = {
  message: string
  data: T
}

export type ListPromoCodesQuery = {
  search?: string
  is_active?: boolean
  page?: number
  per_page?: number
}

export async function listPromoCodes(query: ListPromoCodesQuery = {}) {
  return await $fetch<ApiListResponse<PromoCode[]>>('/api/admin/promo-codes', {
    query
  })
}

export async function getPromoCode(id: number | string) {
  return await $fetch<{ message: string; data: PromoCode }>(`/api/admin/promo-codes/${id}`)
}

export async function createPromoCode(payload: CreatePromoCodePayload) {
  return await $fetch<{ message: string; data: PromoCode }>('/api/admin/promo-codes', {
    method: 'POST',
    body: payload
  })
}

export async function updatePromoCode(id: number | string, payload: UpdatePromoCodePayload) {
  return await $fetch<{ message: string; data: PromoCode }>(`/api/admin/promo-codes/${id}`, {
    method: 'PATCH',
    body: payload
  })
}

export async function deletePromoCode(id: number | string) {
  return await $fetch<{ message: string }>(`/api/admin/promo-codes/${id}`, {
    method: 'DELETE'
  })
}

export async function togglePromoCodeStatus(id: number | string) {
  return await $fetch<{ message: string; data: PromoCode }>(`/api/admin/promo-codes/${id}/toggle-status`, {
    method: 'PATCH'
  })
}