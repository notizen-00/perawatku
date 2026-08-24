<script setup lang="ts">
import { listServiceBookings } from '~/services/admin/service-bookings'

type StatusRecord = {
  status: string
  label: string
  count: number
  color: string
}

const STATUSES: { status: string, label: string, color: string }[] = [
  { status: 'pending', label: 'Menunggu', color: 'bg-amber-500' },
  { status: 'confirmed', label: 'Dikonfirmasi', color: 'bg-sky-500' },
  { status: 'on_the_way', label: 'Menuju Lokasi', color: 'bg-indigo-500' },
  { status: 'completed', label: 'Selesai', color: 'bg-emerald-500' },
  { status: 'cancelled', label: 'Dibatalkan', color: 'bg-rose-500' }
]

const { data, status } = await useAsyncData<StatusRecord[]>('home-booking-status', async () => {
  const results = await Promise.all(
    STATUSES.map(({ status: bookingStatus }) => listServiceBookings({ status: bookingStatus, per_page: 1 }))
  )

  return STATUSES.map((entry, index) => {
    const payload = results[index]?.data as any
    const count = Number(payload?.total ?? payload?.meta?.total ?? 0)
    return { ...entry, count }
  })
}, { default: () => [] })

const total = computed(() => (data.value ?? []).reduce((acc, item) => acc + item.count, 0))
const maxCount = computed(() => Math.max(1, ...(data.value ?? []).map(item => item.count)))
</script>

<template>
  <UCard :ui="{ body: 'pt-4' }">
    <template #header>
      <div>
        <p class="text-xs text-muted uppercase mb-1.5">
          Booking Layanan per Status
        </p>
        <p class="text-3xl text-highlighted font-semibold">
          {{ total }} total booking
        </p>
      </div>
    </template>

    <div v-if="status !== 'pending'" class="space-y-4 py-2">
      <div v-for="item in data" :key="item.status" class="flex items-center gap-3">
        <span class="w-36 shrink-0 text-xs text-muted truncate">{{ item.label }}</span>
        <div class="flex-1 h-3 rounded-full bg-elevated overflow-hidden">
          <div
            class="h-full rounded-full transition-all duration-500"
            :class="item.color"
            :style="{ width: `${(item.count / maxCount) * 100}%` }"
          />
        </div>
        <span class="w-10 shrink-0 text-right text-sm font-semibold text-highlighted">{{ item.count }}</span>
      </div>
      <p v-if="total === 0" class="text-sm text-muted text-center py-4">
        Belum ada booking layanan.
      </p>
    </div>
    <div v-else class="space-y-4 py-2">
      <USkeleton v-for="n in 5" :key="n" class="h-3 w-full" />
    </div>
  </UCard>
</template>
