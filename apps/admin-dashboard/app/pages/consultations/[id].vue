<script setup lang="ts">
import { getConsultation } from '~/services/admin/consultations'

const route = useRoute()
const toast = useToast()

const id = computed(() => String(route.params.id || ''))

const { data, pending, error, refresh } = await useAsyncData(
  () => `consultation:${id.value}`,
  async () => {
    const res = await getConsultation(id.value)
    return res.data
  },
  { watch: [id] }
)

const showDebug = ref(false)

async function copyId() {
  const value = String(data.value?.id || '')
  if (!value) return
  await globalThis.navigator?.clipboard?.writeText(value)
  toast.add({ title: 'Copied', description: 'Consultation ID disalin.' })
}
</script>

<template>
  <UDashboardPanel id="consultation-detail">
    <template #header>
      <UDashboardNavbar :title="data?.consultation_code ? `Consultation: ${data.consultation_code}` : 'Consultation Detail'">
        <template #leading>
          <UButton icon="i-lucide-arrow-left" color="neutral" variant="ghost" @click="navigateTo('/consultations')" />
        </template>

        <template #right>
          <UButton icon="i-lucide-copy" color="neutral" variant="outline" :disabled="!data?.id" @click="copyId">
            Copy ID
          </UButton>
          <UButton icon="i-lucide-refresh-cw" color="neutral" variant="outline" :loading="pending" @click="refresh()">
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
                  Konsultasi
                </div>
                <div class="text-lg font-semibold">
                  {{ data?.consultation_code || `#${data?.id || '-'}` }}
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
                Service
              </div>
              <div class="font-medium">
                {{ data?.service_type || '-' }}
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
                Payment
              </div>
              <div class="font-medium">
                {{ data?.payment?.status || '-' }}
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
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="text-sm text-dimmed">
              Partner
            </div>
          </template>
          <div class="grid gap-4 sm:grid-cols-3">
            <div>
              <div class="text-xs text-dimmed">
                Nama
              </div>
              <div class="font-medium">
                {{ data?.partner?.name || '-' }}
              </div>
              <div class="text-sm text-dimmed">
                {{ data?.partner?.email || '' }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Profesi
              </div>
              <div class="font-medium">
                {{ data?.partner?.partner_profile?.profession || '-' }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Spesialisasi
              </div>
              <div class="font-medium">
                {{ data?.partner?.partner_profile?.specialization || '-' }}
              </div>
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="text-sm text-dimmed">
              Keluhan & Diagnosis
            </div>
          </template>
          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <div class="text-xs text-dimmed">
                Complaint
              </div>
              <div class="font-medium whitespace-pre-wrap">
                {{ data?.complaint || '-' }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">
                Diagnosis
              </div>
              <div class="font-medium whitespace-pre-wrap">
                {{ data?.diagnosis || '-' }}
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

