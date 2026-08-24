<script setup lang="ts">
import { getOrder } from '~/services/admin/orders'

const route = useRoute()
const toast = useToast()

const id = computed(() => String(route.params.id || ''))

const { data, pending, error, refresh } = await useAsyncData(
  () => `order:${id.value}`,
  async () => {
    const res = await getOrder(id.value)
    return res.data
  },
  { watch: [id] }
)

const items = computed<any[]>(() => (data.value as any)?.items || [])
const prescriptionItems = computed<any[]>(() => (data.value as any)?.prescription?.items || [])
const shipmentHistories = computed<any[]>(() => (data.value as any)?.shipment?.histories || [])
const showDebug = ref(false)

async function copyId() {
  const value = String(data.value?.id || '')
  if (!value) return
  await globalThis.navigator?.clipboard?.writeText(value)
  toast.add({ title: 'Copied', description: 'Order ID disalin.' })
}
</script>

<template>
  <UDashboardPanel id="order-detail">
    <template #header>
      <UDashboardNavbar :title="data?.order_code ? `Order: ${data.order_code}` : 'Order Detail'">
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/orders')"
          />
        </template>

        <template #right>
          <UButton
            icon="i-lucide-copy"
            color="neutral"
            variant="outline"
            :disabled="!data?.id"
            @click="copyId"
          >
            Copy ID
          </UButton>
          <UButton
            icon="i-lucide-refresh-cw"
            color="neutral"
            variant="outline"
            :loading="pending"
            @click="refresh()"
          >
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

      <div v-else class="grid gap-4 lg:grid-cols-3">
        <UCard class="lg:col-span-2">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="space-y-0.5">
                <div class="text-sm text-dimmed">
                  Order
                </div>
                <div class="text-lg font-semibold">
                  {{ data?.order_code || `#${data?.id || '-'}` }}
                </div>
              </div>
              <UBadge variant="subtle" color="neutral">
                {{ data?.status || '-' }}
              </UBadge>
            </div>
          </template>

          <div class="grid gap-4 sm:grid-cols-3">
            <div>
              <div class="text-xs text-dimmed">
                Type
              </div>
              <div class="font-medium">
                {{ data?.order_type || '-' }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Created at
              </div>
              <div class="font-medium">
                {{ formatDateTime(data?.created_at) }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Total
              </div>
              <div class="font-medium">
                {{ data?.total_amount != null ? formatCurrencyIDR(data?.total_amount) : '-' }}
              </div>
            </div>
          </div>
        </UCard>

        <UCard>
          <template #header>
            <div class="text-sm text-dimmed">
              Patient
            </div>
          </template>

          <div class="space-y-1.5">
            <div class="font-semibold">
              {{ data?.patient?.name || '-' }}
            </div>
            <div class="text-sm text-dimmed">
              {{ data?.patient?.email || '-' }}
            </div>
            <div class="text-sm text-dimmed">
              {{ data?.patient?.phone || '-' }}
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-2">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="text-sm text-dimmed">
                Pharmacy
              </div>
              <UBadge v-if="data?.pharmacy?.id" variant="subtle" color="neutral">
                #{{ data.pharmacy.id }}
              </UBadge>
            </div>
          </template>

          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <div class="text-xs text-dimmed">
                Nama Apotek
              </div>
              <div class="font-medium">
                {{ data?.pharmacy?.profile?.name || '-' }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Owner
              </div>
              <div class="font-medium">
                {{ data?.pharmacy?.owner?.name || '-' }}
              </div>
              <div class="text-sm text-dimmed">
                {{ data?.pharmacy?.owner?.email || '' }}
              </div>
            </div>
          </div>
        </UCard>

        <UCard>
          <template #header>
            <div class="text-sm text-dimmed">
              Address
            </div>
          </template>

          <div class="space-y-1.5">
            <div class="font-medium">
              {{ data?.address?.name || '-' }}
            </div>
            <div class="text-sm text-dimmed">
              {{ data?.address?.phone || '-' }}
            </div>
            <div class="text-sm text-dimmed">
              {{ data?.address?.full_address || data?.address?.address || '-' }}
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="text-sm text-dimmed">
                Items
              </div>
              <UBadge variant="subtle" color="neutral">
                {{ items.length }} item(s)
              </UBadge>
            </div>
          </template>

          <div v-if="items.length" class="overflow-auto">
            <table class="w-full text-sm">
              <thead class="text-xs text-dimmed">
                <tr class="border-b border-default">
                  <th class="py-2 text-left font-medium">
                    Produk
                  </th>
                  <th class="py-2 text-left font-medium">
                    Apotek
                  </th>
                  <th class="py-2 text-right font-medium">
                    Qty
                  </th>
                  <th class="py-2 text-right font-medium">
                    Harga
                  </th>
                  <th class="py-2 text-right font-medium">
                    Subtotal
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(it, idx) in items"
                  :key="it?.id ?? idx"
                  class="border-b border-default last:border-b-0"
                >
                  <td class="py-2">
                    <div class="font-medium text-highlighted">
                      {{ it?.product?.name || it?.product_name || '-' }}
                    </div>
                    <div class="text-xs text-dimmed">
                      {{ it?.notes || '' }}
                    </div>
                  </td>
                  <td class="py-2">
                    {{ it?.product?.pharmacy?.profile?.name || '-' }}
                  </td>
                  <td class="py-2 text-right">
                    {{ it?.quantity ?? it?.qty ?? '-' }}
                  </td>
                  <td class="py-2 text-right">
                    {{ it?.price != null ? formatCurrencyIDR(it?.price) : '-' }}
                  </td>
                  <td class="py-2 text-right">
                    {{ it?.subtotal != null ? formatCurrencyIDR(it?.subtotal) : '-' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="text-sm text-dimmed">
            Tidak ada item.
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="text-sm text-dimmed">
                Shipment
              </div>
              <UBadge v-if="data?.shipment?.id" variant="subtle" color="neutral">
                #{{ data.shipment.id }}
              </UBadge>
            </div>
          </template>

          <div class="grid gap-4 lg:grid-cols-3">
            <div class="space-y-1.5">
              <div class="text-xs text-dimmed">
                Courier
              </div>
              <div class="font-medium">
                {{ data?.shipment?.courier?.name || '-' }}
              </div>
              <div class="text-sm text-dimmed">
                {{ data?.shipment?.courier?.email || '' }}
              </div>
            </div>

            <div class="space-y-1.5">
              <div class="text-xs text-dimmed">
                Tracking
              </div>
              <div class="font-medium">
                {{ data?.shipment?.tracking_number || data?.shipment?.tracking_code || '-' }}
              </div>
              <div class="text-sm text-dimmed">
                {{ data?.shipment?.status || '' }}
              </div>
            </div>

            <div class="space-y-1.5">
              <div class="text-xs text-dimmed">
                History
              </div>
              <div v-if="shipmentHistories.length" class="space-y-2">
                <div
                  v-for="(h, idx) in shipmentHistories"
                  :key="h?.id ?? idx"
                  class="rounded-lg border border-default p-2"
                >
                  <div class="text-sm font-medium">
                    {{ h?.status || '-' }}
                  </div>
                  <div class="text-xs text-dimmed">
                    {{ h?.description || h?.notes || '' }}
                  </div>
                </div>
              </div>
              <div v-else class="text-sm text-dimmed">
                Tidak ada history.
              </div>
            </div>
          </div>
        </UCard>

        <UCard v-if="data?.prescription" class="lg:col-span-3">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="text-sm text-dimmed">
                Prescription
              </div>
              <UBadge variant="subtle" color="neutral">
                {{ prescriptionItems.length }} item(s)
              </UBadge>
            </div>
          </template>

          <div class="grid gap-4 sm:grid-cols-3">
            <div>
              <div class="text-xs text-dimmed">
                Notes
              </div>
              <div class="font-medium">
                {{ data?.prescription?.notes || '-' }}
              </div>
            </div>
            <div class="sm:col-span-2">
              <div class="text-xs text-dimmed">
                Items
              </div>
              <div v-if="prescriptionItems.length" class="mt-1 grid gap-2 sm:grid-cols-2">
                <div
                  v-for="(it, idx) in prescriptionItems"
                  :key="it?.id ?? idx"
                  class="rounded-lg border border-default p-3"
                >
                  <div class="font-medium text-highlighted">
                    {{ it?.name || it?.product_name || '-' }}
                  </div>
                  <div class="text-xs text-dimmed">
                    {{ it?.dosage || it?.note || '' }}
                  </div>
                </div>
              </div>
              <div v-else class="text-sm text-dimmed">
                Tidak ada item resep.
              </div>
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="flex items-center justify-between gap-3">
              <div class="text-sm text-dimmed">
                Debug JSON
              </div>
              <UButton
                color="neutral"
                variant="outline"
                size="xs"
                :icon="showDebug ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                @click="showDebug = !showDebug"
              >
                {{ showDebug ? 'Hide' : 'Show' }}
              </UButton>
            </div>
          </template>

          <pre v-if="showDebug" class="text-xs overflow-auto max-h-[28rem]">{{ data }}</pre>
          <div v-else class="text-sm text-dimmed">
            Gunakan untuk debug jika ada field yang belum ditampilkan di UI.
          </div>
        </UCard>
      </div>

      <USkeleton v-if="pending" class="h-32 w-full mt-4" />
    </template>
  </UDashboardPanel>
</template>
