<script setup lang="ts">
const props = defineProps<{
  count: number;
}>();

const open = ref(false);
const currentDeletingPromoCode = ref<any>(null);

const toast = useToast();

function openDelete(promoCode: any) {
  currentDeletingPromoCode.value = promoCode;
  open.value = true;
}

function close() {
  open.value = false;
  currentDeletingPromoCode.value = null;
}

async function onSubmit() {
  try {
    if (currentDeletingPromoCode.value) {
      const { deletePromoCode } = await import("~/services/admin/promo-codes");
      await deletePromoCode(currentDeletingPromoCode.value.id);
      toast.add({
        title: "Berhasil",
        description: "Promo code dihapus.",
        color: "success",
      });
      close();
      emit("refresh");
    }
  } catch (e: any) {
    toast.add({
      title: "Error",
      description: e?.data?.message || "Gagal menghapus promo code.",
      color: "error",
    });
  }
}

const emit = defineEmits<(e: "refresh") => void>();

defineExpose({ openDelete });
</script>

<template>
  <UModal v-model:open="open">
    <template #header>
      <h3 class="text-lg font-semibold">Hapus Promo Code</h3>
    </template>

    <div class="p-6">
      <p class="text-dimmed mb-6">
        {{
          currentDeletingPromoCode
            ? `Apakah Anda yakin ingin menghapus promo code "${currentDeletingPromoCode.code}"?`
            : "Apakah Anda yakin ingin menghapus promo code ini?"
        }}
      </p>

      <div class="flex justify-end gap-2">
        <UButton variant="ghost" @click="close">Batal</UButton>
        <UButton color="error" @click="onSubmit">Hapus</UButton>
      </div>
    </div>
  </UModal>
</template>
