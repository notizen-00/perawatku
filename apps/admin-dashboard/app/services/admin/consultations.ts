export type ApiResponse<T> = {
  message: string
  data: T
}

export type ConsultationStatus =
  | 'pending'
  | 'confirmed'
  | 'ongoing'
  | 'completed'
  | 'cancelled'

export type ListConsultationsQuery = {
  status?: ConsultationStatus
  partner_user_id?: number
  patient_user_id?: number
  service_type?: string
  search?: string
  page?: number
  per_page?: number
}

export type ConsultationLite = {
  id: number
  consultation_code?: string | null
  status?: ConsultationStatus
  service_type?: string | null
  created_at?: string
  patient?: { id: number, name: string, email: string } | null
  partner?: { id: number, name: string, email: string, partner_profile?: { profession?: string } | null } | null
}

export type ConsultationDetail = Record<string, any> & { id: number }

export async function listConsultations(query: ListConsultationsQuery = {}) {
  return await $fetch<ApiResponse<any>>('/api/admin/consultations', { query })
}

export async function getConsultation(id: number | string) {
  return await $fetch<ApiResponse<ConsultationDetail>>(`/api/admin/consultations/${id}`)
}
