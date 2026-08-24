<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import { upperFirst } from "scule";
import { normalizeLaravelPaginated } from "~/services/shared/pagination";

type PatientRow = {
  id: number;
  name: string;
  email: string;
  phone?: string | null;
  patient_profile?: { gender?: string | null; birth_date?: string | null } | null;
};

const UAvatar = resolveComponent("UAvatar");
const UButton = resolveComponent("UButton");
const UDropdownMenu = resolveComponent("UDropdownMenu");

const toast = useToast();
const table = useTemplateRef("table");

const columnVisibility = ref();

const pagination = reactive({
  page: 1,
  perPage: 10,
  total: 0,
  lastPage: 1,
});

const searchEmail = ref("");

const query = computed(() => ({
  page: pagination.page,
  per_page: pagination.perPage,
  search: searchEmail.value?.trim() || undefined,
}));

const {
  data: res,
  status,
  refresh,
} = await useFetch<any>("/api/admin/patients", {
  lazy: true,
  query,
});

const rows = computed<PatientRow[]>(() => {
  const normalized = normalizeLaravelPaginated<PatientRow>(res.value?.data);
  if (normalized.meta) {
    pagination.page = normalized.meta.current_page;
    pagination.perPage = normalized.meta.per_page;
    pagination.total = normalized.meta.total;
    pagination.lastPage = normalized.meta.last_page;
  }
  return normalized.items;
});

async function goToPage(page: number) {
  pagination.page = page;
  await refresh();
}

function getRowItems(row: { original: PatientRow }) {
  return [
    {
      type: "label",
      label: "Aksi",
    },
    {
      label: "Salin ID Pasien",
      icon: "i-lucide-copy",
      onSelect() {
        navigator.clipboard.writeText(row.original.id.toString());
        toast.add({
          title: "Disalin",
          description: "ID pasien disalin ke clipboard",
        });
      },
    },
    {
      type: "separator",
    },
    {
      label: "Lihat Detail Pasien",
      icon: "i-lucide-list",
      onSelect() {
        navigateTo(`/patients/${row.original.id}`);
      },
    },
  ];
}

const columns: TableColumn<PatientRow>[] = [
  {
    accessorKey: "id",
    header: "ID",
  },
  {
    accessorKey: "name",
    header: "Nama",
    cell: ({ row }) => {
      return h("div", { class: "flex items-center gap-3" }, [
        h(UAvatar, { alt: row.original.name, size: "lg" }),
        h("p", { class: "font-medium text-highlighted" }, row.original.name),
      ]);
    },
  },
  {
    accessorKey: "email",
    header: ({ column }) => {
      const isSorted = column.getIsSorted();

      return h(UButton, {
        color: "neutral",
        variant: "ghost",
        label: "Email",
        icon: isSorted
          ? isSorted === "asc"
            ? "i-lucide-arrow-up-narrow-wide"
            : "i-lucide-arrow-down-wide-narrow"
          : "i-lucide-arrow-up-down",
        class: "-mx-2.5",
        onClick: () => column.toggleSorting(column.getIsSorted() === "asc"),
      });
    },
  },
  {
    accessorKey: "phone",
    header: "No. HP",
    cell: ({ row }) => row.original.phone || "-",
  },
  {
    id: "gender",
    header: "Jenis Kelamin",
    cell: ({ row }) => {
      const gender = row.original.patient_profile?.gender;
      if (gender === "male") return "Laki-laki";
      if (gender === "female") return "Perempuan";
      return "-";
    },
  },
  {
    id: "actions",
    cell: ({ row }) => {
      return h(
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
      );
    },
  },
];

watchDebounced(
  searchEmail,
  async () => {
    pagination.page = 1;
    await refresh();
  },
  { debounce: 400, maxWait: 1200 },
);
</script>

<template>
  <UDashboardPanel id="patients">
    <template #header>
      <UDashboardNavbar title="Pasien">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="flex flex-wrap items-center justify-between gap-1.5">
        <UInput
          v-model="searchEmail"
          class="max-w-sm"
          icon="i-lucide-search"
          placeholder="Cari email/nama..."
        />

        <div class="flex flex-wrap items-center gap-1.5">
          <UDropdownMenu
            :items="
              table?.tableApi
                ?.getAllColumns()
                .filter((column: any) => column.getCanHide())
                .map((column: any) => ({
                  label: upperFirst(column.id),
                  type: 'checkbox' as const,
                  checked: column.getIsVisible(),
                  onUpdateChecked(checked: boolean) {
                    table?.tableApi
                      ?.getColumn(column.id)
                      ?.toggleVisibility(!!checked);
                  },
                  onSelect(e?: Event) {
                    e?.preventDefault();
                  },
                }))
            "
            :content="{ align: 'end' }"
          >
            <UButton
              label="Tampilan"
              color="neutral"
              variant="outline"
              trailing-icon="i-lucide-settings-2"
            />
          </UDropdownMenu>
        </div>
      </div>

      <UTable
        ref="table"
        v-model:column-visibility="columnVisibility"
        class="shrink-0"
        :data="rows"
        :columns="columns"
        :loading="status === 'pending'"
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
        <div class="text-sm text-muted">Total: {{ pagination.total }} pasien</div>

        <div class="flex items-center gap-1.5">
          <UPagination
            :page="pagination.page"
            :items-per-page="pagination.perPage"
            :total="pagination.total"
            @update:page="goToPage"
          />
        </div>
      </div>
    </template>
  </UDashboardPanel>
</template>
