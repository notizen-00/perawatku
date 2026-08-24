export type ServiceCategory = {
  id: number
  name: string
  slug?: string | null
  description?: string | null
  icon?: string | null
  sort_order?: number | null
  is_active: boolean
  services_count?: number | null
  created_at?: string | null
  updated_at?: string | null
}

export type CreateServiceCategoryPayload = {
  name: string
  slug?: string
  description?: string
  icon?: string
  sort_order?: number
  is_active?: boolean
}

export type UpdateServiceCategoryPayload = Partial<CreateServiceCategoryPayload>

export type ApiListResponse<T> = {
  message: string
  data: T
}

export type ListServiceCategoriesQuery = {
  search?: string
  is_active?: boolean
  page?: number
  per_page?: number
}

export async function listServiceCategories(query: ListServiceCategoriesQuery = {}) {
  return await $fetch<ApiListResponse<ServiceCategory[]>>('/api/admin/service-categories', {
    query
  })
}

export async function getServiceCategory(id: number | string) {
  return await $fetch<{ message: string; data: ServiceCategory }>(`/api/admin/service-categories/${id}`)
}

export async function createServiceCategory(payload: CreateServiceCategoryPayload) {
  return await $fetch<{ message: string; data: ServiceCategory }>('/api/admin/service-categories', {
    method: 'POST',
    body: payload
  })
}

export async function updateServiceCategory(id: number | string, payload: UpdateServiceCategoryPayload) {
  return await $fetch<{ message: string; data: ServiceCategory }>(`/api/admin/service-categories/${id}`, {
    method: 'PATCH',
    body: payload
  })
}

export async function deleteServiceCategory(id: number | string) {
  return await $fetch<{ message: string }>(`/api/admin/service-categories/${id}`, {
    method: 'DELETE'
  })
}

export async function toggleServiceCategoryStatus(id: number | string) {
  return await $fetch<{ message: string; data: ServiceCategory }>(`/api/admin/service-categories/${id}/toggle-status`, {
    method: 'PATCH'
  })
}
