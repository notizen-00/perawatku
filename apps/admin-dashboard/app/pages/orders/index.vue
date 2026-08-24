<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from '@nuxt/ui'
import type { OrderLite, OrderStatus, OrderType } from '~/services/admin/orders'

const store = useOrdersStore()
const toast = useToast()

const UBadge = resolveComponent('UBadge')
const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const search = ref(store.filters.search)

watchDebounced(
  search,
  (value) => {
    store.filters.search = value
    store.pagination.page = 1
    store.fetch()
  },
  { debounce: 400, maxWait: 1200 }
)

watch(
  () => [store.filters.status, store.filters.orderType] as const,
  () => {
    store.pagination.page = 1
    store.fetch()
  }
)

await callOnce(async () => {
  await store.fetch()
})

function statusColor(status?: OrderStatus) {
  if (status === 'delivered') return 'success' as const
  if (status === 'cancelled') return 'error' as const
  if (status === 'shipped') return 'primary' as const
  if (status === 'processed') return 'warning' as const
  if (status === 'confirmed') return 'info' as const
  return 'neutral' as const
}

function statusLabel(status?: string) {
  return status || '-'
}

function getRowItems(order: OrderLite): DropdownMenuItem[] {
  return [
    { label: 'Actions', type: 'label' },
    {
      label: 'Lihat detail',
      icon: 'i-lucide-eye',
      onSelect: () => navigateTo(`/orders/${order.id}`)
    },
    {
      label: 'Copy Order ID',
      icon: 'i-lucide-copy',
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(order.id))
        toast.add({ title: 'Copied', description: `Order ID ${order.id} disalin.` })
      }
    },
    ...(order.order_code
      ? [{
          label: 'Copy Order Code',
          icon: 'i-lucide-clipboard',
          onSelect: async () => {
            await globalThis.navigator?.clipboard?.writeText(String(order.order_code))
            toast.add({ title: 'Copied', description: `Order code ${order.order_code} disalin.` })
          }
        } satisfies DropdownMenuItem]
      : [])
  ]
}

const columns: TableColumn<OrderLite>[] = [
  {
    id: 'order_code',
    header: 'Order',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.order_code || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, formatDateTime(row.original.created_at))
      ])
  },
  {
    id: 'patient',
    header: 'Patient',
    cell: ({ row }) => {
      const patient = row.original.patient
      return h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, patient?.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, patient?.email || '')
      ])
    }
  },
  {
    id: 'pharmacy',
    header: 'Pharmacy',
    cell: ({ row }) => row.original.pharmacy?.profile?.name || '-'
  },
  {
    accessorKey: 'order_type',
    header: 'Type',
    cell: ({ row }) => row.original.order_type || '-'
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => statusLabel(row.original.status))
  },
  {
    id: 'actions',
    cell: ({ row }) =>
      h(
        'div',
        { class: 'text-right' },
        h(
          UDropdownMenu,
          { items: getRowItems(row.original), content: { align: 'end' } },
          () =>
            h(UButton, {
              icon: 'i-lucide-ellipsis-vertical',
              color: 'neutral',
              variant: 'ghost',
              size: 'xs',
              class: 'ml-auto'
            })
        )
      )
  }
]
</script>

<template>
  <UDashboardPanel id="orders">
    <template #header>
      <UDashboardNavbar title="Orders">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-2">
        <UInput
          v-model="search"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Cari order_code/patient/pharmacy..."
        />

        <div class="flex flex-wrap items-center gap-2">
          <USelect
            v-model="store.filters.status"
            class="min-w-40"
            placeholder="Status"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'pending', value: 'pending' },
              { label: 'confirmed', value: 'confirmed' },
              { label: 'processed', value: 'processed' },
              { label: 'shipped', value: 'shipped' },
              { label: 'delivered', value: 'delivered' },
              { label: 'cancelled', value: 'cancelled' }
            ]"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
          />

          <USelect
            v-model="store.filters.orderType"
            class="min-w-36"
            placeholder="Type"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'resep', value: 'resep' },
              { label: 'non_resep', value: 'non_resep' }
            ]"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
          />

          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-refresh-cw"
            :loading="store.loading"
            @click="store.fetch()"
          >
            Refresh
          </UButton>
        </div>
      </div>

      <UAlert
        v-if="store.error"
        color="error"
        variant="subtle"
        title="Gagal memuat data"
        :description="store.error"
      />

      <UTable
        :data="store.items"
        :columns="columns"
        :loading="store.loading"
        :ui="{
          base: 'table-fixed border-separate border-spacing-0',
          thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
          tbody: '[&>tr]:last:[&>td]:border-b-0',
          th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
          td: 'border-b border-default',
          separator: 'h-0'
        }"
      />

      <div class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-4">
        <div class="text-sm text-muted">
          Total: {{ store.pagination.total }}
        </div>

        <UPagination
          :page="store.pagination.page"
          :items-per-page="store.pagination.perPage"
          :total="store.pagination.total"
          @update:page="(p: number) => { store.pagination.page = p; store.fetch() }"
        />
      </div>
    </template>
  </UDashboardPanel>
</template>
