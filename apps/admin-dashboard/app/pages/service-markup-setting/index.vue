<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from '@nuxt/ui'
import type {
  MarkupType,
  ServiceMarkupSetting
} from '~/services/admin/service-markup-settings'

const store = useServiceMarkupSettingsStore()
const servicesStore = useServicesStore()
const toast = useToast()

const UBadge = resolveComponent('UBadge')
const UButton = resolveComponent('UButton')
const UDropdownMenu = resolveComponent('UDropdownMenu')

const modalOpen = ref(false)
const deleteModalOpen = ref(false)
const editing = ref<ServiceMarkupSetting | null>(null)
const deleteTarget = ref<ServiceMarkupSetting | null>(null)

const form = reactive({
  service_id: null as number | null,
  markup_type: 'percentage' as MarkupType,
  markup_value: 0,
  min_final_price: null as number | null,
  priority: 0,
  notes: '',
  is_active: true
})

const serviceFilterItems = computed(() => [
  { label: 'Semua Service', value: 0 },
  ...servicesStore.items.map(item => ({
    label: item.name,
    value: item.id
  }))
])

const serviceSelectItems = computed(() =>
  servicesStore.items.map(item => ({
    label: item.name,
    value: item.id
  }))
)

watch(
  () => [store.filters.status, store.filters.serviceId] as const,
  async () => {
    store.pagination.page = 1
    await store.fetch()
  }
)

await callOnce(async () => {
  await Promise.all([servicesStore.fetch(), store.fetch()])
})

function resetForm() {
  editing.value = null
  form.service_id = servicesStore.items[0]?.id || null
  form.markup_type = 'percentage'
  form.markup_value = 0
  form.min_final_price = null
  form.priority = 0
  form.notes = ''
  form.is_active = true
}

function openCreate() {
  resetForm()
  modalOpen.value = true
}

function openEdit(item: ServiceMarkupSetting) {
  editing.value = item
  form.service_id = item.service_id
  form.markup_type = item.markup_type
  form.markup_value = Number(item.markup_value || 0)
  form.min_final_price = item.min_final_price == null ? null : Number(item.min_final_price)
  form.priority = Number(item.priority || 0)
  form.notes = item.notes || ''
  form.is_active = Boolean(item.is_active)
  modalOpen.value = true
}

function openDelete(item: ServiceMarkupSetting) {
  deleteTarget.value = item
  deleteModalOpen.value = true
}

function markupValueLabel(item: ServiceMarkupSetting) {
  if (item.markup_type === 'percentage') return `${Number(item.markup_value || 0)}%`
  return formatCurrencyIDR(item.markup_value)
}

function serviceName(item: ServiceMarkupSetting) {
  return item.service?.name || servicesStore.items.find(service => service.id === item.service_id)?.name || `#${item.service_id}`
}

function getRowItems(item: ServiceMarkupSetting): DropdownMenuItem[] {
  return [
    {
      label: 'Edit',
      icon: 'i-lucide-edit',
      onSelect: () => openEdit(item)
    },
    {
      label: item.is_active ? 'Nonaktifkan' : 'Aktifkan',
      icon: item.is_active ? 'i-lucide-toggle-left' : 'i-lucide-toggle-right',
      onSelect: async () => {
        try {
          await store.toggleStatus(item)
          toast.add({
            title: 'Berhasil',
            description: 'Status markup diubah.',
            color: 'success'
          })
        }
        catch (e: any) {
          toast.add({
            title: 'Error',
            description: e?.data?.message || e?.message || 'Gagal mengubah status markup.',
            color: 'error'
          })
        }
      }
    },
    {
      label: 'Hapus',
      icon: 'i-lucide-trash',
      color: 'error',
      onSelect: () => openDelete(item)
    }
  ]
}

