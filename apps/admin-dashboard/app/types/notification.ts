export interface Notification {
  id: number
  user_id: number
  type: string
  title: string
  body?: string | null
  action_url?: string | null
  reference_type?: string | null
  reference_id?: number | null
  data?: Record<string, any> | null
  read_at?: string | null
  created_at: string
}
