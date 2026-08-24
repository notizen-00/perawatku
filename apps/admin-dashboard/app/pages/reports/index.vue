<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import {
  getCustomersReport,
  getOrdersReport,
  getProfitLossReport,
  listBalanceTransactions,
  listBalances,
  listJournals,
  listTransactions
} from '~/services/admin/reports'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

type ReportTab = 'overview' | 'orders' | 'customers' | 'profitLoss' | 'balance' | 'transactions' | 'journals'

type AsyncState<T> = {
  data: T
  loading: boolean
  error: string | null
}

const UBadge = resolveComponent('UBadge')

const today = new Date()
const thirtyDaysAgo = new Date()
thirtyDaysAgo.setDate(today.getDate() - 30)

const activeTab = ref<ReportTab>('overview')
const fromDate = ref(toDateInput(thirtyDaysAgo))
const toDate = ref(toDateInput(today))
const statusFilter = ref('all')
const transactionSearch = ref('')

const ordersReport = reactive<AsyncState<Record<string, any>>>({
  data: {},
  loading: false,
  error: null
})

const customersReport = reactive<AsyncState<Record<string, any>>>({
  data: {},
  loading: false,
  error: null
})

const profitLossReport = reactive<AsyncState<Record<string, any>>>({
  data: {},
  loading: false,
  error: null
})

const balancesReport = reactive<AsyncState<any[]>>({
  data: [],
  loading: false,
  error: null
})

const transactionRows = reactive<AsyncState<any[]>>({
  data: [],
  loading: false,
  error: null
})

const balanceTransactionRows = reactive<AsyncState<any[]>>({
  data: [],
  loading: false,
  error: null
})

const journalRows = reactive<AsyncState<any[]>>({
  data: [],
  loading: false,
  error: null
})

const tabs = [
  { label: 'Ringkasan', value: 'overview', icon: 'i-lucide-layout-dashboard' },
  { label: 'Order', value: 'orders', icon: 'i-lucide-shopping-bag' },
  { label: 'Customer', value: 'customers', icon: 'i-lucide-users' },
  { label: 'Laba Rugi', value: 'profitLoss', icon: 'i-lucide-chart-line' },
  { label: 'Neraca', value: 'balance', icon: 'i-lucide-scale' },
  { label: 'Transaksi', value: 'transactions', icon: 'i-lucide-receipt-text' },
  { label: 'Jurnal', value: 'journals', icon: 'i-lucide-book-open-check' }
] satisfies Array<{ label: string, value: ReportTab, icon: string }>

const summaryCards = computed(() => [
  {
    label: 'Total Order',
    value: pickFirstNumber(ordersReport.data, ['total_orders', 'orders_count', 'total_count', 'count']),
    format: 'number'
  },
  {
    label: 'Pendapatan',
    value: pickFirstNumber(profitLossReport.data, ['revenue', 'total_revenue', 'income', 'gross_revenue', 'total_income']),
    format: 'currency'
  },
  {
    label: 'Laba Aplikator',
    value: pickFirstNumber(profitLossReport.data, [
      'app_profit',
      'applicator_profit',
      'platform_profit',
      'net_profit',
      'profit',
      'laba_aplikator'
    ]),
    format: 'currency'
  },
  {
    label: 'Customer Baru',
    value: pickFirstNumber(customersReport.data, ['new_customers', 'customers_count', 'total_customers', 'count']),
    format: 'number'
  }
])

const profitLossCards = computed(() => [
  { label: 'Pendapatan', value: pickFirstNumber(profitLossReport.data, ['revenue', 'total_revenue', 'income', 'gross_revenue', 'total_income']) },
  { label: 'HPP / Beban Pokok', value: pickFirstNumber(profitLossReport.data, ['cogs', 'cost_of_goods_sold', 'cost', 'total_cost']) },
  { label: 'Laba Kotor', value: pickFirstNumber(profitLossReport.data, ['gross_profit']) },
  { label: 'Biaya Operasional', value: pickFirstNumber(profitLossReport.data, ['operational_cost', 'operating_expense', 'expense', 'total_expense']) },
  { label: 'Laba Aplikator', value: pickFirstNumber(profitLossReport.data, ['app_profit', 'applicator_profit', 'platform_profit', 'laba_aplikator']) },
  { label: 'Laba Bersih', value: pickFirstNumber(profitLossReport.data, ['net_profit', 'profit']) }
])

