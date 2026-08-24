import { defineStore } from 'pinia'
import type {
  ListServiceBookingsQuery,
  ServiceBookingLite,
  ServiceBookingStatus
} from '~/services/admin/service-bookings'
import { listServiceBookings } from '~/services/admin/service-bookings'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = ServiceBookingStatus | 'all'

export const useServiceBookingsStore = defineStore('serviceBookings', () => {
  const items = ref<ServiceBookingLite[]>([])
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
    serviceId: number | null
    patientUserId: number | null
    assignedPartnerUserId: number | null
    search: string
  }>({
    status: 'all',
    serviceId: null,
    patientUserId: null,
    assignedPartnerUserId: null,
    search: ''
  })

  const query = computed<ListServiceBookingsQuery>(() => {
    const q: ListServiceBookingsQuery = {
      page: pagination.page,
      per_page: pagination.perPage
    }

    if (filters.status !== 'all') q.status = filters.status
    if (filters.serviceId) q.service_id = filters.serviceId
    if (filters.patientUserId) q.patient_user_id = filters.patientUserId
    if (filters.assignedPartnerUserId) q.assigned_partner_user_id = filters.assignedPartnerUserId
    if (filters.search.trim()) q.search = filters.search.trim()

    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null

    try {
      const res = await listServiceBookings(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<ServiceBookingLite>(res.data)

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
      error.value = e?.data?.message || e?.message || 'Gagal memuat service bookings.'
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
