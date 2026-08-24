<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from "@nuxt/ui";
import type {
  ConsultationLite,
  ConsultationStatus,
} from "~/services/admin/consultations";

const store = useConsultationsStore();
const toast = useToast();

const UBadge = resolveComponent("UBadge");
const UButton = resolveComponent("UButton");
const UDropdownMenu = resolveComponent("UDropdownMenu");

const search = ref(store.filters.search);

watchDebounced(
  search,
  (value) => {
    store.filters.search = value;
    store.pagination.page = 1;
    store.fetch();
  },
  { debounce: 400, maxWait: 1200 },
);

watch(
  () => store.filters.status,
  () => {
    store.pagination.page = 1;
    store.fetch();
  },
);

await callOnce(async () => {
  await store.fetch();
});

function statusColor(status?: ConsultationStatus) {
  if (status === "completed") return "success" as const;
  if (status === "cancelled") return "error" as const;
  if (status === "ongoing") return "primary" as const;
  if (status === "confirmed") return "info" as const;
  return "neutral" as const;
}

function getRowItems(item: ConsultationLite): DropdownMenuItem[] {
  return [
    { label: "Actions", type: "label" },
    {
      label: "Lihat detail",
      icon: "i-lucide-eye",
      onSelect: () => navigateTo(`/consultations/${item.id}`),
    },
    {
      label: "Copy Consultation ID",
      icon: "i-lucide-copy",
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(item.id));
        toast.add({
          title: "Copied",
          description: `Consultation ID ${item.id} disalin.`,
        });
      },
    },
    ...(item.consultation_code
      ? [
          {
            label: "Copy Consultation Code",
            icon: "i-lucide-clipboard",
            onSelect: async () => {
              await globalThis.navigator?.clipboard?.writeText(
                String(item.consultation_code),
              );
              toast.add({
                title: "Copied",
                description: `Consultation code ${item.consultation_code} disalin.`,
              });
            },
          } satisfies DropdownMenuItem,
        ]
      : []),
  ];
}

const columns: TableColumn<ConsultationLite>[] = [
  {
    id: "code",
    header: "Konsultasi",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h(
          "p",
          { class: "font-medium text-highlighted" },
          row.original.consultation_code || `#${row.original.id}`,
        ),
        h(
          "p",
          { class: "text-xs text-dimmed" },
          formatDateTime(row.original.created_at),
        ),
      ]),
  },
  {
    id: "patient",
    header: "Patient",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h(
          "p",
          { class: "font-medium text-highlighted" },
          row.original.patient?.name || "-",
        ),
        h(
          "p",
          { class: "text-xs text-dimmed" },
          row.original.patient?.email || "",
        ),
      ]),
  },
  {
    id: "partner",
    header: "Partner",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h(
          "p",
          { class: "font-medium text-highlighted" },
          row.original.partner?.name || "-",
        ),
        h(
          "p",
          { class: "text-xs text-dimmed" },
          row.original.partner?.partner_profile?.profession || "",
        ),
      ]),
  },
  {
    accessorKey: "service_type",
    header: "Service",
    cell: ({ row }) => row.original.service_type || "-",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) =>
      h(
        UBadge,
        { variant: "subtle", color: statusColor(row.original.status) },
        () => row.original.status || "-",
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
          { items: getRowItems(row.original), content: { align: "end" } },
          () =>
            h(UButton, {
              icon: "i-lucide-ellipsis-vertical",
              color: "neutral",
              variant: "ghost",
              size: "xs",
              class: "ml-auto",
            }),
        ),
      ),
  },
];
</script>

<template>
  <UDashboardPanel id="consultations">
    <template #header>
      <UDashboardNavbar title="Consultations">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-2">
        <UInput
          v-model="search"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Cari code/patient/partner/diagnosis..."
        />

        <div class="flex flex-wrap items-center gap-2">
          <USelect
            v-model="store.filters.status"
            class="min-w-40"
            placeholder="Status"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'pending', value: 'pending' },
              { label: 'confirmed', value: 'confirmed' },
              { label: 'ongoing', value: 'ongoing' },
              { label: 'completed', value: 'completed' },
              { label: 'cancelled', value: 'cancelled' },
            ]"
            :ui="{
              trailingIcon:
                'group-data-[state=open]:rotate-180 transition-transform duration-200',
            }"
          />

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
          separator: 'h-0',
        }"
      />

      <div class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-4">
        <div class="text-sm text-muted">Total: {{ store.pagination.total }}</div>

        <UPagination
          :page="store.pagination.page"
          :items-per-page="store.pagination.perPage"
          :total="store.pagination.total"
          @update:page="(p: number) => { store.pagination.page = p; store.fetch() }"
        />
      </div>
    </template>
  </UDashboardPanel>
</template>
