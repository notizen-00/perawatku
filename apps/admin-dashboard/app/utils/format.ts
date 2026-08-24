type DateLike = string | number | Date | null | undefined

function toDate(value: DateLike): Date | null {
  if (value == null) return null
  const d = value instanceof Date ? value : new Date(value)
  return Number.isNaN(d.getTime()) ? null : d
}

export function formatDate(
  value: DateLike,
  options: Intl.DateTimeFormatOptions = {},
  locale = 'id-ID'
) {
  const d = toDate(value)
  if (!d) return '-'

  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    ...options
  }).format(d)
}

export function formatDateTime(
  value: DateLike,
  options: Intl.DateTimeFormatOptions = {},
  locale = 'id-ID'
) {
  const d = toDate(value)
  if (!d) return '-'

  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    ...options
  }).format(d)
}

export function formatCurrencyIDR(
  value: unknown,
  options: Intl.NumberFormatOptions = {},
  locale = 'id-ID'
) {
  const n = typeof value === 'number' ? value : Number(value)
  if (Number.isNaN(n)) return '-'

  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
    ...options
  }).format(n)
}

