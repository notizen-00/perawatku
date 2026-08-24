<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from '@nuxt/ui'
import type { PartnerServiceLite } from '~/services/admin/partner-services'

const store = usePartnerServiceApplicationsStore()
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
  () => [store.filters.verified, store.filters.active] as const,
  () => {
    store.pagination.page = 1
    store.fetch()
  }
)

await callOnce(async () => {
  await store.fetch()
})

function getRowItems(item: PartnerServiceLite): DropdownMenuItem[] {
  const id = item.id
  const loading = !!store.actionLoadingIds[id]

  return [
    { label: 'Actions', type: 'label' },
    {
      label: 'Approve',
      icon: 'i-lucide-check',
      disabled: loading,
      onSelect: async () => {
        await store.setVerified(id, true)
        toast.add({ title: 'Updated', description: 'Status verifikasi diperbarui.' })
      }
    },
    {
      label: 'Reject',
      icon: 'i-lucide-x',
      disabled: loading,
      onSelect: async () => {
        await store.setVerified(id, false)
        toast.add({ title: 'Updated', description: 'Status verifikasi diperbarui.' })
      }
    },
    { type: 'separator' },
    {
      label: 'Copy ID',
      icon: 'i-lucide-copy',
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(id))
        toast.add({ title: 'Copied', description: `ID ${id} disalin.` })
      }
    }
  ]
}

const columns: TableColumn<PartnerServiceLite>[] = [
  {
    id: 'service',
    header: 'Service',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.service?.name || `#${row.original.id}`),
        h('p', { class: 'text-xs text-dimmed' }, row.original.service?.service_type || '')
      ])
  },
  {
    id: 'partner',
    header: 'Partner',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.partner?.name || '-'),
        h('p', { class: 'text-xs text-dimmed' }, row.original.partner?.email || '')
      ])
  },
  {
    id: 'verified',
    header: 'Verified',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: row.original.is_verified ? 'success' : 'neutral' }, () =>
        row.original.is_verified ? 'Yes' : 'No'
      )
  },
  {
    id: 'active',
    header: 'Active',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: row.original.is_active ? 'primary' : 'error' }, () =>
        row.original.is_active ? 'Active' : 'Inactive'
      )
  },
  {
    accessorKey: 'notes',
    header: 'Notes',
    cell: ({ row }) => row.original.notes || '-'
  },
  {
    id: 'actions',
    cell: ({ row }) => {
      return h(
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
  }
]
</script>

<template>
  <UDashboardPanel id="service-applications">
    <template #header>
      <UDashboardNavbar title="Service Applications">
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
          placeholder="Cari partner/service/notes..."
        />

        <div class="flex flex-wrap items-center gap-2">
          <USelect
            v-model="store.filters.verified"
            class="min-w-36"
            placeholder="Verified"
            :items="[
              { label: 'All', value: 'all' },
              { label: 'Yes', value: 'true' },
              { label: 'No', value: 'false' }
            ]"
            :ui="{ trailingIcon: 'group-data-[state=open]:rotate-180 transition-transform duration-200' }"
          />
          <USelect
            v-model="store.filters.active"
            class="min-w-36"
            placeholder="Active"
            :items="[
              { label: 'All', value: 'all' },
              { label: 'Active', value: 'true' },
              { label: 'Inactive', value: 'false' }
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
        <div class="text-sm text-muted">Total: {{ store.pagination.total }}</div>

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
