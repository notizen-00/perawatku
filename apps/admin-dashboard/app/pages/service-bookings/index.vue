<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from '@nuxt/ui'
import type { ServiceBookingLite, ServiceBookingStatus } from '~/services/admin/service-bookings'

const store = useServiceBookingsStore()
const servicesStore = useServicesStore()
const toast = useToast()

const UBadge = resolveComponent('UBadge')
const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const search = ref(store.filters.search)
const patientUserId = ref<number | null>(store.filters.patientUserId)
const assignedPartnerUserId = ref<number | null>(store.filters.assignedPartnerUserId)

const serviceFilterItems = computed(() => [
  { label: 'Semua Service', value: 0 },
  ...servicesStore.items.map(item => ({
    label: item.name,
    value: item.id
  }))
])

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
  () => [store.filters.status, store.filters.serviceId] as const,
  () => {
    store.pagination.page = 1
    store.fetch()
  }
)

watchDebounced(
  [patientUserId, assignedPartnerUserId],
  ([patientId, partnerId]) => {
    store.filters.patientUserId = patientId ? Number(patientId) : null
    store.filters.assignedPartnerUserId = partnerId ? Number(partnerId) : null
    store.pagination.page = 1
    store.fetch()
  },
  { debounce: 400, maxWait: 1200 }
)

await callOnce(async () => {
  await Promise.all([store.fetch(), servicesStore.fetch()])
})

function statusColor(status?: ServiceBookingStatus | null) {
  if (status === 'completed') return 'success' as const
  if (status === 'cancelled') return 'error' as const
  if (status === 'ongoing') return 'primary' as const
  if (status === 'confirmed' || status === 'assigned') return 'info' as const
  if (status === 'pending') return 'warning' as const
  return 'neutral' as const
}

function bookingCode(item: ServiceBookingLite) {
  return item.booking_code || item.service_booking_code || `#${item.id}`
}

function bookingSchedule(item: ServiceBookingLite) {
  return item.scheduled_at || item.booking_date || item.start_date || item.created_at
}

function bookingAmount(item: ServiceBookingLite) {
  return item.total_amount ?? item.final_price ?? item.price ?? item.base_price
}

function assignedPartner(item: ServiceBookingLite) {
  return item.assigned_partner || item.partner || item.partner_user || null
}

function getRowItems(item: ServiceBookingLite): DropdownMenuItem[] {
  return [
    { label: 'Actions', type: 'label' },
    {
      label: 'Copy Booking ID',
      icon: 'i-lucide-copy',
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(item.id))
        toast.add({ title: 'Copied', description: `Booking ID ${item.id} disalin.` })
      }
    },
    {
      label: 'Copy Booking Code',
      icon: 'i-lucide-clipboard',
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(bookingCode(item))
        toast.add({ title: 'Copied', description: `Booking code ${bookingCode(item)} disalin.` })
      }
    }
  ]
}

const columns: TableColumn<ServiceBookingLite>[] = [
  {
    id: 'booking',
    header: 'Booking',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, bookingCode(row.original)),
        h('p', { class: 'text-xs text-dimmed' }, formatDateTime(row.original.created_at))
      ])
  },
  {
    id: 'service',
    header: 'Service',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.service?.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, row.original.service?.service_type || '')
      ])
  },
  {
    id: 'patient',
    header: 'Patient',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.patient?.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, row.original.patient?.email || row.original.patient?.phone || '')
      ])
  },
  {
    id: 'partner',
    header: 'Partner',
    cell: ({ row }) => {
      const partner = assignedPartner(row.original)

      return h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, partner?.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, partner?.partner_profile?.profession || partner?.email || '')
      ])
    }
  },
  {
    id: 'schedule',
    header: 'Schedule',
    cell: ({ row }) => formatDateTime(bookingSchedule(row.original))
  },
  {
    id: 'amount',
    header: 'Total',
    cell: ({ row }) => formatCurrencyIDR(bookingAmount(row.original))
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: statusColor(row.original.status) }, () => row.original.status || '-')
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
  <UDashboardPanel id="service-bookings">
    <template #header>
      <UDashboardNavbar title="Service Bookings">
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
          placeholder="Cari booking/patient/service/partner..."
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
              { label: 'assigned', value: 'assigned' },
              { label: 'ongoing', value: 'ongoing' },
              { label: 'completed', value: 'completed' },
              { label: 'cancelled', value: 'cancelled' }
            ]"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
          />

          <USelect
            :model-value="store.filters.serviceId || 0"
            class="min-w-44"
            placeholder="Service"
            :items="serviceFilterItems"
            :loading="servicesStore.loading"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
            @update:model-value="(value: number) => {
              store.filters.serviceId = value ? Number(value) : null
            }"
          />

          <UInput
            v-model.number="patientUserId"
            class="w-36"
            type="number"
            min="1"
            icon="i-lucide-user"
            placeholder="Patient ID"
          />

          <UInput
            v-model.number="assignedPartnerUserId"
            class="w-36"
            type="number"
            min="1"
            icon="i-lucide-stethoscope"
            placeholder="Partner ID"
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
