<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import type { PromoCode } from "~/services/admin/promo-codes";

const UBadge = resolveComponent("UBadge");
const UButton = resolveComponent("UButton");
const UDropdownMenu = resolveComponent("UDropdownMenu");
const UInput = resolveComponent("UInput");
const USelect = resolveComponent("USelect");

const toast = useToast();

const search = ref("");
const statusFilter = ref("all");

const pagination = reactive({
  page: 1,
  perPage: 10,
  total: 0,
  lastPage: 1,
});

const promoCodesStore = usePromoCodesStore();

const query = computed(() => ({
  page: pagination.page,
  per_page: pagination.perPage,
  search: search.value?.trim() || undefined,
  is_active:
    statusFilter.value !== "all"
      ? statusFilter.value === "active"
        ? true
        : false
      : undefined,
}));

watchDebounced(
  search,
  async () => {
    pagination.page = 1;
    await promoCodesStore.fetch();
  },
  { debounce: 400, maxWait: 1200 },
);

watch(
  () => statusFilter.value,
  async () => {
    pagination.page = 1;
    await promoCodesStore.fetch();
  },
);

await callOnce(async () => {
  await promoCodesStore.fetch();
});

const addModal = useTemplateRef("addModal");
const deleteModal = useTemplateRef("deleteModal");

function getRowItems(row: any) {
  return [
    {
      label: "Edit",
      icon: "i-lucide-edit",
      onSelect() {
        addModal.value?.openEdit(row.original);
      },
    },
    {
      label: row.original.is_active ? "Nonaktifkan" : "Aktifkan",
      icon: row.original.is_active
        ? "i-lucide-toggle-left"
        : "i-lucide-toggle-right",
      async onSelect() {
        try {
          await promoCodesStore.toggleStatus(row.original.id);
          toast.add({
            title: "Berhasil",
            description: "Status diubah.",
            color: "success",
          });
        } catch {
          toast.add({
            title: "Error",
            description: "Gagal mengubah status.",
            color: "error",
          });
        }
      },
    },
    {
      label: "Hapus",
      icon: "i-lucide-trash",
      color: "error",
      onSelect() {
        deleteModal.value?.openDelete(row.original);
      },
    },
  ];
}

const columns: TableColumn<PromoCode>[] = [
  {
    accessorKey: "name",
    header: "Nama",
    cell: ({ row }) =>
      h("div", { class: "font-medium" }, row.original.name || "-"),
  },
  {
    accessorKey: "code",
    header: "Kode",
    cell: ({ row }) => h("div", { class: "text-dimmed" }, row.original.code),
  },
  {
    accessorKey: "discount",
    header: "Diskon",
    cell: ({ row }) => {
      const type = row.original.discount_type;
      const value = row.original.discount_value;
      const maxDiscount = row.original.max_discount;
      if (type === "percentage")
        return `${value}%${maxDiscount ? ` (Maks Rp ${maxDiscount})` : ""}`;
      return `Rp ${value.toLocaleString("id-ID")}`;
    },
  },
  {
    accessorKey: "valid_period",
    header: "Periode",
    cell: ({ row }) => {
      const from = new Date(row.original.valid_from).toLocaleDateString(
        "id-ID",
        { day: "numeric", month: "short", year: "numeric" },
      );
      const until = new Date(row.original.valid_until).toLocaleDateString(
        "id-ID",
        { day: "numeric", month: "short", year: "numeric" },
      );
      return `${from} - ${until}`;
    },
  },
  {
    accessorKey: "usage",
    header: "Penggunaan",
    cell: ({ row }) => {
      const count = row.original.usage_count;
      const limit = row.original.usage_limit;
      return limit ? `${count}/${limit}` : `${count}`;
    },
  },
  {
    accessorKey: "is_active",
    header: "Status",
    cell: ({ row }) => {
      const active = row.original.is_active;
      return h(
        UBadge,
        { variant: "subtle", color: active ? "success" : "error" },
        () => (active ? "Aktif" : "Tidak Aktif"),
      );
    },
  },
  {
    id: "actions",
    cell: ({ row }) =>
      h(
        "div",
        { class: "text-right" },
        h(
          UDropdownMenu,
          {
            content: {
              align: "end",
            },
            items: getRowItems(row),
          },
          () =>
            h(UButton, {
              icon: "i-lucide-ellipsis-vertical",
              color: "neutral",
              variant: "ghost",
              class: "ml-auto",
            }),
        ),
      ),
  },
];
</script>

<template>
  <UDashboardPanel id="promo-codes">
    <template #header>
      <UDashboardNavbar title="Promo Codes">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <PromoCodesAddModal />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-1.5">
        <UInput
          v-model="search"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Cari nama/kode promo..."
        />

        <div class="flex flex-wrap items-center gap-1.5">
          <USelect
            v-model="statusFilter"
            class="min-w-28"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'Aktif', value: 'active' },
              { label: 'Tidak Aktif', value: 'inactive' },
            ]"
            placeholder="Filter status"
          />
        </div>
      </div>

      <UTable
        :data="promoCodesStore.items"
        :columns="columns"
        :loading="promoCodesStore.loading"
        :ui="{
          base: 'table-fixed border-separate border-spacing-0',
          thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
          tbody: '[&>tr]:last:[&>td]:border-b-0',
          th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
          td: 'border-b border-default',
          separator: 'h-0',
        }"
      />

      <div
        class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-auto"
      >
        <div class="text-sm text-muted">
          Total: {{ promoCodesStore.pagination.total }}
        </div>

        <UPagination
          :page="pagination.page"
          :items-per-page="pagination.perPage"
          :total="promoCodesStore.pagination.total"
          @update:page="
            (p: number) => {
              pagination.page = p;
              promoCodesStore.fetch();
            }
          "
        />
      </div>
    </template>
  </UDashboardPanel>

  <!-- <PromoCodesDeleteModal
    ref="deleteModal"
    :count="0"
    @refresh="promoCodesStore.fetch()"
  /> -->
</template>
