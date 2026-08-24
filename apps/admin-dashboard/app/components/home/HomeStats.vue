<script setup lang="ts">
import type { Range, Stat } from '~/types'
import { getCustomersReport, getOrdersReport, getProfitLossReport } from '~/services/admin/reports'
import { listPartners } from '~/services/admin/partners'

const props = defineProps<{
  range: Range
}>()

function toDateParam(date: Date): string {
  return date.toISOString().slice(0, 10)
}

const { data: stats } = await useAsyncData<Stat[]>('home-stats', async () => {
  const from = toDateParam(props.range.start)
  const to = toDateParam(props.range.end)

  const [customersRes, ordersRes, profitRes, pendingPartnersRes] = await Promise.all([
    getCustomersReport({ from, to }),
    getOrdersReport({ from, to }),
    getProfitLossReport({ from, to }),
    listPartners({ verification_status: 'pending', per_page: 1 })
  ])

  const customers = customersRes.data
  const orders = ordersRes.data
  const profit = profitRes.data
  const pendingPartners = (pendingPartnersRes.data as any)?.total
    ?? (pendingPartnersRes.data as any)?.meta?.total
    ?? 0

  return [
    {
      title: 'Pasien Baru',
      icon: 'i-lucide-users',
      value: customers.new_customers ?? 0,
      badge: `${customers.total_customers ?? 0} total pasien`,
      to: '/patients'
    },
    {
      title: 'Pesanan Obat',
      icon: 'i-lucide-shopping-cart',
      value: orders.total_orders ?? 0,
      badge: `${orders.completed_orders ?? 0} selesai`,
      to: '/orders'
    },
    {
      title: 'Pendapatan',
      icon: 'i-lucide-circle-dollar-sign',
      value: formatCurrencyIDR(profit.total_revenue ?? 0),
      badge: `Laba ${formatCurrencyIDR(profit.net_profit ?? 0)}`,
      to: '/reports'
    },
    {
      title: 'Mitra Menunggu Verifikasi',
      icon: 'i-lucide-user-check',
      value: pendingPartners,
      badge: pendingPartners > 0 ? 'Perlu ditinjau' : 'Semua terverifikasi',
      to: '/partners'
    }
  ]
}, {
  watch: [() => props.range],
  default: () => []
})
</script>

<template>
  <UPageGrid class="lg:grid-cols-4 gap-4 sm:gap-6 lg:gap-px">
    <UPageCard
      v-for="(stat, index) in stats"
      :key="index"
      :icon="stat.icon"
      :title="stat.title"
      :to="stat.to"
      variant="subtle"
      :ui="{
        container: 'gap-y-1.5',
        wrapper: 'items-start',
        leading: 'p-2.5 rounded-full bg-primary/10 ring ring-inset ring-primary/25 flex-col',
        title: 'font-normal text-muted text-xs uppercase'
      }"
      class="lg:rounded-none first:rounded-l-lg last:rounded-r-lg hover:z-1"
    >
      <div class="flex items-center gap-2">
        <span class="text-2xl font-semibold text-highlighted">
          {{ stat.value }}
        </span>

        <UBadge v-if="stat.badge" color="neutral" variant="subtle" class="text-xs">
          {{ stat.badge }}
        </UBadge>
      </div>
    </UPageCard>
  </UPageGrid>
</template>
