<script setup lang="ts">
import { h, resolveComponent } from 'vue'
import type { TableColumn } from '@nuxt/ui'
import { listPartners } from '~/services/admin/partners'
import type { Partner } from '~/services/admin/partners'

const UBadge = resolveComponent('UBadge')
const UButton = resolveComponent('UButton')

const { data, status, refresh } = await useAsyncData('home-pending-partners', async () => {
  const res = await listPartners({ verification_status: 'pending', per_page: 5 })
  const payload = res.data as any
  return (payload?.data ?? []) as Partner[]
}, { default: () => [] })

function professionLabel(profession?: string) {
  if (profession === 'dokter') return 'Dokter'
  if (profession === 'perawat') return 'Perawat'
  if (profession === 'bidan') return 'Bidan'
  return '-'
}

const columns: TableColumn<Partner>[] = [
  {
    accessorKey: 'name',
    header: 'Nama',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, row.original.name),
        h('p', { class: 'text-xs text-muted' }, row.original.email)
      ])
  },
  {
    id: 'profession',
    header: 'Profesi',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: 'neutral' }, () =>
        professionLabel(row.original.partner_profile?.profession))
  },
  {
    id: 'specialization',
    header: 'Spesialisasi',
    cell: ({ row }) => row.original.partner_profile?.specialization || '-'
  },
  {
    id: 'actions',
    cell: ({ row }) =>
      h('div', { class: 'text-right' }, [
        h(UButton, {
          label: 'Tinjau',
          size: 'xs',
          color: 'neutral',
          variant: 'outline',
          to: `/partners/${row.original.id}`
        })
      ])
  }
]
</script>

<template>
  <UCard :ui="{ body: 'p-0 sm:p-0' }">
    <template #header>
      <div class="flex items-center justify-between">
        <div>
          <p class="text-xs text-muted uppercase mb-1">
            Mitra Menunggu Verifikasi
          </p>
          <p class="text-sm text-highlighted font-medium">
            {{ data.length }} pendaftaran perlu ditinjau
          </p>
        </div>
        <UButton
          icon="i-lucide-refresh-cw"
          color="neutral"
          variant="ghost"
          size="xs"
          :loading="status === 'pending'"
          @click="refresh()"
        />
      </div>
    </template>

    <UTable
      :data="data"
      :columns="columns"
      class="shrink-0"
      :ui="{
        base: 'table-fixed border-separate border-spacing-0',
        thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
        tbody: '[&>tr]:last:[&>td]:border-b-0',
        th: 'first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
        td: 'border-b border-default'
      }"
    >
      <template #empty>
        <div class="py-6 text-center text-sm text-muted">
          Tidak ada mitra yang menunggu verifikasi.
        </div>
      </template>
    </UTable>
  </UCard>
</template>
