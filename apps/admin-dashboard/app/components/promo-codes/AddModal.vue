<script setup lang="ts">
import type {
  PromoCode,
  CreatePromoCodePayload,
} from "~/services/admin/promo-codes";

const emit = defineEmits<(e: "refresh") => void>();

const open = ref(false);
const isEdit = ref(false);
const editingId = ref<number | null>(null);

const formData = ref<CreatePromoCodePayload>({
  name: "",
  code: "",
  description: "",
  discount_type: "percentage",
  discount_value: 0,
  min_transaction: 0,
  max_discount: 0,
  valid_from: "",
  valid_until: "",
  usage_limit: 0,
});

const toast = useToast();

function resetForm() {
  formData.value = {
    name: "",
    code: "",
    description: "",
    discount_type: "percentage",
    discount_value: 0,
    min_transaction: 0,
    max_discount: 0,
    valid_from: new Date().toISOString().slice(0, 16),
    valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 16),
    usage_limit: 0,
  };
  isEdit.value = false;
  editingId.value = null;
}

function openCreate() {
  resetForm();
  open.value = true;
}

function openEdit(promoCode: PromoCode) {
  formData.value = {
    name: promoCode.name || "",
    code: promoCode.code,
    description: promoCode.description || "",
    discount_type: promoCode.discount_type,
    discount_value: promoCode.discount_value,
    min_transaction: promoCode.min_transaction || 0,
    max_discount: promoCode.max_discount || 0,
    valid_from: promoCode.valid_from.slice(0, 16),
    valid_until: promoCode.valid_until.slice(0, 16),
    usage_limit: promoCode.usage_limit || 0,
  };
  editingId.value = promoCode.id;
  isEdit.value = true;
  open.value = true;
}

function close() {
  open.value = false;
  resetForm();
}

async function onSubmit() {
  try {
    if (isEdit.value && editingId.value) {
      const { updatePromoCode } = await import("~/services/admin/promo-codes");
      await updatePromoCode(editingId.value, formData.value);
      toast.add({
        title: "Berhasil",
        description: "Promo code diperbarui.",
        color: "success",
      });
    } else {
      const { createPromoCode } = await import("~/services/admin/promo-codes");
      await createPromoCode(formData.value);
      toast.add({
        title: "Berhasil",
        description: "Promo code dibuat.",
        color: "success",
      });
    }
    close();
    emit("refresh");
  } catch (e: any) {
    toast.add({
      title: "Error",
      description: e?.data?.message || "Gagal menyimpan promo code.",
      color: "error",
    });
  }
}

defineExpose({ openCreate, openEdit });
</script>

<template>
  <UModal v-model:open="open">
    <UButton label="New Promo Code" icon="i-lucide-plus" />
    <template #header>
      <h3 class="text-lg font-semibold">
        {{ isEdit ? "Edit Promo Code" : "Tambah Promo Code" }}
      </h3>
    </template>

    <template #body>
      <UForm :state="formData" @submit="onSubmit">
        <div class="space-y-4">
          <UFormField label="Nama Promo" name="name" required>
            <UInput
              v-model="formData.name"
              placeholder="Contoh: Promo Lebaran 2024"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Kode Promo" name="code" required>
            <UInput
              v-model="formData.code"
              placeholder="Contoh: LEBARAN24"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Deskripsi" name="description">
            <UTextarea
              v-model="formData.description"
              :rows="2"
              placeholder="Deskripsi promo (opsional)"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Tipe Diskon" name="discount_type" required>
            <USelect
              v-model="formData.discount_type"
              :items="[
                { label: 'Persentase (%)', value: 'percentage' },
                { label: 'Nominal (Rp)', value: 'fixed' },
              ]"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Nilai Diskon" name="discount_value" required>
            <UInput
              v-model.number="formData.discount_value"
              type="number"
              min="0"
              placeholder="0"
              class="w-full"
            />
          </UFormField>

          <UFormField
            v-if="formData.discount_type === 'percentage'"
            label="Maksimal Diskon (Rp)"
            name="max_discount"
          >
            <UInput
              v-model.number="formData.max_discount"
              type="number"
              min="0"
              placeholder="0"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Minimal Transaksi (Rp)" name="min_transaction">
            <UInput
              v-model.number="formData.min_transaction"
              type="number"
              min="0"
              placeholder="0"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Batas Penggunaan" name="usage_limit">
            <UInput
              v-model.number="formData.usage_limit"
              type="number"
              min="0"
              placeholder="0"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Berlaku dari" name="valid_from" required>
            <UInput
              v-model="formData.valid_from"
              type="datetime-local"
              class="w-full"
            />
          </UFormField>

          <UFormField label="Berlaku sampai" name="valid_until" required>
            <UInput
              v-model="formData.valid_until"
              type="datetime-local"
              class="w-full"
            />
          </UFormField>
        </div>

        <div class="flex justify-end gap-2 mt-6">
          <UButton
            label="Batal"
            color="neutral"
            variant="subtle"
            @click="close"
          />
          <UButton
            type="submit"
            color="primary"
            :label="isEdit ? 'Simpan' : 'Buat'"
          />
        </div>
      </UForm>
    </template>
  </UModal>
</template>