const balanceCards = computed(() => [
  { label: 'Total Saldo User', value: sumByPossibleKeys(balancesReport.data, ['balance', 'amount', 'saldo']) },
  { label: 'Saldo Aktif', value: sumByPossibleKeys(balancesReport.data.filter(row => isActiveStatus(row.status)), ['balance', 'amount', 'saldo']) },
  { label: 'Total Debit Jurnal', value: sumJournalTotal('debit') },
  { label: 'Total Kredit Jurnal', value: sumJournalTotal('credit') }
])

const genericReportEntries = computed(() => ({
  orders: objectEntries(ordersReport.data),
  customers: objectEntries(customersReport.data),
  profitLoss: objectEntries(profitLossReport.data)
}))

const balanceColumns: TableColumn<any>[] = [
  {
    id: 'user',
    header: 'User',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.user?.name || row.original.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, row.original.user?.email || row.original.email || '')
      ])
  },
  {
    id: 'balance',
    header: 'Saldo',
    cell: ({ row }) => formatCurrencyIDR(row.original.balance ?? row.original.amount ?? row.original.saldo)
  },
  {
    id: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: isActiveStatus(row.original.status) ? 'success' : 'neutral' }, () => row.original.status || '-')
  },
  {
    id: 'updated_at',
    header: 'Updated',
    cell: ({ row }) => formatDateTime(row.original.updated_at || row.original.created_at)
  }
]

const transactionColumns: TableColumn<any>[] = [
  {
    id: 'reference',
    header: 'Transaksi',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.transaction_code || row.original.reference || row.original.reference_type || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, row.original.description || row.original.notes || '')
      ])
  },
  {
    id: 'user',
    header: 'User',
    cell: ({ row }) => row.original.user?.name || row.original.patient?.name || row.original.partner?.name || '-'
  },
  {
    id: 'type',
    header: 'Type',
    cell: ({ row }) => row.original.type || row.original.transaction_type || '-'
  },
  {
    id: 'amount',
    header: 'Amount',
    cell: ({ row }) => formatCurrencyIDR(row.original.amount ?? row.original.total_amount ?? row.original.value)
  },
  {
    id: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
  },
  {
    id: 'created_at',
    header: 'Tanggal',
    cell: ({ row }) => formatDateTime(row.original.created_at || row.original.transaction_date)
  }
]

const journalColumns: TableColumn<any>[] = [
  {
    id: 'entry',
    header: 'Jurnal',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.description || row.original.reference_type || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, row.original.entry_date ? formatDate(row.original.entry_date) : formatDateTime(row.original.created_at))
      ])
  },
  {
    id: 'reference',
    header: 'Reference',
    cell: ({ row }) => row.original.reference_type ? `${row.original.reference_type} #${row.original.reference_id || '-'}` : '-'
  },
  {
    id: 'debit',
    header: 'Debit',
    cell: ({ row }) => formatCurrencyIDR(row.original.totals?.debit ?? row.original.total_debit)
  },
  {
    id: 'credit',
    header: 'Credit',
    cell: ({ row }) => formatCurrencyIDR(row.original.totals?.credit ?? row.original.total_credit)
  },
  {
    id: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: journalStatusColor(row.original.status) }, () => row.original.status || '-')
  },
  {
    id: 'balanced',
    header: 'Balance',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: row.original.is_balanced === false ? 'error' : 'success' }, () => row.original.is_balanced === false ? 'Tidak balance' : 'Balance')
  }
]

watchDebounced(
  transactionSearch,
  async () => {
    await refreshTransactionReports()
  },
  { debounce: 400, maxWait: 1200 }
)

