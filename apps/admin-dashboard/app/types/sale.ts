export type SaleStatus = 'paid' | 'failed' | 'refunded'

export interface Sale {
  id: string
  date: string
  status: SaleStatus
  email: string
  amount: number
}

