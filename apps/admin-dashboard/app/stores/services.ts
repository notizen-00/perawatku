import { defineStore } from 'pinia'
import type {
  CreateServicePayload,
  ListServicesQuery,
  Service,
  ServiceType,
  UpdateServicePayload
} from '~/services/admin/services'
import {
  createService,
  deleteService,
  listServices,
  toggleServiceStatus,
  updateService
} from '~/services/admin/services'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = 'all' | 'active' | 'inactive'

export const useServicesStore = defineStore('services', () => {
  const items = ref<Service[]>([])
  const loading = ref(false)
  const saving = ref(false)
  const error = ref<string | null>(null)

  const pagination = reactive({
    page: 1,
    perPage: 10,
    total: 0,
    lastPage: 1
  })

  const filters = reactive<{
    status: StatusFilter
    search: string
    serviceCategoryId: number | null
    serviceType: ServiceType | 'all'
  }>({
    status: 'all',
    search: '',
    serviceCategoryId: null,
    serviceType: 'all'
  })

  const query = computed<ListServicesQuery>(() => {
    const q: ListServicesQuery = {
      page: pagination.page,
      per_page: pagination.perPage
    }

    if (filters.search.trim()) q.search = filters.search.trim()
    if (filters.serviceCategoryId) q.service_category_id = filters.serviceCategoryId
    if (filters.serviceType !== 'all') q.service_type = filters.serviceType
    if (filters.status === 'active') q.is_active = true
    if (filters.status === 'inactive') q.is_active = false

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null

    try {
      const res = await listServices(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<Service>(res.data)

      items.value = rows

      if (meta) {
        pagination.page = meta.current_page
        pagination.perPage = meta.per_page
        pagination.total = meta.total
        pagination.lastPage = meta.last_page
      }
      else {
        pagination.total = rows.length
        pagination.lastPage = 1
      }
    }
    catch (e: any) {
      items.value = []
      error.value = e?.data?.message || e?.message || 'Gagal memuat data layanan.'
    }
    finally {
      loading.value = false
    }
  }

  async function create(payload: CreateServicePayload) {
    saving.value = true
    try {
      await createService(payload)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function update(id: number | string, payload: UpdateServicePayload) {
    saving.value = true
    try {
      await updateService(id, payload)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function remove(id: number | string) {
    saving.value = true
    try {
      await deleteService(id)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function toggleStatus(id: number | string) {
    await toggleServiceStatus(id)
    await fetch()
    return true
  }

  return {
    items,
    loading,
    saving,
    error,
    pagination,
    filters,
    fetch,
    create,
    update,
    remove,
    toggleStatus
  }
})
