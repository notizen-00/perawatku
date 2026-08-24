<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'
import {
  getServiceBookingFee,
  updateServiceBookingFee
} from '~/services/admin/service-booking-fees'

const toast = useToast()
const loading = ref(true)
const saving = ref(false)

const schema = z.object({
  transport_distance_threshold_km: z.coerce.number()
    .min(0, 'Ambang jarak minimal 0 km')
    .max(1000, 'Ambang jarak maksimal 1.000 km'),
  transport_fee_per_visit: z.coerce.number().min(0, 'Biaya tidak boleh negatif'),
  hospital_meal_fee_per_visit: z.coerce.number().min(0, 'Biaya tidak boleh negatif'),
  is_active: z.boolean()
})

type Schema = z.output<typeof schema>

const state = reactive<Schema>({
  transport_distance_threshold_km: 0,
  transport_fee_per_visit: 0,
  hospital_meal_fee_per_visit: 0,
  is_active: true
})

function errorMessage(error: any, fallback: string) {
  return error?.data?.message || error?.message || fallback
}

async function load() {
  loading.value = true
  try {
    const response = await getServiceBookingFee()
    Object.assign(state, response.data)
  }
  catch (error) {
    toast.add({
      title: 'Gagal memuat pengaturan',
      description: errorMessage(error, 'Kebijakan biaya service booking tidak dapat dimuat.'),
      color: 'error'
    })
  }
  finally {
    loading.value = false
  }
}

async function onSubmit(event: FormSubmitEvent<Schema>) {
  saving.value = true
  try {
    const response = await updateServiceBookingFee(event.data)
    Object.assign(state, response.data)
    toast.add({
      title: 'Pengaturan tersimpan',
      description: response.message || 'Kebijakan biaya berlaku untuk booking baru.',
      icon: 'i-lucide-check',
      color: 'success'
    })
  }
  catch (error) {
    toast.add({
      title: 'Gagal menyimpan pengaturan',
      description: errorMessage(error, 'Periksa kembali nilai yang dimasukkan.'),
      color: 'error'
    })
  }
  finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <UForm :schema="schema" :state="state" class="space-y-6" @submit="onSubmit">
    <UPageCard
      title="Biaya Service Booking"
      description="Atur biaya tambahan yang dihitung saat pasien membuat booking baru."
      variant="naked"
      orientation="horizontal"
    >
      <UButton
        type="submit"
        label="Simpan perubahan"
        icon="i-lucide-save"
        color="neutral"
        :loading="saving"
        :disabled="loading"
        class="w-fit lg:ms-auto"
      />
    </UPageCard>

    <UPageCard variant="subtle" :ui="{ container: 'divide-y divide-default' }">
      <UFormField
        name="transport_distance_threshold_km"
        label="Ambang jarak transport"
        description="Biaya transport dikenakan untuk booking berulang non-live-in di atas jarak ini."
        required
        class="flex max-sm:flex-col justify-between items-start gap-4 py-4 first:pt-0 last:pb-0"
      >
        <UInput
          v-model.number="state.transport_distance_threshold_km"
          type="number"
          min="0"
          max="1000"
          step="0.1"
          :disabled="loading"
          class="w-full sm:w-52"
        >
          <template #trailing>km</template>
        </UInput>
      </UFormField>

      <UFormField
        name="transport_fee_per_visit"
        label="Biaya transport per kunjungan"
        description="Nominal transport untuk setiap kunjungan yang memenuhi ketentuan jarak."
        required
        class="flex max-sm:flex-col justify-between items-start gap-4 py-4 first:pt-0 last:pb-0"
      >
        <UInput
          v-model.number="state.transport_fee_per_visit"
          type="number"
          min="0"
          step="1000"
          :disabled="loading"
          class="w-full sm:w-52"
        >
          <template #leading>Rp</template>
        </UInput>
      </UFormField>

      <UFormField
        name="hospital_meal_fee_per_visit"
        label="Uang makan rumah sakit"
        description="Uang makan per kunjungan jika lokasi layanan berada di rumah sakit."
        required
        class="flex max-sm:flex-col justify-between items-start gap-4 py-4 first:pt-0 last:pb-0"
      >
        <UInput
          v-model.number="state.hospital_meal_fee_per_visit"
          type="number"
          min="0"
          step="1000"
          :disabled="loading"
          class="w-full sm:w-52"
        >
          <template #leading>Rp</template>
        </UInput>
      </UFormField>

      <UFormField
        name="is_active"
        label="Aktifkan kebijakan"
        description="Perubahan hanya berlaku pada booking yang dibuat setelah pengaturan disimpan."
        class="flex items-center justify-between gap-4 py-4 first:pt-0 last:pb-0"
      >
        <USwitch v-model="state.is_active" :disabled="loading" />
      </UFormField>
    </UPageCard>
  </UForm>
</template>
