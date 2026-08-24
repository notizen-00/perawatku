<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import type { ServiceCategory } from "~/services/admin/services-categories";
import type {
  CreateServicePayload,
  Service,
  ServiceMode,
} from "~/services/admin/services";

const UBadge = resolveComponent("UBadge");
const UButton = resolveComponent("UButton");
const UDropdownMenu = resolveComponent("UDropdownMenu");

const toast = useToast();

const categoriesStore = useServiceCategoriesStore();
const servicesStore = useServicesStore();

const activeSection = ref<"categories" | "services">("categories");

const categoryModalOpen = ref(false);
const serviceModalOpen = ref(false);
const deleteModalOpen = ref(false);

const categoryEditing = ref<ServiceCategory | null>(null);
const serviceEditing = ref<Service | null>(null);
const deleteTarget = ref<{
  type: "category" | "service";
  item: ServiceCategory | Service;
} | null>(null);

const categoryForm = reactive({
  name: "",
  slug: "",
  description: "",
  icon: "",
  sort_order: 0,
  is_active: true,
});

const serviceForm = reactive({
  service_code: "",
  service_category_id: null as number | null,
  name: "",
  slug: "",
  description: "",
  service_type: "consultation",
  service_mode: "visit" as ServiceMode,
  category: "",
  base_price: 0,
  duration_minutes: 60,
  icon: "",
  requires_address: false,
  requires_schedule: false,
  requires_matchmaking: false,
  is_homecare: false,
  sort_order: 0,
  image_path: "",
  image: null as File | null,
  remove_image: false,
  is_active: true,
});

const serviceImagePreview = ref<string | null>(null);

const serviceTypeItems = [
  { label: "Konsultasi", value: "consultation" },
  { label: "Tindakan / Procedure", value: "procedure" },
  { label: "Caregiver", value: "caregiver" },
  { label: "Homecare", value: "homecare" },
  { label: "Dokter Homecare", value: "dokter_homecare" },
  { label: "Perawat Homecare", value: "perawat_homecare" },
  { label: "Bidan Homecare", value: "bidan_homecare" },
  { label: "Konsultasi Tindakan", value: "konsultasi_tindakan" },
];

const serviceModeItems = [
  { label: "Chat", value: "chat" },
  { label: "Voice", value: "voice" },
  { label: "Video", value: "video" },
  { label: "Visit / Kunjungan", value: "visit" },
];

const statusItems = [
  { label: "Semua", value: "all" },
  { label: "Aktif", value: "active" },
  { label: "Tidak Aktif", value: "inactive" },
];

const categoryFilterItems = computed(() => [
  { label: "Semua Kategori", value: 0 },
  ...categoriesStore.items.map((item) => ({
    label: item.name,
    value: item.id,
  })),
]);

const categorySelectItems = computed(() =>
  categoriesStore.items.map((item) => ({
    label: item.name,
    value: item.id,
  })),
);

watchDebounced(
  () => categoriesStore.filters.search,
  async () => {
    categoriesStore.pagination.page = 1;
    await categoriesStore.fetch();
  },
  { debounce: 400, maxWait: 1200 },
);

watch(
  () => categoriesStore.filters.status,
  async () => {
    categoriesStore.pagination.page = 1;
    await categoriesStore.fetch();
  },
);

watchDebounced(
  () => servicesStore.filters.search,
  async () => {
    servicesStore.pagination.page = 1;
    await servicesStore.fetch();
  },
  { debounce: 400, maxWait: 1200 },
);

watch(
  () => [
    servicesStore.filters.status,
    servicesStore.filters.serviceCategoryId,
    servicesStore.filters.serviceType,
  ],
  async () => {
    servicesStore.pagination.page = 1;
    await servicesStore.fetch();
  },
);

await callOnce(async () => {
  await Promise.all([categoriesStore.fetch(), servicesStore.fetch()]);
});

function formatCurrency(value?: number | null) {
  return `Rp ${Number(value || 0).toLocaleString("id-ID")}`;
}

function resetCategoryForm() {
  categoryEditing.value = null;
  categoryForm.name = "";
  categoryForm.slug = "";
  categoryForm.description = "";
  categoryForm.icon = "";
  categoryForm.sort_order = 0;
  categoryForm.is_active = true;
}

