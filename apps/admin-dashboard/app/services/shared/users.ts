export type ApiResponse<T> = {
  message: string
  data: T
}

export type PartnerProfession = 'dokter' | 'perawat' | 'bidan'

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

export type SharedUser = {
  id: number
  name: string
  email: string
  phone?: string | null
  role?: string
  partner_profile?: PartnerProfile | null
  patient_profile?: any
  courier_profile?: any
  pharmacy?: any
}

export async function getUser(id: number | string) {
  return await $fetch<ApiResponse<SharedUser>>(`/api/shared/users/${id}`)
}

