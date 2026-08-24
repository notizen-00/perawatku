export type ServiceBookingFee = {
  id?: number
  transport_distance_threshold_km: number
  transport_fee_per_visit: number
  hospital_meal_fee_per_visit: number
  is_active: boolean
  created_at?: string | null
  updated_at?: string | null
}

export type UpdateServiceBookingFeePayload = Pick<
  ServiceBookingFee,
  | 'transport_distance_threshold_km'
  | 'transport_fee_per_visit'
  | 'hospital_meal_fee_per_visit'
  | 'is_active'
>

type ServiceBookingFeeResponse = {
  message?: string
  data: ServiceBookingFee
}

export async function getServiceBookingFee() {
  return await $fetch<ServiceBookingFeeResponse>('/api/admin/service-booking-fees')
}

export async function updateServiceBookingFee(payload: UpdateServiceBookingFeePayload) {
  return await $fetch<ServiceBookingFeeResponse>('/api/admin/service-booking-fees', {
    method: 'PUT',
    body: payload
  })
}