watch(
  () => [fromDate.value, toDate.value, statusFilter.value],
  async () => {
    await refreshReports()
  }
)

await callOnce(async () => {
  await refreshReports()
})

function toDateInput(value: Date) {
  return value.toISOString().slice(0, 10)
}

function reportQuery() {
  return {
    from: fromDate.value || undefined,
    to: toDate.value || undefined
  }
}

function errorMessage(error: any, fallback: string) {
  return error?.data?.message || error?.message || fallback
}

async function withState<T>(
  state: AsyncState<T>,
  fallback: T,
  task: () => Promise<T>,
  fallbackMessage: string
) {
  state.loading = true
  state.error = null

  try {
    state.data = await task()
  }
  catch (error: any) {
    state.data = fallback
    state.error = errorMessage(error, fallbackMessage)
  }
  finally {
    state.loading = false
  }
}

async function refreshReports() {
  await Promise.all([
    withState(
      ordersReport,
      {},
      async () => (await getOrdersReport({
        ...reportQuery(),
        status: statusFilter.value !== 'all' ? statusFilter.value : undefined
      })).data || {},
      'Gagal memuat laporan order.'
    ),
    withState(
      customersReport,
      {},
      async () => (await getCustomersReport(reportQuery())).data || {},
      'Gagal memuat laporan customer.'
    ),
    withState(
      profitLossReport,
      {},
      async () => (await getProfitLossReport(reportQuery())).data || {},
      'Gagal memuat laporan laba rugi.'
    ),
    withState(
      balancesReport,
      [],
      async () => normalizeLaravelPaginated<any>((await listBalances({ per_page: 100 })).data).items,
      'Gagal memuat neraca saldo.'
    ),
    refreshTransactionReports(),
    withState(
      journalRows,
      [],
      async () => normalizeLaravelPaginated<any>((await listJournals({
        ...reportQuery(),
        status: statusFilter.value !== 'all' ? statusFilter.value : undefined,
        per_page: 100
      })).data).items,
      'Gagal memuat jurnal.'
    )
  ])
}

async function refreshTransactionReports() {
  await Promise.all([
    withState(
      transactionRows,
      [],
      async () => normalizeLaravelPaginated<any>((await listTransactions({
        search: transactionSearch.value.trim() || undefined,
        per_page: 100
      })).data).items,
      'Gagal memuat transaksi.'
    ),
    withState(
      balanceTransactionRows,
      [],
      async () => normalizeLaravelPaginated<any>((await listBalanceTransactions({
        from_date: fromDate.value || undefined,
        to_date: toDate.value || undefined,
        status: statusFilter.value !== 'all' ? statusFilter.value : undefined,
        per_page: 100
      })).data).items,
      'Gagal memuat transaksi saldo.'
    )
  ])
}

function pickFirstNumber(source: Record<string, any>, keys: string[]) {
  for (const key of keys) {
    const value = source?.[key]
    const number = Number(value)
    if (value !== undefined && value !== null && Number.isFinite(number)) return number
  }

  return null
}

function formatMetric(value: number | null, format: string) {
  if (value == null) return '-'
  if (format === 'currency') return formatCurrencyIDR(value)
  return Number(value).toLocaleString('id-ID')
}

function objectEntries(source: Record<string, any>) {
  return Object.entries(source || {})
    .filter(([, value]) => value == null || ['string', 'number', 'boolean'].includes(typeof value))
    .map(([key, value]) => ({
      key,
      label: key.replaceAll('_', ' '),
      value
    }))
}

function formatUnknownValue(value: any) {
  if (value == null || value === '') return '-'
  if (typeof value === 'boolean') return value ? 'Ya' : 'Tidak'
  if (typeof value === 'number') return Number.isFinite(value) ? value.toLocaleString('id-ID') : '-'
  return String(value)
}

