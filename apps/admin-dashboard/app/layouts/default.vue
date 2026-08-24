<script setup lang="ts">
import type { NavigationMenuItem } from "@nuxt/ui";

const route = useRoute();
const toast = useToast();

const open = ref(false);

function closeSidebar() {
  open.value = false;
}

const links = [
  [
    {
      label: "Home",
      icon: "i-lucide-house",
      to: "/",
      onSelect: closeSidebar,
    },
    {
      label: "Master Data",
      icon: "i-lucide-database",
      defaultOpen: true,
      type: "trigger",
      children: [
        {
          label: "Patients",
          icon: "i-lucide-users",
          to: "/patients",
          onSelect: closeSidebar,
        },
        {
          label: "Partners",
          icon: "i-lucide-stethoscope",
          to: "/partners",
          onSelect: closeSidebar,
        },
        {
          label: "Services",
          icon: "i-lucide-list-tree",
          to: "/services",
          onSelect: closeSidebar,
        },
        {
          label: "Service Applications",
          icon: "i-lucide-badge-check",
          to: "/service-applications",
          onSelect: closeSidebar,
        },
      ],
    },
    {
      label: "Transaksi",
      icon: "i-lucide-receipt-text",
      defaultOpen: true,
      type: "trigger",
      children: [
        {
          label: "Orders",
          icon: "i-lucide-shopping-bag",
          to: "/orders",
          onSelect: closeSidebar,
        },
        {
          label: "Consultations",
          icon: "i-lucide-message-square",
          to: "/consultations",
          onSelect: closeSidebar,
        },
        {
          label: "Service Bookings",
          icon: "i-lucide-calendar-check",
          to: "/service-bookings",
          onSelect: closeSidebar,
        },
      ],
    },
    {
      label: "Laporan",
      icon: "i-lucide-chart-no-axes-combined",
      type: "trigger",
      children: [
        {
          label: "Laporan Keuangan",
          icon: "i-lucide-chart-no-axes-combined",
          to: "/reports",
          onSelect: closeSidebar,
        },
        {
          label: "Inbox",
          icon: "i-lucide-inbox",
          to: "/inbox",
          badge: "4",
          onSelect: closeSidebar,
        },
      ],
    },
    {
      label: "Settings",
      to: "/settings",
      icon: "i-lucide-settings",
      defaultOpen: true,
      type: "trigger",
      children: [
        {
          label: "General",
          to: "/settings",
          exact: true,
          onSelect: closeSidebar,
        },
        {
          label: "Members",
          to: "/settings/members",
          onSelect: closeSidebar,
        },
        {
          label: "Promo Codes",
          to: "/promo-codes",
          icon: "i-lucide-ticket",
          onSelect: closeSidebar,
        },
        {
          label: "Service Markup",
          to: "/service-markup-setting",
          icon: "i-lucide-badge-percent",
          onSelect: closeSidebar,
        },
        {
          label: "Booking Fees",
          to: "/settings/service-booking-fees",
          onSelect: closeSidebar,
        },
        {
          label: "Notifications",
          to: "/settings/notifications",
          onSelect: closeSidebar,
        },
        {
          label: "Security",
          to: "/settings/security",
          onSelect: closeSidebar,
        },
      ],
    },
  ],
  [
    {
      label: "Feedback",
      icon: "i-lucide-message-circle",
      to: "https://github.com/nuxt-ui-templates/dashboard",
      target: "_blank",
    },
    {
      label: "Help & Support",
      icon: "i-lucide-info",
      to: "https://github.com/nuxt-ui-templates/dashboard",
      target: "_blank",
    },
  ],
] satisfies NavigationMenuItem[][];

function flattenItems(items: NavigationMenuItem[]): NavigationMenuItem[] {
  return items.flatMap((item) => [
    item,
    ...flattenItems(item.children || []),
  ]);
}

const groups = computed(() => [
  {
    id: "links",
    label: "Go to",
    items: links.flatMap((group) => flattenItems(group)),
  },
  {
    id: "code",
    label: "Code",
    items: [
      {
        id: "source",
        label: "View page source",
        icon: "i-simple-icons-github",
        to: `https://github.com/nuxt-ui-templates/dashboard/blob/main/app/pages${route.path === "/" ? "/index" : route.path}.vue`,
        target: "_blank",
      },
    ],
  },
]);

onMounted(async () => {
  const cookie = useCookie("cookie-consent");
  if (cookie.value === "accepted") {
    return;
  }

  toast.add({
    title:
      "We use first-party cookies to enhance your experience on our website.",
    duration: 0,
    close: false,
    actions: [
      {
        label: "Accept",
        color: "neutral",
        variant: "outline",
        onClick: () => {
          cookie.value = "accepted";
        },
      },
      {
        label: "Opt out",
        color: "neutral",
        variant: "ghost",
      },
    ],
  });
});
</script>

<template>
  <UDashboardGroup unit="rem">
    <UDashboardSidebar
      id="default"
      v-model:open="open"
      collapsible
      resizable
      class="bg-elevated/25"
      :ui="{ footer: 'lg:border-t lg:border-default' }"
    >
      <template #header="{ collapsed }">
        <TeamsMenu :collapsed="collapsed" />
      </template>

      <template #default="{ collapsed }">
        <UDashboardSearchButton
          :collapsed="collapsed"
          class="bg-transparent ring-default"
        />

        <UNavigationMenu
          :collapsed="collapsed"
          :items="links[0]"
          orientation="vertical"
          tooltip
          popover
        />

        <UNavigationMenu
          :collapsed="collapsed"
          :items="links[1]"
          orientation="vertical"
          tooltip
          class="mt-auto"
        />
      </template>

      <template #footer="{ collapsed }">
        <UserMenu :collapsed="collapsed" />
      </template>
    </UDashboardSidebar>

    <UDashboardSearch :groups="groups" />

    <slot />

    <NotificationsSlideover />
  </UDashboardGroup>
</template>
