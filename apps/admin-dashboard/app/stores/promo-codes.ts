import { defineStore } from 'pinia'
import type { PromoCode, ListPromoCodesQuery } from '~/services/admin/promo-codes'
import { listPromoCodes, togglePromoCodeStatus } from '~/services/admin/promo-codes'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = 'all' | 'active' | 'inactive'

export const usePromoCodesStore = defineStore('promoCodes', () => {
  const items = ref<PromoCode[]>([])
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

  const query = computed<ListPromoCodesQuery>(() => {
    const q: ListPromoCodesQuery = {}

    if (filters.search.trim()) q.search = filters.search.trim()
    if (filters.status === 'active') q.is_active = true
    if (filters.status === 'inactive') q.is_active = false
    q.page = pagination.page
    q.per_page = pagination.perPage

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null
    try {
      const res = await listPromoCodes(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<PromoCode>(res.data)
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
      error.value = e?.data?.message || e?.message || 'Gagal memuat data promo code.'
    }
    finally {
      loading.value = false
    }
  }

  async function toggleStatus(id: number | string) {
    try {
      await togglePromoCodeStatus(id)
      await fetch()
      return true
    }
    catch (e: any) {
      return false
    }
  }

  return {
    items,
    loading,
    error,
    pagination,
    filters,
    fetch,
    toggleStatus
  }
})