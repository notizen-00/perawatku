<script setup lang="ts">
import type { DropdownMenuItem, TableColumn } from "@nuxt/ui";
import type { Partner } from "~/services/admin/partners";

const store = usePartnersStore();
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
  () =>
    [
      store.filters.profession,
      store.filters.availability,
      store.filters.verificationStatus,
    ] as const,
  () => {
    store.pagination.page = 1;
    store.fetch();
  },
);

await callOnce(async () => {
  await store.fetch();
});

function professionLabel(p?: string) {
  if (p === "dokter") return "Dokter";
  if (p === "perawat") return "Perawat";
  if (p === "bidan") return "Bidan";
  return "-";
}

function partnerDocumentThumbUrl(partnerId: number | string, type: string = "str") {
  return `/api/shared/secure-image/partners/${partnerId}/documents/${type}`;
}

function getRowItems(partner: Partner): DropdownMenuItem[] {
  return [
    { label: "Actions", type: "label" },
    {
      label: "Lihat detail",
      icon: "i-lucide-eye",
      onSelect: () => navigateTo(`/partners/${partner.id}`)
    },
    {
      label: "Copy Partner ID",
      icon: "i-lucide-copy",
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(partner.id))
        toast.add({ title: "Copied", description: `Partner ID ${partner.id} disalin.` })
      }
    },
    {
      label: "Copy Email",
      icon: "i-lucide-mail",
      onSelect: async () => {
        await globalThis.navigator?.clipboard?.writeText(String(partner.email || ""))
        toast.add({ title: "Copied", description: "Email disalin." })
      }
    }
  ];
}

const columns: TableColumn<Partner>[] = [
  {
    accessorKey: "name",
    header: "Nama",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h("p", { class: "font-medium text-highlighted" }, row.original.name),
        h("p", { class: "text-xs text-dimmed" }, row.original.email),
      ]),
  },
  {
    id: "document_thumb",
    header: "Foto",
    cell: ({ row }) =>
      h("img", {
        src: partnerDocumentThumbUrl(row.original.id, "str"),
        alt: `${row.original.name} - STR`,
        class:
          "h-10 w-10 rounded-md border border-default object-cover bg-elevated/40",
        loading: "lazy",
        onError: (e: Event) => {
          (e.target as HTMLImageElement).style.display = "none";
        },
      }),
  },
  {
    id: "profession",
    header: "Profesi",
    cell: ({ row }) => {
      const p = row.original.partner_profile?.profession;
      return h(UBadge, { variant: "subtle", color: "neutral" }, () =>
        professionLabel(p),
      );
    },
  },
  {
    id: "specialization",
    header: "Spesialisasi",
    cell: ({ row }) => row.original.partner_profile?.specialization || "-",
  },
  {
    id: "work_location",
    header: "Lokasi",
    cell: ({ row }) => row.original.partner_profile?.work_location || "-",
  },
  {
    id: "availability",
    header: "Status",
    cell: ({ row }) => {
      const available = row.original.partner_profile?.is_available;
      const color = available ? "success" : "error";
      const label = available ? "Available" : "Unavailable";
      return h(UBadge, { variant: "subtle", color }, () => label);
    },
  },
  {
    id: "verification_status",
    header: "Verifikasi",
    cell: ({ row }) => {
      type VerificationStatus = "pending" | "verified" | "rejected";
      const status = (row.original.partner_profile?.verification_status ||
        (row.original as any)?.verification_status) as
        | VerificationStatus
        | undefined;

      const colorMap: Record<
        VerificationStatus,
        "success" | "warning" | "error"
      > = {
        verified: "success",
        pending: "warning",
        rejected: "error",
      };
      const labelMap: Record<VerificationStatus, string> = {
        verified: "Verified",
        pending: "Pending",
        rejected: "Rejected",
      };

      const color = status ? colorMap[status] : ("neutral" as const);
      const label = status ? labelMap[status] : "-";
      return h(UBadge, { variant: "subtle", color }, () => label);
    },
  },
  // {
  //   id: "counts",
  //   header: "Ringkasan",
  //   cell: ({ row }) => {
  //     const consultations = row.original.partner_consultations_count ?? 0;
  //     const services = row.original.partner_services_count ?? 0;
  //     const bookings = row.original.partner_service_bookings_count ?? 0;
  //     return h(
  //       "div",
  //       { class: "text-sm text-dimmed" },
  //       `C:${consultations} • S:${services} • B:${bookings}`,
  //     );
  //   },
  // },
  {
    id: "actions",
    cell: ({ row }) => {
      return h("div", { class: "flex justify-end" }, [
        h(
          UDropdownMenu,
          { items: getRowItems(row.original), content: { align: "end" } },
          () =>
            h(UButton, {
              icon: "i-lucide-ellipsis-vertical",
              color: "neutral",
              variant: "ghost",
              size: "xs",
            }),
        ),
      ]);
    },
  },
];
</script>

<template>
  <UDashboardPanel id="partners">
    <template #header>
      <UDashboardNavbar title="Partners">
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
          placeholder="Cari nama/email/phone/spesialisasi..."
        />

        <div class="flex flex-wrap items-center gap-2">
          <USelect
            v-model="store.filters.profession"
            class="min-w-32"
            placeholder="Profesi"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'Dokter', value: 'dokter' },
              { label: 'Perawat', value: 'perawat' },
              { label: 'Bidan', value: 'bidan' },
            ]"
            :ui="{
              trailingIcon:
                'group-data-[state=open]:rotate-180 transition-transform duration-200',
            }"
          />

          <USelect
            v-model="store.filters.availability"
            class="min-w-36"
            placeholder="Status"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'Available', value: 'available' },
              { label: 'Unavailable', value: 'unavailable' },
            ]"
            :ui="{
              trailingIcon:
                'group-data-[state=open]:rotate-180 transition-transform duration-200',
            }"
          />

          <USelect
            v-model="store.filters.verificationStatus"
            class="min-w-36"
            placeholder="Verifikasi"
            :items="[
              { label: 'Semua', value: 'all' },
              { label: 'Pending', value: 'pending' },
              { label: 'Verified', value: 'verified' },
              { label: 'Rejected', value: 'rejected' },
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

      <div
        class="flex items-center justify-between gap-3 border-t border-default pt-4 mt-4"
      >
        <div class="text-sm text-muted">
          Total: {{ store.pagination.total }}
        </div>

        <UPagination
          :page="store.pagination.page"
          :items-per-page="store.pagination.perPage"
          :total="store.pagination.total"
          @update:page="
            (p: number) => {
              store.pagination.page = p;
              store.fetch();
            }
          "
        />
      </div>
    </template>
  </UDashboardPanel>
</template>
