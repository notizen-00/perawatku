import { defineStore } from 'pinia'
import type {
  CreateServiceMarkupSettingPayload,
  ListServiceMarkupSettingsQuery,
  ServiceMarkupSetting,
  UpdateServiceMarkupSettingPayload
} from '~/services/admin/service-markup-settings'
import {
  createServiceMarkupSetting,
  deleteServiceMarkupSetting,
  listServiceMarkupSettings,
  toggleServiceMarkupSettingStatus,
  updateServiceMarkupSetting
} from '~/services/admin/service-markup-settings'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = 'all' | 'active' | 'inactive'

export const useServiceMarkupSettingsStore = defineStore('serviceMarkupSettings', () => {
  const items = ref<ServiceMarkupSetting[]>([])
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
    serviceId: number | null
  }>({
    status: 'all',
    serviceId: null
  })

  const query = computed<ListServiceMarkupSettingsQuery>(() => {
    const q: ListServiceMarkupSettingsQuery = {
      page: pagination.page,
      per_page: pagination.perPage
    }

    if (filters.serviceId) q.service_id = filters.serviceId
    if (filters.status === 'active') q.is_active = true
    if (filters.status === 'inactive') q.is_active = false

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null

    try {
      const res = await listServiceMarkupSettings(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<ServiceMarkupSetting>(res.data)

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
      error.value = e?.data?.message || e?.message || 'Gagal memuat service markup setting.'
    }
    finally {
      loading.value = false
    }
  }

  async function create(payload: CreateServiceMarkupSettingPayload) {
    saving.value = true
    try {
      await createServiceMarkupSetting(payload)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function update(id: number | string, payload: UpdateServiceMarkupSettingPayload) {
    saving.value = true
    try {
      await updateServiceMarkupSetting(id, payload)
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
      await deleteServiceMarkupSetting(id)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
  }

  async function toggleStatus(item: ServiceMarkupSetting) {
    saving.value = true
    try {
      await toggleServiceMarkupSettingStatus(item.id, !item.is_active)
      await fetch()
      return true
    }
    finally {
      saving.value = false
    }
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