function resetServiceForm() {
  serviceEditing.value = null;
  serviceImagePreview.value = null;
  serviceForm.service_code = "";
  serviceForm.service_category_id = categoriesStore.items[0]?.id || null;
  serviceForm.name = "";
  serviceForm.slug = "";
  serviceForm.description = "";
  serviceForm.service_type = "consultation";
  serviceForm.service_mode = "visit";
  serviceForm.category = "";
  serviceForm.base_price = 0;
  serviceForm.duration_minutes = 60;
  serviceForm.icon = "";
  serviceForm.requires_address = false;
  serviceForm.requires_schedule = false;
  serviceForm.requires_matchmaking = false;
  serviceForm.is_homecare = false;
  serviceForm.sort_order = 0;
  serviceForm.image_path = "";
  serviceForm.image = null;
  serviceForm.remove_image = false;
  serviceForm.is_active = true;
}

function openCreateCategory() {
  resetCategoryForm();
  categoryModalOpen.value = true;
}

function openEditCategory(item: ServiceCategory) {
  categoryEditing.value = item;
  categoryForm.name = item.name || "";
  categoryForm.slug = item.slug || "";
  categoryForm.description = item.description || "";
  categoryForm.icon = item.icon || "";
  categoryForm.sort_order = Number(item.sort_order || 0);
  categoryForm.is_active = Boolean(item.is_active);
  categoryModalOpen.value = true;
}

function openCreateService() {
  resetServiceForm();
  serviceModalOpen.value = true;
}

function handleServiceImageChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0] || null;

  if (file) {
    serviceForm.image = file;
    serviceForm.remove_image = false;
    serviceImagePreview.value = URL.createObjectURL(file);
  } else {
    serviceForm.image = null;
    serviceImagePreview.value = serviceEditing.value?.image_url || null;
  }
}

function removeServiceImage() {
  serviceForm.image = null;
  serviceForm.remove_image = true;
  serviceImagePreview.value = null;
}

function openEditService(item: Service) {
  serviceEditing.value = item;
  serviceImagePreview.value = item.image_url || null;
  serviceForm.service_code = item.service_code || "";
  serviceForm.service_category_id =
    Number(
      item.service_category_id || item.category_id || item.category?.id || 0,
    ) || null;
  serviceForm.name = item.name || "";
  serviceForm.slug = item.slug || "";
  serviceForm.description = item.description || "";
  serviceForm.service_type = item.service_type || "consultation";
  serviceForm.service_mode = (item.service_mode || "visit") as ServiceMode;
  serviceForm.category = "";
  serviceForm.base_price = Number(item.base_price || item.price || 0);
  serviceForm.duration_minutes = Number(item.duration_minutes || 0);
  serviceForm.icon = item.icon || "";
  serviceForm.requires_address = Boolean(item.requires_address);
  serviceForm.requires_schedule = Boolean(item.requires_schedule);
  serviceForm.requires_matchmaking = Boolean(item.requires_matchmaking);
  serviceForm.is_homecare = Boolean(item.is_homecare);
  serviceForm.sort_order = Number(item.sort_order || 0);
  serviceForm.image_path = "";
  serviceForm.image = null;
  serviceForm.remove_image = false;
  serviceForm.is_active = Boolean(item.is_active);
  serviceModalOpen.value = true;
}

async function submitCategory() {
  if (!categoryForm.name.trim()) {
    toast.add({
      title: "Validasi",
      description: "Nama kategori wajib diisi.",
      color: "warning",
    });
    return;
  }

  const payload = {
    name: categoryForm.name.trim(),
    slug: categoryForm.slug.trim() || undefined,
    description: categoryForm.description.trim() || undefined,
    icon: categoryForm.icon.trim() || undefined,
    sort_order: Number(categoryForm.sort_order || 0),
    is_active: categoryForm.is_active,
  };

  try {
    if (categoryEditing.value) {
      await categoriesStore.update(categoryEditing.value.id, payload);
    } else {
      await categoriesStore.create(payload);
    }

    categoryModalOpen.value = false;
    toast.add({
      title: "Berhasil",
      description: "Kategori layanan berhasil disimpan.",
      color: "success",
    });
  } catch (e: any) {
    toast.add({
      title: "Error",
      description:
        e?.data?.message || e?.message || "Gagal menyimpan kategori layanan.",
      color: "error",
    });
  }
}

