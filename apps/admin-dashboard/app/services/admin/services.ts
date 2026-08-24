import type { ServiceCategory } from './services-categories'

export const SERVICE_IMAGE_NOT_AVAILABLE = 'Image not available'

export type ServiceType =
  | 'consultation'
  | 'procedure'
  | 'caregiver'
  | 'homecare'
  | 'dokter_homecare'
  | 'perawat_homecare'
  | 'bidan_homecare'
  | 'konsultasi_tindakan'
  | string

export type ServiceMode = 'chat' | 'voice' | 'video' | 'visit'

export type Service = {
  id: number
  service_code?: string | null
  service_category_id?: number | null
  category_id?: number | null
  category?: ServiceCategory | null
  name: string
  slug?: string | null
  description?: string | null
  service_type?: ServiceType | null
  service_mode?: ServiceMode | null
  base_price?: number | null
  price?: number | null
  duration_minutes?: number | null
  icon?: string | null
  requires_address?: boolean | null
  requires_schedule?: boolean | null
  requires_matchmaking?: boolean | null
  is_homecare?: boolean | null
  sort_order?: number | null
  is_active: boolean
  image?: string | null
  image_url?: string | null
  created_at?: string | null
  updated_at?: string | null
}

export type CreateServicePayload = {
  remove_image: boolean
  service_code?: string
  service_category_id?: number
  category_id?: number
  name: string
  slug?: string
  description?: string
  service_type?: ServiceType
  service_mode?: ServiceMode
  category?: string
  base_price?: number
  price?: number
  duration_minutes?: number
  icon?: string
  requires_address?: boolean
  requires_schedule?: boolean
  requires_matchmaking?: boolean
  is_homecare?: boolean
  sort_order?: number
  is_active?: boolean
  image?: File | null
  image_path?: string
}

export type UpdateServicePayload = Partial<CreateServicePayload>

export type ApiListResponse<T> = {
  message: string
  data: T
}

export type ListServicesQuery = {
  search?: string
  service_category_id?: number
  category_id?: number
  service_type?: ServiceType
  is_active?: boolean
  page?: number
  per_page?: number
}

function hasServiceImage(value?: string | null) {
  return typeof value === 'string' && value.trim().length > 0
}

export function normalizeService(service: Service): Service {
  if (hasServiceImage(service.image) || hasServiceImage(service.image_url)) {
    return service
  }

  return {
    ...service,
    image: SERVICE_IMAGE_NOT_AVAILABLE
  }
}

function normalizeServicePayload<T>(payload: T): T {
  if (Array.isArray(payload)) {
    return payload.map(item => normalizeService(item as Service)) as T
  }

  if (payload && typeof payload === 'object' && Array.isArray((payload as any).data)) {
    return {
      ...(payload as any),
      data: (payload as any).data.map((item: Service) => normalizeService(item))
    }
  }

  return payload
}

function normalizeServiceResponse<T extends { data: any }>(response: T): T {
  return {
    ...response,
    data: normalizeServicePayload(response.data)
  }
}

export async function listServices(query: ListServicesQuery = {}) {
  const response = await $fetch<ApiListResponse<Service[]>>('/api/admin/services', {
    query
  })

  return normalizeServiceResponse(response)
}

export async function getService(id: number | string) {
  const response = await $fetch<{ message: string; data: Service }>(`/api/admin/services/${id}`)

  return normalizeServiceResponse(response)
}

function buildServiceFormData(payload: CreateServicePayload | UpdateServicePayload) {
  const formData = new FormData()

  for (const [key, value] of Object.entries(payload)) {
    if (value === undefined || value === null) continue

    if (key === 'image') {
      if (value instanceof File) formData.append('image', value)
      continue
    }

    if (typeof value === 'boolean') {
      formData.append(key, value ? '1' : '0')
      continue
    }

    formData.append(key, String(value))
  }

  return formData
}

export async function createService(payload: CreateServicePayload) {
  const useMultipart = !!payload.image

  const response = await $fetch<{ message: string; data: Service }>('/api/admin/services', {
    method: 'POST',
    body: useMultipart ? buildServiceFormData(payload) : payload
  })

  return normalizeServiceResponse(response)
}

export async function updateService(id: number | string, payload: UpdateServicePayload) {
  const useMultipart = !!payload.image

  const response = await $fetch<{ message: string; data: Service }>(`/api/admin/services/${id}`, {
    method: 'PATCH',
    body: useMultipart ? buildServiceFormData(payload) : payload
  })

  return normalizeServiceResponse(response)
}

export async function deleteService(id: number | string) {
  return await $fetch<{ message: string }>(`/api/admin/services/${id}`, {
    method: 'DELETE'
  })
}

export async function toggleServiceStatus(id: number | string) {
  const response = await $fetch<{ message: string; data: Service }>(`/api/admin/services/${id}/toggle-status`, {
    method: 'PATCH'
  })

  return normalizeServiceResponse(response)
}
