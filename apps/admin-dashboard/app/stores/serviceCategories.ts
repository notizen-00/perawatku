import { defineStore } from 'pinia'
import type {
  CreateServiceCategoryPayload,
  ListServiceCategoriesQuery,
  ServiceCategory,
  UpdateServiceCategoryPayload
} from '~/services/admin/services-categories'
import {
  createServiceCategory,
  deleteServiceCategory,
  listServiceCategories,
  toggleServiceCategoryStatus,
  updateServiceCategory
} from '~/services/admin/services-categories'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = 'all' | 'active' | 'inactive'

export const useServiceCategoriesStore = defineStore('serviceCategories', () => {
  const items = ref<ServiceCategory[]>([])
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
  }>({
    status: 'all',
    search: ''
  })

  const query = computed<ListServiceCategoriesQuery>(() => {
    const q: ListServiceCategoriesQuery = {
      page: pagination.page,
      per_page: pagination.perPage
    }

    if (filters.search.trim()) q.search = filters.search.trim()
    if (filters.status === 'active') q.is_active = true
    if (filters.status === 'inactive') q.is_active = false

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null

    try {
      const res = await listServiceCategories(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<ServiceCategory>(res.data)

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
      error.value = e?.data?.message || e?.message || 'Gagal memuat data kategori layanan.'
    }
    finally {
      loading.value = false
    }
  }

  async function create(payload: CreateServiceCategoryPayload) {
    saving.value = true
    try {
      await createServiceCategory(payload)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function update(id: number | string, payload: UpdateServiceCategoryPayload) {
    saving.value = true
    try {
      await updateServiceCategory(id, payload)
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
      await deleteServiceCategory(id)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function toggleStatus(id: number | string) {
    await toggleServiceCategoryStatus(id)
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
