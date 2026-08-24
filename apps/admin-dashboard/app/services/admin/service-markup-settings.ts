import type { Service } from './services'

export type ApiResponse<T> = {
  message: string
  data: T
}

export type MarkupType = 'percentage' | 'fixed'

export type ServiceMarkupSetting = {
  id: number
  service_id: number
  service?: Service | null
  markup_type: MarkupType
  markup_value: number
  min_final_price?: number | null
  priority?: number | null
  notes?: string | null
  is_active: boolean
  created_at?: string | null
  updated_at?: string | null
}

export type CreateServiceMarkupSettingPayload = {
  service_id: number
  markup_type: MarkupType
  markup_value: number
  min_final_price?: number | null
  priority?: number | null
  notes?: string | null
  is_active?: boolean
}

export type UpdateServiceMarkupSettingPayload = Partial<CreateServiceMarkupSettingPayload>

export type ListServiceMarkupSettingsQuery = {
  service_id?: number
  is_active?: boolean
  page?: number
  per_page?: number
}

export async function listServiceMarkupSettings(query: ListServiceMarkupSettingsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/service-markup', { query })
}

export async function createServiceMarkupSetting(payload: CreateServiceMarkupSettingPayload) {
  return await $fetch<ApiResponse<ServiceMarkupSetting>>('/api/admin/service-markup', {
    method: 'POST',
    body: payload
  })
}

export async function updateServiceMarkupSetting(
  id: number | string,
  payload: UpdateServiceMarkupSettingPayload
) {
  return await $fetch<ApiResponse<ServiceMarkupSetting>>(`/api/admin/service-markup/${id}`, {
    method: 'PATCH',
    body: payload
  })
}

export async function deleteServiceMarkupSetting(id: number | string) {
  return await $fetch<{ message: string }>(`/api/admin/service-markup/${id}`, {
    method: 'DELETE'
  })
}

export async function toggleServiceMarkupSettingStatus(id: number | string, isActive: boolean) {
  return await $fetch<ApiResponse<ServiceMarkupSetting>>(`/api/admin/service-markup/${id}/toggle-status`, {
    method: 'PATCH',
    body: { is_active: isActive }
  })
}