async function submitService() {
  if (!serviceForm.service_category_id) {
    toast.add({
      title: "Validasi",
      description: "Kategori layanan wajib dipilih.",
      color: "warning",
    });
    return;
  }

  if (!serviceForm.name.trim()) {
    toast.add({
      title: "Validasi",
      description: "Nama layanan wajib diisi.",
      color: "warning",
    });
    return;
  }

  const payload: CreateServicePayload = {
    service_category_id: Number(serviceForm.service_category_id),
    name: serviceForm.name.trim(),
    slug: serviceForm.slug.trim() || undefined,
    description: serviceForm.description.trim() || undefined,
    service_type: serviceForm.service_type,
    service_mode: serviceForm.service_mode,
    base_price: Number(serviceForm.base_price || 0),
    duration_minutes: Number(serviceForm.duration_minutes || 0),
    icon: serviceForm.icon.trim() || undefined,
    is_active: serviceForm.is_active,
    remove_image: false,
  };

  if (serviceForm.service_code.trim())
    payload.service_code = serviceForm.service_code.trim();
  if (serviceForm.category.trim())
    payload.category = serviceForm.category.trim();
  if (serviceForm.image_path.trim())
    payload.image_path = serviceForm.image_path.trim();
  payload.requires_address = serviceForm.requires_address;
  payload.requires_schedule = serviceForm.requires_schedule;
  payload.requires_matchmaking = serviceForm.requires_matchmaking;
  payload.is_homecare = serviceForm.is_homecare;
  if (Number(serviceForm.sort_order || 0))
    payload.sort_order = Number(serviceForm.sort_order);
  if (serviceForm.image) payload.image = serviceForm.image;
  if (serviceEditing.value && serviceForm.remove_image)
    payload.remove_image = true;

  try {
    if (serviceEditing.value) {
      await servicesStore.update(serviceEditing.value.id, payload);
    } else {
      await servicesStore.create(payload);
    }

    serviceModalOpen.value = false;
    toast.add({
      title: "Berhasil",
      description: "Layanan berhasil disimpan.",
      color: "success",
    });
  } catch (e: any) {
    toast.add({
      title: "Error",
      description: e?.data?.message || e?.message || "Gagal menyimpan layanan.",
      color: "error",
    });
  }
}

function openDelete(
  type: "category" | "service",
  item: ServiceCategory | Service,
) {
  deleteTarget.value = { type, item };
  deleteModalOpen.value = true;
}

async function confirmDelete() {
  if (!deleteTarget.value) return;

  try {
    if (deleteTarget.value.type === "category") {
      await categoriesStore.remove(deleteTarget.value.item.id);
    } else {
      await servicesStore.remove(deleteTarget.value.item.id);
    }

    deleteModalOpen.value = false;
    toast.add({
      title: "Berhasil",
      description: "Data berhasil dihapus.",
      color: "success",
    });
  } catch (e: any) {
    toast.add({
      title: "Error",
      description: e?.data?.message || e?.message || "Gagal menghapus data.",
      color: "error",
    });
  }
}

async function toggleCategoryStatus(item: ServiceCategory) {
  try {
    await categoriesStore.toggleStatus(item.id);
    toast.add({
      title: "Berhasil",
      description: "Status kategori diubah.",
      color: "success",
    });
  } catch {
    toast.add({
      title: "Error",
      description: "Gagal mengubah status kategori.",
      color: "error",
    });
  }
}

async function toggleServiceStatus(item: Service) {
  try {
    await servicesStore.toggleStatus(item.id);
    toast.add({
      title: "Berhasil",
      description: "Status layanan diubah.",
      color: "success",
    });
  } catch {
    toast.add({
      title: "Error",
      description: "Gagal mengubah status layanan.",
      color: "error",
    });
  }
}

function getCategoryRowItems(row: any) {
  return [
    {
      label: "Edit",
      icon: "i-lucide-edit",
      onSelect() {
        openEditCategory(row.original);
      },
    },
    {
      label: row.original.is_active ? "Nonaktifkan" : "Aktifkan",
      icon: row.original.is_active
        ? "i-lucide-toggle-left"
        : "i-lucide-toggle-right",
      onSelect() {
        toggleCategoryStatus(row.original);
      },
    },
    {
      label: "Hapus",
      icon: "i-lucide-trash",
      color: "error",
      onSelect() {
        openDelete("category", row.original);
      },
    },
  ];
}

function getServiceRowItems(row: any) {
  return [
    {
      label: "Edit",
      icon: "i-lucide-edit",
      onSelect() {
        openEditService(row.original);
      },
    },
    {
      label: row.original.is_active ? "Nonaktifkan" : "Aktifkan",
      icon: row.original.is_active
        ? "i-lucide-toggle-left"
        : "i-lucide-toggle-right",
      onSelect() {
        toggleServiceStatus(row.original);
      },
    },
    {
      label: "Hapus",
      icon: "i-lucide-trash",
      color: "error",
      onSelect() {
        openDelete("service", row.original);
      },
    },
  ];
}

