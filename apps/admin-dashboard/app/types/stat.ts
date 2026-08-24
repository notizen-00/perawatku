export interface Stat {
  title: string
  icon: string
  value: number | string
  /** Optional secondary badge text, e.g. a completed/pending sub-count. Omit
   * rather than fabricate a fake period-over-period percentage. */
  badge?: string
  to?: string
}

