export type ApiResponse<T> = {
  message: string
  data: T
}

export type PaginationQuery = {
  page?: number
  per_page?: number
}

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'processed'
  | 'shipped'
  | 'delivered'
  | 'cancelled'

export type OrderType = 'resep' | 'non_resep'

export type ListOrdersQuery = {
  status?: OrderStatus
  order_type?: OrderType
  patient_user_id?: number
  pharmacy_id?: number
  search?: string
} & PaginationQuery

export type OrderLite = {
  id: number
  order_code?: string | null
  status?: OrderStatus
  order_type?: OrderType
  total_amount?: number | null
  created_at?: string
  patient?: { id: number, name: string, email: string, phone?: string | null } | null
  pharmacy?: { id: number, profile?: { name?: string | null } | null } | null
}

export type OrderDetail = Record<string, any> & { id: number }

export async function listOrders(query: ListOrdersQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/orders', { query })
}

export async function getOrder(id: number | string) {
  return await $fetch<ApiResponse<OrderDetail>>(`/api/admin/orders/${id}`)
}
