import { defineStore } from 'pinia'
import type { ListPartnersQuery, Partner, PartnerProfession } from '~/services/admin/partners'
import { listPartners } from '~/services/admin/partners'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type AvailabilityFilter = 'all' | 'available' | 'unavailable'
type VerificationFilter = 'all' | 'pending' | 'verified' | 'rejected'

export const usePartnersStore = defineStore('partners', () => {
  const items = ref<Partner[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const pagination = reactive({
    page: 1,
    perPage: 10,
    total: 0,
    lastPage: 1
  })

  const filters = reactive<{
    profession: PartnerProfession | 'all'
    availability: AvailabilityFilter
    verificationStatus: VerificationFilter
    search: string
  }>({
    profession: 'all',
    availability: 'all',
    verificationStatus: 'all',
    search: ''
  })

  const query = computed<ListPartnersQuery>(() => {
    const q: ListPartnersQuery = {}

    if (filters.profession !== 'all') q.profession = filters.profession
    if (filters.search.trim()) q.search = filters.search.trim()
    if (filters.availability === 'available') q.is_available = true
    if (filters.availability === 'unavailable') q.is_available = false
    if (filters.verificationStatus !== 'all') q.verification_status = filters.verificationStatus
    q.page = pagination.page
    q.per_page = pagination.perPage

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null
    try {
      const res = await listPartners(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<Partner>(res.data)
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
      error.value = e?.data?.message || e?.message || 'Gagal memuat data partners.'
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
