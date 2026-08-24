<script setup lang="ts">
import type { TableColumn } from "@nuxt/ui";
import { listConsultations } from "~/services/admin/consultations";
import { getUserBalance, getUserBalanceHistory } from "~/services/admin/reports";
import { listServiceBookings } from "~/services/admin/service-bookings";
import { normalizeLaravelPaginated } from "~/services/shared/pagination";
import { getUser } from "~/services/shared/users";

const route = useRoute();
const toast = useToast();

const UBadge = resolveComponent("UBadge");

const id = computed(() => String(route.params.id || ""));

const { data, pending, error, refresh } = await useAsyncData(
  () => `partner:${id.value}`,
  async () => {
    const res = await getUser(id.value);
    return res.data;
  },
  { watch: [id] },
);

const { data: consultations, pending: consultationsPending, refresh: refreshConsultations } = await useAsyncData(
  () => `partner-consultations:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await listConsultations({ partner_user_id: Number(id.value), per_page: 5 })).data).items,
  { default: () => [], watch: [id] },
);

const { data: bookings, pending: bookingsPending, refresh: refreshBookings } = await useAsyncData(
  () => `partner-bookings:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await listServiceBookings({ assigned_partner_user_id: Number(id.value), per_page: 5 })).data).items,
  { default: () => [], watch: [id] },
);

const { data: balance, pending: balancePending, refresh: refreshBalance } = await useAsyncData(
  () => `partner-balance:${id.value}`,
  async () => (await getUserBalance(id.value)).data,
  { default: () => null, watch: [id] },
);

const { data: balanceHistory, pending: balanceHistoryPending, refresh: refreshBalanceHistory } = await useAsyncData(
  () => `partner-balance-history:${id.value}`,
  async () => normalizeLaravelPaginated<any>((await getUserBalanceHistory(id.value, { per_page: 5 })).data).items,
  { default: () => [], watch: [id] },
);

const strPhotoOk = ref(true)
const ktpPhotoOk = ref(true)

const strPhotoApiUrl = computed(() =>
  strPhotoOk.value ? `/api/shared/secure-image/partners/${id.value}/documents/str` : undefined
)

const ktpPhotoApiUrl = computed(() =>
  ktpPhotoOk.value ? `/api/shared/secure-image/partners/${id.value}/documents/ktp` : undefined
)

const { src: strPhotoUrl } = useSecureImage(strPhotoApiUrl)
const { src: ktpPhotoUrl } = useSecureImage(ktpPhotoApiUrl)

type VerificationStatus = "pending" | "verified" | "rejected";

const verificationBadge = computed(() => {
  const status = (data.value?.partner_profile?.verification_status ||
    (data.value as any)?.verification_status) as VerificationStatus | undefined;

  if (!status) return { color: "neutral" as const, label: "-" };

  const colorMap: Record<VerificationStatus, "warning" | "success" | "error"> =
    {
      pending: "warning",
      verified: "success",
      rejected: "error",
    };
  const labelMap: Record<VerificationStatus, string> = {
    pending: "Pending",
    verified: "Verified",
    rejected: "Rejected",
  };

  return { color: colorMap[status], label: labelMap[status] };
});

function professionLabel(p?: string) {
  if (p === "dokter") return "Dokter";
  if (p === "perawat") return "Perawat";
  if (p === "bidan") return "Bidan";
  return "-";
}

const balanceAmount = computed(() =>
  balance.value?.balance ?? balance.value?.amount ?? balance.value?.saldo ?? balance.value?.data?.balance ?? 0
);

const historyLoading = computed(() =>
  consultationsPending.value || bookingsPending.value || balanceHistoryPending.value
);

function statusColor(status?: string | null) {
  if (["completed", "delivered", "paid", "success", "verified"].includes(String(status))) return "success" as const;
  if (["cancelled", "failed", "rejected"].includes(String(status))) return "error" as const;
  if (["pending", "processed", "draft"].includes(String(status))) return "warning" as const;
  if (["confirmed", "ongoing", "assigned", "shipped"].includes(String(status))) return "info" as const;
  return "neutral" as const;
}

