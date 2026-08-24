export type ApiResponse<T> = {
  message?: string
  success?: boolean
  data: T
}

export type ReportDateQuery = {
  from?: string
  to?: string
}

export type OrdersReportQuery = ReportDateQuery & {
  status?: string
  patient_user_id?: number
  pharmacy_id?: number
}

export type CustomersReportQuery = ReportDateQuery

export type ProfitLossReportQuery = ReportDateQuery

export type ListTransactionsQuery = {
  search?: string
  page?: number
  per_page?: number
}

export type ListBalancesQuery = {
  status?: string
  search?: string
  page?: number
  per_page?: number
}

export type ListBalanceTransactionsQuery = {
  type?: string
  status?: string
  user_id?: number
  from_date?: string
  to_date?: string
  page?: number
  per_page?: number
}

export type ListJournalsQuery = ReportDateQuery & {
  status?: 'draft' | 'posted' | 'void' | string
  page?: number
  per_page?: number
}

export type ReportPayload = Record<string, any>

export async function getOrdersReport(query: OrdersReportQuery = {}) {
  return await $fetch<ApiResponse<ReportPayload>>('/api/admin/reports/orders', { query })
}

export async function getCustomersReport(query: CustomersReportQuery = {}) {
  return await $fetch<ApiResponse<ReportPayload>>('/api/admin/reports/customers', { query })
}

export async function getProfitLossReport(query: ProfitLossReportQuery = {}) {
  return await $fetch<ApiResponse<ReportPayload>>('/api/admin/reports/profit-loss', { query })
}

export async function listTransactions(query: ListTransactionsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/transactions', { query })
}

export async function listBalances(query: ListBalancesQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/balance', { query })
}

export async function listBalanceTransactions(query: ListBalanceTransactionsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/balance/transactions', { query })
}

export async function getUserBalance(userId: number | string) {
  return await $fetch<ApiResponse<any>>(`/api/admin/balance/users/${userId}`)
}

export async function getUserBalanceHistory(userId: number | string, query: Pick<ListBalanceTransactionsQuery, 'type' | 'status' | 'per_page' | 'page'> = {}) {
  return await $fetch<ApiResponse<any>>(`/api/admin/balance/users/${userId}/history`, { query })
}

export async function listJournals(query: ListJournalsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/journals', { query })
}