function sumByPossibleKeys(rows: any[], keys: string[]) {
  return rows.reduce((total, row) => {
    for (const key of keys) {
      const value = Number(row?.[key])
      if (Number.isFinite(value)) return total + value
    }

    return total
  }, 0)
}

function sumJournalTotal(type: 'debit' | 'credit') {
  return journalRows.data.reduce((total, row) => {
    const value = Number(row?.totals?.[type] ?? row?.[`total_${type}`])
    return Number.isFinite(value) ? total + value : total
  }, 0)
}

function isActiveStatus(status: any) {
  return status === 'active' || status === 'aktif' || status === true || status == null
}

function statusColor(status?: string) {
  if (status === 'success' || status === 'completed' || status === 'paid' || status === 'posted') return 'success' as const
  if (status === 'failed' || status === 'cancelled' || status === 'void') return 'error' as const
  if (status === 'pending' || status === 'draft') return 'warning' as const
  return 'neutral' as const
}

function journalStatusColor(status?: string) {
  if (status === 'posted') return 'success' as const
  if (status === 'void') return 'error' as const
  if (status === 'draft') return 'warning' as const
  return 'neutral' as const
}
</script>

<template>
  <UDashboardPanel id="reports">
    <template #header>
      <UDashboardNavbar title="Laporan">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div class="flex flex-wrap items-center gap-2">
            <UInput
              v-model="fromDate"
              type="date"
              class="w-40"
            />
            <UInput
              v-model="toDate"
              type="date"
              class="w-40"
            />
            <USelect
              v-model="statusFilter"
              class="min-w-36"
              :items="[
                { label: 'Semua Status', value: 'all' },
                { label: 'pending', value: 'pending' },
                { label: 'completed', value: 'completed' },
                { label: 'paid', value: 'paid' },
                { label: 'posted', value: 'posted' },
                { label: 'draft', value: 'draft' },
                { label: 'cancelled', value: 'cancelled' },
                { label: 'void', value: 'void' }
              ]"
            />
          </div>

          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-refresh-cw"
            :loading="ordersReport.loading || customersReport.loading || profitLossReport.loading || transactionRows.loading || journalRows.loading"
            @click="refreshReports"
          >
            Refresh
          </UButton>
        </div>

        <div class="flex flex-wrap gap-1.5">
          <UButton
            v-for="tab in tabs"
            :key="tab.value"
            :icon="tab.icon"
            :label="tab.label"
            :variant="activeTab === tab.value ? 'solid' : 'outline'"
            @click="activeTab = tab.value"
          />
        </div>

        <div v-if="activeTab === 'overview'" class="space-y-4">
          <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <UPageCard
              v-for="card in summaryCards"
              :key="card.label"
              variant="subtle"
            >
              <div class="space-y-1">
                <p class="text-sm text-muted">{{ card.label }}</p>
                <p class="text-2xl font-semibold text-highlighted">
                  {{ formatMetric(card.value, card.format) }}
                </p>
              </div>
            </UPageCard>
          </div>

          <UAlert
            v-if="profitLossReport.error || ordersReport.error || customersReport.error"
            color="warning"
            variant="subtle"
            title="Sebagian laporan belum termuat"
            :description="[ordersReport.error, customersReport.error, profitLossReport.error].filter(Boolean).join(' ')"
          />
        </div>

        <div v-if="activeTab === 'orders'" class="space-y-4">
          <UAlert v-if="ordersReport.error" color="error" variant="subtle" :description="ordersReport.error" />
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <UPageCard v-for="item in genericReportEntries.orders" :key="item.key" variant="subtle">
              <p class="text-sm capitalize text-muted">{{ item.label }}</p>
              <p class="text-xl font-semibold text-highlighted">{{ formatUnknownValue(item.value) }}</p>
            </UPageCard>
          </div>
        </div>

        <div v-if="activeTab === 'customers'" class="space-y-4">
          <UAlert v-if="customersReport.error" color="error" variant="subtle" :description="customersReport.error" />
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <UPageCard v-for="item in genericReportEntries.customers" :key="item.key" variant="subtle">
              <p class="text-sm capitalize text-muted">{{ item.label }}</p>
              <p class="text-xl font-semibold text-highlighted">{{ formatUnknownValue(item.value) }}</p>
            </UPageCard>
          </div>
        </div>

        <div v-if="activeTab === 'profitLoss'" class="space-y-4">
          <UAlert v-if="profitLossReport.error" color="error" variant="subtle" :description="profitLossReport.error" />
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            <UPageCard v-for="item in profitLossCards" :key="item.label" variant="subtle">
              <p class="text-sm text-muted">{{ item.label }}</p>
              <p class="text-xl font-semibold text-highlighted">{{ item.value == null ? '-' : formatCurrencyIDR(item.value) }}</p>
            </UPageCard>
          </div>

          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <UPageCard v-for="item in genericReportEntries.profitLoss" :key="item.key" variant="naked">
              <p class="text-xs capitalize text-muted">{{ item.label }}</p>
              <p class="text-base font-medium text-highlighted">{{ formatUnknownValue(item.value) }}</p>
            </UPageCard>
          </div>
        </div>

        <div v-if="activeTab === 'balance'" class="space-y-4">
          <UAlert v-if="balancesReport.error || journalRows.error" color="error" variant="subtle" :description="[balancesReport.error, journalRows.error].filter(Boolean).join(' ')" />
          <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <UPageCard v-for="item in balanceCards" :key="item.label" variant="subtle">
              <p class="text-sm text-muted">{{ item.label }}</p>
              <p class="text-xl font-semibold text-highlighted">{{ formatCurrencyIDR(item.value) }}</p>
            </UPageCard>
          </div>

          <UTable
            :data="balancesReport.data"
            :columns="balanceColumns"
            :loading="balancesReport.loading"
            :ui="{
              base: 'table-fixed border-separate border-spacing-0',
              thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
              tbody: '[&>tr]:last:[&>td]:border-b-0',
              th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
              td: 'border-b border-default',
              separator: 'h-0'
            }"
          />
        </div>

        <div v-if="activeTab === 'transactions'" class="space-y-4">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <UInput
              v-model="transactionSearch"
              class="max-w-sm"
              icon="i-lucide-search"
              placeholder="Cari transaksi..."
            />
          </div>

          <UAlert v-if="transactionRows.error || balanceTransactionRows.error" color="error" variant="subtle" :description="[transactionRows.error, balanceTransactionRows.error].filter(Boolean).join(' ')" />

          <div class="space-y-2">
            <h2 class="text-base font-semibold text-highlighted">Transaksi Umum</h2>
            <UTable
              :data="transactionRows.data"
              :columns="transactionColumns"
              :loading="transactionRows.loading"
              :ui="{
                base: 'table-fixed border-separate border-spacing-0',
                thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
                tbody: '[&>tr]:last:[&>td]:border-b-0',
                th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
                td: 'border-b border-default',
                separator: 'h-0'
              }"
            />
          </div>

          <div class="space-y-2">
            <h2 class="text-base font-semibold text-highlighted">Transaksi Saldo</h2>
            <UTable
              :data="balanceTransactionRows.data"
              :columns="transactionColumns"
              :loading="balanceTransactionRows.loading"
              :ui="{
                base: 'table-fixed border-separate border-spacing-0',
                thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
                tbody: '[&>tr]:last:[&>td]:border-b-0',
                th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
                td: 'border-b border-default',
                separator: 'h-0'
              }"
            />
          </div>
        </div>

        <div v-if="activeTab === 'journals'" class="space-y-4">
          <UAlert v-if="journalRows.error" color="error" variant="subtle" :description="journalRows.error" />
          <UTable
            :data="journalRows.data"
            :columns="journalColumns"
            :loading="journalRows.loading"
            :ui="{
              base: 'table-fixed border-separate border-spacing-0',
              thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
              tbody: '[&>tr]:last:[&>td]:border-b-0',
              th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
              td: 'border-b border-default',
              separator: 'h-0'
            }"
          />
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