const columns: TableColumn<ServiceMarkupSetting>[] = [
  {
    id: 'service',
    header: 'Service',
    cell: ({ row }) =>
      h('div', { class: 'space-y-0.5' }, [
        h('p', { class: 'font-medium text-highlighted' }, serviceName(row.original)),
        h('p', { class: 'text-xs text-dimmed' }, row.original.service?.service_type || '')
      ])
  },
  {
    accessorKey: 'markup_type',
    header: 'Tipe',
    cell: ({ row }) => row.original.markup_type === 'percentage' ? 'Persentase' : 'Nominal'
  },
  {
    accessorKey: 'markup_value',
    header: 'Markup',
    cell: ({ row }) => markupValueLabel(row.original)
  },
  {
    accessorKey: 'min_final_price',
    header: 'Min. Harga Akhir',
    cell: ({ row }) => row.original.min_final_price ? formatCurrencyIDR(row.original.min_final_price) : '-'
  },
  {
    accessorKey: 'priority',
    header: 'Prioritas',
    cell: ({ row }) => String(row.original.priority || 0)
  },
  {
    accessorKey: 'is_active',
    header: 'Status',
    cell: ({ row }) =>
      h(UBadge, { variant: 'subtle', color: row.original.is_active ? 'success' : 'error' }, () =>
        row.original.is_active ? 'Aktif' : 'Tidak Aktif'
      )
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

async function submit() {
  if (!form.service_id) {
    toast.add({
      title: 'Validasi',
      description: 'Service wajib dipilih.',
      color: 'warning'
    })
    return
  }

  if (Number(form.markup_value) < 0) {
    toast.add({
      title: 'Validasi',
      description: 'Nilai markup tidak boleh negatif.',
      color: 'warning'
    })
    return
  }

  const payload = {
    service_id: Number(form.service_id),
    markup_type: form.markup_type,
    markup_value: Number(form.markup_value || 0),
    min_final_price: form.min_final_price == null ? undefined : Number(form.min_final_price),
    priority: Number(form.priority || 0),
    notes: form.notes.trim() || undefined,
    is_active: form.is_active
  }

  try {
    if (editing.value) {
      await store.update(editing.value.id, payload)
    }
    else {
      await store.create(payload)
    }

    modalOpen.value = false
    toast.add({
      title: 'Berhasil',
      description: 'Service markup setting berhasil disimpan.',
      color: 'success'
    })
  }
  catch (e: any) {
    toast.add({
      title: 'Error',
      description: e?.data?.message || e?.message || 'Gagal menyimpan service markup setting.',
      color: 'error'
    })
  }
}

async function confirmDelete() {
  if (!deleteTarget.value) return

  try {
    await store.remove(deleteTarget.value.id)
    deleteModalOpen.value = false
    toast.add({
      title: 'Berhasil',
      description: 'Service markup setting berhasil dihapus.',
      color: 'success'
    })
  }
  catch (e: any) {
    toast.add({
      title: 'Error',
      description: e?.data?.message || e?.message || 'Gagal menghapus service markup setting.',
      color: 'error'
    })
  }
}
</script>

<template>
  <UDashboardPanel id="service-markup-setting">
    <template #header>
      <UDashboardNavbar title="Service Markup Setting">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UButton
            icon="i-lucide-plus"
            label="Tambah Markup"
            @click="openCreate"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div class="flex flex-wrap items-center gap-2">
          <USelect
            :model-value="store.filters.serviceId || 0"
            class="min-w-52"
            placeholder="Filter service"
            :items="serviceFilterItems"
            :loading="servicesStore.loading"
            @update:model-value="(value: number) => {
              store.filters.serviceId = value ? Number(value) : null
            }"
          />

          <USelect
            v-model="store.filters.status"
            class="min-w-36"
            placeholder="Status"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'Aktif', value: 'active' },
              { label: 'Tidak Aktif', value: 'inactive' }
            ]"
          />
        </div>

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

  <UModal
    v-model:open="modalOpen"
    :title="editing ? 'Edit Service Markup' : 'Tambah Service Markup'"
  >
    <template #body>
      <div class="space-y-4">
        <UFormField label="Service" required>
          <USelect
            v-model="form.service_id!"
            :items="serviceSelectItems"
            placeholder="Pilih service"
          />
        </UFormField>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Tipe Markup" required>
            <USelect
              v-model="form.markup_type"
              :items="[
                { label: 'Persentase', value: 'percentage' },
                { label: 'Nominal', value: 'fixed' }
              ]"
            />
          </UFormField>

          <UFormField label="Nilai Markup" required>
            <UInput
              v-model.number="form.markup_value"
              type="number"
              min="0"
              step="0.01"
            >
              <template v-if="form.markup_type === 'percentage'" #trailing>%</template>
              <template v-else #leading>Rp</template>
            </UInput>
          </UFormField>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Minimal Harga Akhir">
            <UInput
              v-model.number="form.min_final_price"
              type="number"
              min="0"
              step="1000"
            >
              <template #leading>Rp</template>
            </UInput>
          </UFormField>

          <UFormField label="Prioritas">
            <UInput
              v-model.number="form.priority"
              type="number"
              min="0"
            />
          </UFormField>
        </div>

        <UFormField label="Catatan">
          <UTextarea
            v-model="form.notes"
            placeholder="Catatan internal"
          />
        </UFormField>

        <UCheckbox
          v-model="form.is_active"
          label="Markup aktif"
        />
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end gap-2">
        <UButton
          color="neutral"
          variant="ghost"
          label="Batal"
          @click="modalOpen = false"
        />
        <UButton
          :loading="store.saving"
          label="Simpan"
          icon="i-lucide-save"
          @click="submit"
        />
      </div>
    </template>
  </UModal>

  <UModal v-model:open="deleteModalOpen" title="Hapus Service Markup">
    <template #body>
      <p class="text-sm text-muted">
        Yakin ingin menghapus markup untuk
        <strong>{{ deleteTarget ? serviceName(deleteTarget) : '-' }}</strong>?
      </p>
    </template>

    <template #footer>
      <div class="flex justify-end gap-2">
        <UButton
          color="neutral"
          variant="ghost"
          label="Batal"
          @click="deleteModalOpen = false"
        />
        <UButton
          color="error"
          :loading="store.saving"
          label="Hapus"
          icon="i-lucide-trash"
          @click="confirmDelete"
        />
      </div>
    </template>
  </UModal>
</template>
