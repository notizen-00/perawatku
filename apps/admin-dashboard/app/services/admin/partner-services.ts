export type ApiResponse<T> = {
  message: string
  data: T
}

export type ListPartnerServicesQuery = {
  partner_user_id?: number
  service_id?: number
  is_active?: boolean
  is_verified?: boolean
  search?: string
  page?: number
  per_page?: number
}

export type PartnerServiceLite = {
  id: number
  is_active?: boolean
  is_verified?: boolean
  notes?: string | null
  created_at?: string
  partner?: { id: number, name: string, email: string, partner_profile?: { profession?: string } | null } | null
  service?: { id: number, name?: string | null, service_type?: string | null } | null
}

export type VerifyPartnerServicePayload = {
  is_verified: boolean
  is_active?: boolean
  notes?: string | null
}

export async function listPartnerServices(query: ListPartnerServicesQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/partner-services', { query })
}

export async function verifyPartnerService(id: number | string, payload: VerifyPartnerServicePayload) {
  return await $fetch<ApiResponse<PartnerServiceLite>>(`/api/admin/service-applications/${id}/verify`, {
    method: 'PATCH',
    body: payload
  })
}
