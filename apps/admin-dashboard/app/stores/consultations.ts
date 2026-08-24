import { defineStore } from 'pinia'
import type { ConsultationLite, ConsultationStatus, ListConsultationsQuery } from '~/services/admin/consultations'
import { listConsultations } from '~/services/admin/consultations'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = ConsultationStatus | 'all'

export const useConsultationsStore = defineStore('consultations', () => {
  const items = ref<ConsultationLite[]>([])
  const loading = ref(false)
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

  const query = computed<ListConsultationsQuery>(() => {
    const q: ListConsultationsQuery = {}
    if (filters.status !== 'all') q.status = filters.status
    if (filters.search.trim()) q.search = filters.search.trim()
    q.page = pagination.page
    q.per_page = pagination.perPage
    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null
    try {
      const res = await listConsultations(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<ConsultationLite>(res.data)
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
      error.value = e?.data?.message || e?.message || 'Gagal memuat consultations.'
    }
    finally {
      loading.value = false
    }
  }

  return {
    items,
    loading,
    error,
    pagination,
    filters,
    fetch
  }
})