const categoryColumns: TableColumn<ServiceCategory>[] = [
  {
    accessorKey: "name",
    header: "Kategori",
    cell: ({ row }) =>
      h("div", [
        h("div", { class: "font-medium" }, row.original.name),
        h(
          "div",
          { class: "text-sm text-muted" },
          row.original.description || "-",
        ),
      ]),
  },
  {
    accessorKey: "slug",
    header: "Slug",
    cell: ({ row }) =>
      h("div", { class: "text-dimmed" }, row.original.slug || "-"),
  },
  {
    accessorKey: "services_count",
    header: "Jumlah Service",
    cell: ({ row }) => String(row.original.services_count || 0),
  },
  {
    accessorKey: "sort_order",
    header: "Urutan",
    cell: ({ row }) => String(row.original.sort_order || 0),
  },
  {
    accessorKey: "is_active",
    header: "Status",
    cell: ({ row }) =>
      h(
        UBadge,
        {
          variant: "subtle",
          color: row.original.is_active ? "success" : "error",
        },
        () => (row.original.is_active ? "Aktif" : "Tidak Aktif"),
      ),
  },
  {
    id: "actions",
    cell: ({ row }) =>
      h(
        "div",
        { class: "text-right" },
        h(
          UDropdownMenu,
          { content: { align: "end" }, items: getCategoryRowItems(row) },
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

const serviceColumns: TableColumn<Service>[] = [
  {
    accessorKey: "image",
    header: "Image",
    cell: ({ row }) => {
      const imageUrl = row.original.image_url || "";

      return imageUrl
        ? h("img", {
            src: imageUrl,
            alt: row.original.name,
            class:
              "h-12 w-12 shrink-0 rounded-md border border-default object-cover",
          })
        : h(
            "div",
            {
              class:
                "flex h-12 w-12 shrink-0 items-center justify-center rounded-md border border-default bg-elevated/50",
            },
            h("i", { class: "i-lucide-image-off text-lg text-muted" }),
          );
    },
  },
  {
    accessorKey: "name",
    header: "Service",
    cell: ({ row }) =>
      h("div", [
        h("div", { class: "font-medium" }, row.original.name),
        h(
          "div",
          { class: "text-sm text-muted" },
          row.original.description || "-",
        ),
      ]),
  },
  {
    accessorKey: "category",
    header: "Kategori",
    cell: ({ row }) =>
      row.original.category?.name ||
      categoriesStore.items.find(
        (item) =>
          item.id ===
          (row.original.service_category_id || row.original.category_id),
      )?.name ||
      "-",
  },
  {
    accessorKey: "service_type",
    header: "Tipe",
    cell: ({ row }) =>
      h(
        UBadge,
        { variant: "soft", color: "info" },
        () => row.original.service_type || "-",
      ),
  },
  {
    accessorKey: "base_price",
    header: "Harga Dasar",
    cell: ({ row }) =>
      formatCurrency(row.original.base_price || row.original.price),
  },
  {
    accessorKey: "duration_minutes",
    header: "Durasi",
    cell: ({ row }) =>
      row.original.duration_minutes
        ? `${row.original.duration_minutes} menit`
        : "-",
  },
  {
    accessorKey: "is_active",
    header: "Status",
    cell: ({ row }) =>
      h(
        UBadge,
        {
          variant: "subtle",
          color: row.original.is_active ? "success" : "error",
        },
        () => (row.original.is_active ? "Aktif" : "Tidak Aktif"),
      ),
  },
  {
    id: "actions",
    cell: ({ row }) =>
      h(
        "div",
        { class: "text-right" },
        h(
          UDropdownMenu,
          { content: { align: "end" }, items: getServiceRowItems(row) },
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
  <UDashboardPanel id="services">
    <template #header>
      <UDashboardNavbar title="Services">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UButton
            v-if="activeSection === 'categories'"
            icon="i-lucide-plus"
            label="Tambah Kategori"
            @click="openCreateCategory"
          />
          <UButton
            v-else
            icon="i-lucide-plus"
            label="Tambah Service"
            @click="openCreateService"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex flex-wrap items-center gap-1.5">
          <UButton
            :variant="activeSection === 'categories' ? 'solid' : 'outline'"
            icon="i-lucide-folder-tree"
            label="Service Category"
            @click="activeSection = 'categories'"
          />
          <UButton
            :variant="activeSection === 'services' ? 'solid' : 'outline'"
            icon="i-lucide-stethoscope"
            label="Service"
            @click="activeSection = 'services'"
          />
        </div>
      </div>

      <div v-if="activeSection === 'categories'" class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-1.5">
          <UInput
            v-model="categoriesStore.filters.search"
            class="max-w-sm"
            icon="i-lucide-search"
            placeholder="Cari kategori layanan..."
          />

          <USelect
            v-model="categoriesStore.filters.status"
            class="min-w-32"
            :items="statusItems"
            placeholder="Filter status"
          />
        </div>

        <UAlert
          v-if="categoriesStore.error"
          color="error"
          variant="subtle"
          icon="i-lucide-alert-circle"
          :description="categoriesStore.error"
        />

        <UTable
          :data="categoriesStore.items"
          :columns="categoryColumns"
          :loading="categoriesStore.loading"
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
            Total: {{ categoriesStore.pagination.total }}
          </div>

          <UPagination
            :page="categoriesStore.pagination.page"
            :items-per-page="categoriesStore.pagination.perPage"
            :total="categoriesStore.pagination.total"
            @update:page="
              (p: number) => {
                categoriesStore.pagination.page = p;
                categoriesStore.fetch();
              }
            "
          />
        </div>
      </div>

      <div v-else class="space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-1.5">
          <UInput
            v-model="servicesStore.filters.search"
            class="max-w-sm"
            icon="i-lucide-search"
            placeholder="Cari service..."
          />

          <div class="flex flex-wrap items-center gap-1.5">
            <USelect
              :model-value="servicesStore.filters.serviceCategoryId || 0"
              class="min-w-44"
              :items="categoryFilterItems"
              placeholder="Filter kategori"
              @update:model-value="
                (value: number) => {
                  servicesStore.filters.serviceCategoryId = value
                    ? Number(value)
                    : null;
                }
              "
            />
            <USelect
              v-model="servicesStore.filters.serviceType"
              class="min-w-40"
              :items="[
                { label: 'Semua Tipe', value: 'all' },
                ...serviceTypeItems,
              ]"
              placeholder="Filter tipe"
            />
            <USelect
              v-model="servicesStore.filters.status"
              class="min-w-32"
              :items="statusItems"
              placeholder="Filter status"
            />
          </div>
        </div>

        <UAlert
          v-if="servicesStore.error"
          color="error"
          variant="subtle"
          icon="i-lucide-alert-circle"
          :description="servicesStore.error"
        />

        <UTable
          :data="servicesStore.items"
          :columns="serviceColumns"
          :loading="servicesStore.loading"
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
            Total: {{ servicesStore.pagination.total }}
          </div>

          <UPagination
            :page="servicesStore.pagination.page"
            :items-per-page="servicesStore.pagination.perPage"
            :total="servicesStore.pagination.total"
            @update:page="
              (p: number) => {
                servicesStore.pagination.page = p;
                servicesStore.fetch();
              }
            "
          />
        </div>
      </div>
    </template>
  </UDashboardPanel>

  <UModal
    v-model:open="categoryModalOpen"
    :title="
      categoryEditing ? 'Edit Kategori Layanan' : 'Tambah Kategori Layanan'
    "
  >
    <template #body>
      <div class="space-y-4">
        <UFormField label="Nama Kategori" required>
          <UInput
            v-model="categoryForm.name"
            placeholder="Contoh: Perawat Luka"
          />
        </UFormField>

        <UFormField label="Slug">
          <UInput v-model="categoryForm.slug" placeholder="perawat-luka" />
        </UFormField>

        <UFormField label="Deskripsi">
          <UTextarea
            v-model="categoryForm.description"
            placeholder="Deskripsi singkat kategori layanan"
          />
        </UFormField>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Icon">
            <UInput
              v-model="categoryForm.icon"
              placeholder="i-lucide-heart-pulse"
            />
          </UFormField>

          <UFormField label="Urutan">
            <UInput
              v-model.number="categoryForm.sort_order"
              type="number"
              min="0"
            />
          </UFormField>
        </div>

        <UCheckbox v-model="categoryForm.is_active" label="Kategori aktif" />
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end gap-2">
        <UButton
          color="neutral"
          variant="ghost"
          label="Batal"
          @click="categoryModalOpen = false"
        />
        <UButton
          :loading="categoriesStore.saving"
          label="Simpan"
          icon="i-lucide-save"
          @click="submitCategory"
        />
      </div>
    </template>
  </UModal>

  <UModal
    v-model:open="serviceModalOpen"
    :title="serviceEditing ? 'Edit Service' : 'Tambah Service'"
  >
    <template #body>
      <div class="space-y-4">
        <UFormField label="Kategori" required>
          <USelect
            v-model="serviceForm.service_category_id!"
            :items="categorySelectItems"
            placeholder="Pilih kategori layanan"
          />
        </UFormField>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Nama Service" required>
            <UInput
              v-model="serviceForm.name"
              placeholder="Contoh: Pasang Infus"
            />
          </UFormField>

          <UFormField label="Slug">
            <UInput v-model="serviceForm.slug" placeholder="pasang-infus" />
          </UFormField>
        </div>

        <UFormField label="Deskripsi">
          <UTextarea
            v-model="serviceForm.description"
            placeholder="Deskripsi singkat service"
          />
        </UFormField>

        <UFormField label="Foto Service">
          <div class="flex items-center gap-4">
            <div
              class="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-default bg-elevated/50"
            >
              <img
                v-if="serviceImagePreview"
                :src="serviceImagePreview"
                alt="preview"
                class="h-full w-full object-cover"
              />
              <i v-else class="i-lucide-image text-2xl text-muted" />
            </div>

            <div class="space-y-2">
              <UInput
                type="file"
                accept="image/jpeg,image/png,image/webp"
                @change="handleServiceImageChange"
              />
              <div class="flex gap-2">
                <UButton
                  v-if="serviceImagePreview"
                  type="button"
                  size="xs"
                  color="error"
                  variant="soft"
                  icon="i-lucide-trash"
                  label="Hapus Foto"
                  @click="removeServiceImage"
                />
              </div>
              <p class="text-xs text-muted">
                Format: jpg/jpeg/png/webp, maks 2 MB.
              </p>
            </div>
          </div>
        </UFormField>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Tipe Service">
            <USelect
              v-model="serviceForm.service_type"
              :items="serviceTypeItems"
            />
          </UFormField>

          <UFormField label="Mode Service">
            <USelect
              v-model="serviceForm.service_mode"
              :items="serviceModeItems"
            />
          </UFormField>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Kode Service">
            <UInput
              v-model="serviceForm.service_code"
              placeholder="Otomatis bila kosong"
            />
          </UFormField>

          <UFormField label="Kategori (teks)">
            <UInput
              v-model="serviceForm.category"
              placeholder="Label kategori"
            />
          </UFormField>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Icon">
            <UInput v-model="serviceForm.icon" placeholder="i-lucide-syringe" />
          </UFormField>

          <UFormField label="Urutan">
            <UInput
              v-model.number="serviceForm.sort_order"
              type="number"
              min="0"
            />
          </UFormField>
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <UFormField label="Harga Dasar">
            <UInput
              v-model.number="serviceForm.base_price"
              type="number"
              min="0"
            />
          </UFormField>

          <UFormField label="Durasi Menit">
            <UInput
              v-model.number="serviceForm.duration_minutes"
              type="number"
              min="0"
            />
          </UFormField>
        </div>

        <div class="grid gap-2 md:grid-cols-2">
          <UCheckbox
            v-model="serviceForm.requires_address"
            label="Membutuhkan alamat"
          />
          <UCheckbox
            v-model="serviceForm.requires_schedule"
            label="Membutuhkan jadwal"
          />
          <UCheckbox
            v-model="serviceForm.requires_matchmaking"
            label="Membutuhkan matchmaking"
          />
          <UCheckbox v-model="serviceForm.is_homecare" label="Homecare" />
        </div>

        <UCheckbox v-model="serviceForm.is_active" label="Service aktif" />
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end gap-2">
        <UButton
          color="neutral"
          variant="ghost"
          label="Batal"
          @click="serviceModalOpen = false"
        />
        <UButton
          :loading="servicesStore.saving"
          label="Simpan"
          icon="i-lucide-save"
          @click="submitService"
        />
      </div>
    </template>
  </UModal>

  <UModal v-model:open="deleteModalOpen" title="Hapus Data">
    <template #body>
      <p class="text-sm text-muted">
        Yakin ingin menghapus
        <strong>{{ deleteTarget?.item.name }}</strong
        >? Data yang sudah dihapus tidak bisa dikembalikan.
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
          :loading="categoriesStore.saving || servicesStore.saving"
          label="Hapus"
          icon="i-lucide-trash"
          @click="confirmDelete"
        />
      </div>
    </template>
  </UModal>
</template>
