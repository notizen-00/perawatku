import { defineStore } from 'pinia'
import type { ListOrdersQuery, OrderLite, OrderStatus, OrderType } from '~/services/admin/orders'
import { listOrders } from '~/services/admin/orders'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type StatusFilter = OrderStatus | 'all'
type TypeFilter = OrderType | 'all'

export const useOrdersStore = defineStore('orders', () => {
  const items = ref<OrderLite[]>([])
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
    orderType: TypeFilter
    search: string
  }>({
    status: 'all',
    orderType: 'all',
    search: ''
  })

  const query = computed<ListOrdersQuery>(() => {
    const q: ListOrdersQuery = {}
    if (filters.status !== 'all') q.status = filters.status
    if (filters.orderType !== 'all') q.order_type = filters.orderType
    if (filters.search.trim()) q.search = filters.search.trim()
    q.page = pagination.page
    q.per_page = pagination.perPage
    return q
  })

  async function fetch() {
    loading.value = true
    error.value = null
    try {
      const res = await listOrders(query.value)
      const { items: rows, meta } = normalizeLaravelPaginated<OrderLite>(res.data)
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
      error.value = e?.data?.message || e?.message || 'Gagal memuat orders.'
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