function bookingCode(item: any) {
  return item.booking_code || item.service_booking_code || `#${item.id}`;
}

async function refreshAll() {
  await Promise.all([
    refresh(),
    refreshConsultations(),
    refreshBookings(),
    refreshBalance(),
    refreshBalanceHistory(),
  ]);
}

async function copyId() {
  const value = String(data.value?.id || "");
  if (!value) return;
  await globalThis.navigator?.clipboard?.writeText(value);
  toast.add({ title: "Copied", description: "Partner ID disalin." });
}

const consultationColumns: TableColumn<any>[] = [
  {
    id: "consultation",
    header: "Konsultasi",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h("p", { class: "font-medium text-highlighted" }, row.original.consultation_code || `#${row.original.id}`),
        h("p", { class: "text-xs text-dimmed" }, formatDateTime(row.original.created_at)),
      ]),
  },
  { accessorKey: "service_type", header: "Service", cell: ({ row }) => row.original.service_type || "-" },
  { id: "patient", header: "Patient", cell: ({ row }) => row.original.patient?.name || "-" },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => h(UBadge, { variant: "subtle", color: statusColor(row.original.status) }, () => row.original.status || "-"),
  },
];

const bookingColumns: TableColumn<any>[] = [
  {
    id: "booking",
    header: "Booking",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h("p", { class: "font-medium text-highlighted" }, bookingCode(row.original)),
        h("p", { class: "text-xs text-dimmed" }, formatDateTime(row.original.scheduled_at || row.original.booking_date || row.original.created_at)),
      ]),
  },
  { id: "service", header: "Service", cell: ({ row }) => row.original.service?.name || "-" },
  { id: "patient", header: "Patient", cell: ({ row }) => row.original.patient?.name || "-" },
  { id: "amount", header: "Total", cell: ({ row }) => formatCurrencyIDR(row.original.total_amount ?? row.original.final_price) },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => h(UBadge, { variant: "subtle", color: statusColor(row.original.status) }, () => row.original.status || "-"),
  },
];

const balanceHistoryColumns: TableColumn<any>[] = [
  {
    id: "transaction",
    header: "Transaksi Saldo",
    cell: ({ row }) =>
      h("div", { class: "space-y-0.5" }, [
        h("p", { class: "font-medium text-highlighted" }, row.original.transaction_code || row.original.reference || `#${row.original.id}`),
        h("p", { class: "text-xs text-dimmed" }, row.original.description || row.original.notes || ""),
      ]),
  },
  { id: "type", header: "Type", cell: ({ row }) => row.original.type || row.original.transaction_type || "-" },
  { id: "amount", header: "Amount", cell: ({ row }) => formatCurrencyIDR(row.original.amount ?? row.original.value) },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => h(UBadge, { variant: "subtle", color: statusColor(row.original.status) }, () => row.original.status || "-"),
  },
  { id: "date", header: "Tanggal", cell: ({ row }) => formatDateTime(row.original.created_at || row.original.transaction_date) },
];
</script>

