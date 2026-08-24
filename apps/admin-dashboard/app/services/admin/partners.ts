export type PartnerProfession = 'dokter' | 'perawat' | 'bidan'

export type ListPartnersQuery = {
  profession?: PartnerProfession
  search?: string
  is_available?: boolean
  verification_status?: 'pending' | 'verified' | 'rejected'
  page?: number
  per_page?: number
}

export type ApiListResponse<T> = {
  message: string
  data: T
}

export type PartnerProfile = {
  profession?: PartnerProfession
  specialization?: string | null
  work_location?: string | null
  license_number?: string | null
  is_available?: boolean
  verification_status?: 'pending' | 'verified' | 'rejected'
  str_photo_path?: string | null
  ktp_photo_path?: string | null
}

export type Partner = {
  id: number
  name: string
  email: string
  phone?: string | null
  partner_profile?: PartnerProfile | null
  partner_consultations_count?: number
  partner_services_count?: number
  partner_service_bookings_count?: number
}

export async function listPartners(query: ListPartnersQuery = {}) {
  return await $fetch<ApiListResponse<any>>('/api/admin/partners', {
    query
  })
}
