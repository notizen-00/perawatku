<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'
import { listConsultations } from '~/services/admin/consultations'
import { listOrders } from '~/services/admin/orders'
import { getUserBalance, getUserBalanceHistory } from '~/services/admin/reports'
import { listServiceBookings } from '~/services/admin/service-bookings'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'
import { getUser } from '~/services/shared/users'

const route = useRoute()
const toast = useToast()

const UBadge = resolveComponent('UBadge')

const id = computed(() => String(route.params.id || ''))

const { data, pending, error, refresh } = await useAsyncData(
  () => `patient:${id.value}`,
  async () => {
    const res = await getUser(id.value)
    return res.data
  },
  { watch: [id] }
)

const { data: orders, pending: ordersPending, refresh: refreshOrders } = await useAsyncData(
  () => `patient-orders:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await listOrders({ patient_user_id: Number(id.value), per_page: 5 })).data).items,
  { default: () => [], watch: [id] }
)

const { data: consultations, pending: consultationsPending, refresh: refreshConsultations } = await useAsyncData(
  () => `patient-consultations:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await listConsultations({ patient_user_id: Number(id.value), per_page: 5 })).data).items,
  { default: () => [], watch: [id] }
)

const { data: bookings, pending: bookingsPending, refresh: refreshBookings } = await useAsyncData(
  () => `patient-bookings:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await listServiceBookings({ patient_user_id: Number(id.value), per_page: 5 })).data).items,
  { default: () => [], watch: [id] }
)

const { data: balance, pending: balancePending, refresh: refreshBalance } = await useAsyncData(
  () => `patient-balance:${id.value}`,
  async () => (await getUserBalance(id.value)).data,
  { default: () => null, watch: [id] }
)

const { data: balanceHistory, pending: balanceHistoryPending, refresh: refreshBalanceHistory } = await useAsyncData(
  () => `patient-balance-history:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await getUserBalanceHistory(id.value, { per_page: 5 })).data).items,
  { default: () => [], watch: [id] }
)

const balanceAmount = computed(() =>
  balance.value?.balance ?? balance.value?.amount ?? balance.value?.saldo ?? balance.value?.data?.balance ?? 0
)

const patientProfile = computed(() => data.value?.patient_profile || (data.value as any)?.profile || {})

const historyLoading = computed(() =>
  ordersPending.value || consultationsPending.value || bookingsPending.value || balanceHistoryPending.value
)

function statusColor(status?: string | null) {
  if (['completed', 'delivered', 'paid', 'success', 'verified'].includes(String(status))) return 'success' as const
  if (['cancelled', 'failed', 'rejected'].includes(String(status))) return 'error' as const
  if (['pending', 'processed', 'draft'].includes(String(status))) return 'warning' as const
  if (['confirmed', 'ongoing', 'assigned', 'shipped'].includes(String(status))) return 'info' as const
  return 'neutral' as const
}

function bookingCode(item: any) {
  return item.booking_code || item.service_booking_code || `#${item.id}`
}

async function refreshAll() {
  await Promise.all([
    refresh(),
    refreshOrders(),
    refreshConsultations(),
    refreshBookings(),
    refreshBalance(),
    refreshBalanceHistory()
  ])
}

async function copyId() {
  const value = String(data.value?.id || '')
  if (!value) return
  await globalThis.navigator?.clipboard?.writeText(value)
  toast.add({ title: 'Copied', description: 'Patient ID disalin.' })
}

const orderColumns: TableColumn<any>[] = [
  {
    id: 'order',
    header: 'Order',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.order_code || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, formatDateTime(row.original.created_at))
      ])
  },
  { accessorKey: 'order_type', header: 'Type', cell: ({ row }) => row.original.order_type || '-' },
  { id: 'amount', header: 'Total', cell: ({ row }) => formatCurrencyIDR(row.original.total_amount) },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
  }
]

const consultationColumns: TableColumn<any>[] = [
  {
    id: 'consultation',
    header: 'Konsultasi',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.consultation_code || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, formatDateTime(row.original.created_at))
      ])
  },
  { accessorKey: 'service_type', header: 'Service', cell: ({ row }) => row.original.service_type || '-' },
  { id: 'partner', header: 'Partner', cell: ({ row }) => row.original.partner?.name || '-' },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
  }
]

const bookingColumns: TableColumn<any>[] = [
  {
    id: 'booking',
    header: 'Booking',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, bookingCode(row.original)),
        h('p', { class: 'text-xs text-dimmed' }, formatDateTime(row.original.scheduled_at || row.original.booking_date || row.original.created_at))
      ])
  },
  { id: 'service', header: 'Service', cell: ({ row }) => row.original.service?.name || '-' },
  { id: 'partner', header: 'Partner', cell: ({ row }) => row.original.assigned_partner?.name || row.original.partner?.name || '-' },
  { id: 'amount', header: 'Total', cell: ({ row }) => formatCurrencyIDR(row.original.total_amount ?? row.original.final_price) },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
  }
]