<template>
  <UDashboardPanel id="partner-detail">
    <template #header>
      <UDashboardNavbar
        :title="data?.name ? `Partner: ${data.name}` : 'Partner Detail'"
      >
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/partners')"
          />
        </template>

        <template #right>
          <UButton
            icon="i-lucide-copy"
            color="neutral"
            variant="outline"
            :disabled="!data?.id"
            @click="copyId"
          >
            Copy ID
          </UButton>
          <UButton
            icon="i-lucide-refresh-cw"
            color="neutral"
            variant="outline"
            :loading="pending || historyLoading"
            @click="refreshAll"
          >
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
              <div class="flex items-center gap-3 min-w-0">
                <UAvatar :src="strPhotoUrl" :alt="data?.name" size="xl" />

                <div class="space-y-0.5 min-w-0">
                  <div class="text-sm text-dimmed">Informasi Dasar</div>
                  <div class="text-lg font-semibold">
                    {{ data?.name || "-" }}
                  </div>
                </div>
              </div>
              <UBadge variant="subtle" color="neutral">
                {{ data?.role || "mitra" }}
              </UBadge>
            </div>
          </template>

          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <div class="text-xs text-dimmed">Email</div>
              <div class="font-medium">
                {{ data?.email || "-" }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">Phone</div>
              <div class="font-medium">
                {{ data?.phone || "-" }}
              </div>
            </div>
          </div>
        </UCard>

        <UCard>
          <template #header>
            <div class="text-sm text-dimmed">Status & Saldo</div>
          </template>

          <div class="space-y-4">
            <div>
              <div class="text-xs text-dimmed">Balance</div>
              <div class="text-2xl font-semibold text-highlighted">
                {{ formatCurrencyIDR(balanceAmount) }}
              </div>
              <div class="text-xs text-muted">
                {{ balancePending ? "Memuat saldo..." : "Saldo mitra" }}
              </div>
            </div>

            <div class="flex items-center justify-between gap-3">
              <div class="text-sm">Profesi</div>
              <UBadge variant="subtle" color="neutral">
                {{ professionLabel(data?.partner_profile?.profession) }}
              </UBadge>
            </div>

            <div class="flex items-center justify-between gap-3">
              <div class="text-sm">Availability</div>
              <UBadge
                :color="
                  data?.partner_profile?.is_available ? 'success' : 'error'
                "
                variant="subtle"
              >
                {{
                  data?.partner_profile?.is_available
                    ? "Available"
                    : "Unavailable"
                }}
              </UBadge>
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="text-sm text-dimmed">Profil Mitra</div>
          </template>

          <div class="grid gap-4 sm:grid-cols-3">
            <div>
              <div class="text-xs text-dimmed">Spesialisasi</div>
              <div class="font-medium">
                {{ data?.partner_profile?.specialization || "-" }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">Lokasi Kerja</div>
              <div class="font-medium">
                {{ data?.partner_profile?.work_location || "-" }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">Nomor Izin</div>
              <div class="font-medium">
                {{ data?.partner_profile?.license_number || "-" }}
              </div>
            </div>
            <div>
              <div class="text-xs text-dimmed">Verifikasi</div>
              <UBadge :color="verificationBadge.color" variant="subtle">
                {{ verificationBadge.label }}
              </UBadge>
            </div>

            <div>
              <div class="text-xs text-dimmed">Foto STR</div>
              <div class="mt-2">
                <img
                  v-if="strPhotoUrl"
                  :src="strPhotoUrl"
                  :alt="`${data?.name || 'Partner'} - STR`"
                  class="w-full max-w-md rounded-md border border-default object-contain bg-elevated/40"
                  loading="lazy"
                  @error="() => { strPhotoOk = false }"
                />
                <div v-else class="text-sm text-muted">-</div>
              </div>
            </div>

            <div>
              <div class="text-xs text-dimmed">Foto KTP</div>
              <div class="mt-2">
                <img
                  v-if="ktpPhotoUrl"
                  :src="ktpPhotoUrl"
                  :alt="`${data?.name || 'Partner'} - KTP`"
                  class="w-full max-w-md rounded-md border border-default object-contain bg-elevated/40"
                  loading="lazy"
                  @error="() => { ktpPhotoOk = false }"
                />
                <div v-else class="text-sm text-muted">-</div>
              </div>
            </div>
          </div>
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="font-medium">Riwayat Service Booking</div>
          </template>
          <UTable :data="bookings || []" :columns="bookingColumns" :loading="bookingsPending" />
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="font-medium">Riwayat Konsultasi</div>
          </template>
          <UTable :data="consultations || []" :columns="consultationColumns" :loading="consultationsPending" />
        </UCard>

        <UCard class="lg:col-span-3">
          <template #header>
            <div class="font-medium">Riwayat Saldo</div>
          </template>
          <UTable :data="balanceHistory || []" :columns="balanceHistoryColumns" :loading="balanceHistoryPending" />
        </UCard>
      </div>

      <USkeleton v-if="pending" class="h-32 w-full mt-4" />
    </template>
  </UDashboardPanel>
</template>
