import { defineStore } from 'pinia'
import type { ListPartnerServicesQuery, PartnerServiceLite } from '~/services/admin/partner-services'
import { listPartnerServices, verifyPartnerService } from '~/services/admin/partner-services'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type TriState = 'all' | 'true' | 'false'

export const usePartnerServiceApplicationsStore = defineStore('partnerServiceApplications', () => {
  const items = ref<PartnerServiceLite[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const actionLoadingIds = ref<Record<number, boolean>>({})
  const pagination = reactive({
    page: 1,
    perPage: 10,
    total: 0,
    lastPage: 1
  })

  const filters = reactive<{
    verified: TriState
    active: TriState
    search: string
  }>({
    verified: 'all',
    active: 'all',
    search: ''
  })

  const query = computed<ListPartnerServicesQuery>(() => {
    const q: ListPartnerServicesQuery = {}
    if (filters.verified !== 'all') q.is_verified = filters.verified === 'true'
    if (filters.active !== 'all') q.is_active = filters.active === 'true'
    if (filters.search.trim()) q.search = filters.search.trim()
    q.page = pagination.page
    q.per_page = pagination.perPage
    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null
    try {
      const res = await listPartnerServices(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<PartnerServiceLite>(res.data)
      items.value = rows
      if (meta) {
        pagination.page = meta.current_page
        pagination.perPage = meta.per_page
        pagination.total = meta.total
        pagination.lastPage = meta.last_page
      }
    }
    catch (e: any) {
      items.value = []
      error.value = e?.data?.message || e?.message || 'Gagal memuat service applications.'
    }
    finally {
      loading.value = false
    }
  }

  async function setVerified(id: number, isVerified: boolean) {
    actionLoadingIds.value[id] = true
    try {
      const res = await verifyPartnerService(id, { is_verified: isVerified })
      const idx = items.value.findIndex(i => i.id === id)
      if (idx >= 0) items.value[idx] = res.data
    }
    finally {
      actionLoadingIds.value[id] = false
    }
  }

  return {
    items,
    loading,
    error,
    actionLoadingIds,
    pagination,
    filters,
    fetch,
    setVerified
  }
})
