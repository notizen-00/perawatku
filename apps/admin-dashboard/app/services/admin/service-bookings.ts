export type ApiResponse<T> = {
  message: string
  data: T
}

export type ServiceBookingStatus =
  | 'pending'
  | 'confirmed'
  | 'assigned'
  | 'ongoing'
  | 'completed'
  | 'cancelled'
  | string

export type ListServiceBookingsQuery = {
  status?: ServiceBookingStatus
  service_id?: number
  patient_user_id?: number
  assigned_partner_user_id?: number
  search?: string
  page?: number
  per_page?: number
}

export type ServiceBookingLite = Record<string, any> & {
  id: number
  booking_code?: string | null
  service_booking_code?: string | null
  status?: ServiceBookingStatus | null
  scheduled_at?: string | null
  booking_date?: string | null
  start_date?: string | null
  created_at?: string | null
  total_amount?: number | string | null
  final_price?: number | string | null
  service?: { id: number, name?: string | null, service_type?: string | null } | null
  patient?: { id: number, name?: string | null, email?: string | null, phone?: string | null } | null
  assigned_partner?: {
    id: number
    name?: string | null
    email?: string | null
    partner_profile?: { profession?: string | null } | null
  } | null
}

export async function listServiceBookings(query: ListServiceBookingsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/service-bookings', { query })
}