const balanceHistoryColumns: TableColumn<any>[] = [
  {
    id: 'transaction',
    header: 'Transaksi Saldo',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.transaction_code || row.original.reference || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, row.original.description || row.original.notes || '')
      ])
  },
  { id: 'type', header: 'Type', cell: ({ row }) => row.original.type || row.original.transaction_type || '-' },
  { id: 'amount', header: 'Amount', cell: ({ row }) => formatCurrencyIDR(row.original.amount ?? row.original.value) },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
  },
  { id: 'date', header: 'Tanggal', cell: ({ row }) => formatDateTime(row.original.created_at || row.original.transaction_date) }
]
</script>

<template>
  <UDashboardPanel id="patient-detail">
    <template #header>
      <UDashboardNavbar :title="data?.name ? `Patient: ${data.name}` : 'Patient Detail'">
        <template #leading>
          <UButton icon="i-lucide-arrow-left" color="neutral" variant="ghost" @click="navigateTo('/patients')" />
        </template>

        <template #right>
          <UButton icon="i-lucide-copy" color="neutral" variant="outline" :disabled="!data?.id" @click="copyId">
            Copy ID
          </UButton>
          <UButton icon="i-lucide-refresh-cw" color="neutral" variant="outline" :loading="pending || historyLoading" @click="refreshAll">
            Refresh
          </UButton>
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <UAlert
        v-if="error"
        color="error"
        variant="subtle"
        title="Gagal memuat data"
        :description="(error as any)?.message || 'Terjadi kesalahan.'"
      />

      <div v-else class="space-y-4">
        <div class="grid gap-4 lg:grid-cols-3">
          <UCard class="lg:col-span-2">
            <template #header>
              <div class="flex items-center justify-between gap-3">
                <div class="flex min-w-0 items-center gap-3">
                  <UAvatar :alt="data?.name" size="xl" />
                  <div class="min-w-0 space-y-0.5">
                    <div class="text-sm text-dimmed">Informasi Pasien</div>
                    <div class="text-lg font-semibold">{{ data?.name || '-' }}</div>
                  </div>
                </div>
                <UBadge variant="subtle" color="neutral">{{ data?.role || 'patient' }}</UBadge>
              </div>
            </template>

            <div class="grid gap-4 sm:grid-cols-2">
              <div>
                <div class="text-xs text-dimmed">Email</div>
                <div class="font-medium">{{ data?.email || '-' }}</div>
              </div>
              <div>
                <div class="text-xs text-dimmed">Phone</div>
                <div class="font-medium">{{ data?.phone || '-' }}</div>
              </div>
              <div>
                <div class="text-xs text-dimmed">Gender</div>
                <div class="font-medium">{{ patientProfile?.gender || '-' }}</div>
              </div>
              <div>
                <div class="text-xs text-dimmed">Tanggal Lahir</div>
                <div class="font-medium">{{ patientProfile?.birth_date ? formatDate(patientProfile.birth_date) : '-' }}</div>
              </div>
            </div>
          </UCard>

          <UCard>
            <template #header>
              <div class="text-sm text-dimmed">Saldo Balance</div>
            </template>

            <div class="space-y-3">
              <div class="text-2xl font-semibold text-highlighted">
                {{ formatCurrencyIDR(balanceAmount) }}
              </div>
              <div class="text-xs text-muted">
                {{ balancePending ? 'Memuat saldo...' : 'Saldo aktif pasien' }}
              </div>
            </div>
          </UCard>
        </div>

        <UCard>
          <template #header>
            <div class="font-medium">Riwayat Pesanan</div>
          </template>
          <UTable :data="orders || []" :columns="orderColumns" :loading="ordersPending" />
        </UCard>

        <UCard>
          <template #header>
            <div class="font-medium">Riwayat Service Booking</div>
          </template>
          <UTable :data="bookings || []" :columns="bookingColumns" :loading="bookingsPending" />
        </UCard>

        <UCard>
          <template #header>
            <div class="font-medium">Riwayat Konsultasi</div>
          </template>
          <UTable :data="consultations || []" :columns="consultationColumns" :loading="consultationsPending" />
        </UCard>

        <UCard>
          <template #header>
            <div class="font-medium">Riwayat Saldo</div>
          </template>
          <UTable :data="balanceHistory || []" :columns="balanceHistoryColumns" :loading="balanceHistoryPending" />
        </UCard>
      </div>

      <USkeleton v-if="pending" class="h-32 w-full mt-4" />
    </template>
  </UDashboardPanel>
</template>
