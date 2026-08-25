<script setup lang="ts">
import { sub } from 'date-fns'
import type { DropdownMenuItem } from '@nuxt/ui'
import type { Range } from '~/types'

const { isNotificationsSlideoverOpen } = useDashboard()

const { data: unreadRes, refresh: refreshUnreadCount } = await useFetch<any>(
  '/api/shared/notifications/unread-count'
)
const unreadCount = computed(() => unreadRes.value?.data?.unread_count ?? 0)

watch(isNotificationsSlideoverOpen, (open) => {
  if (!open) refreshUnreadCount()
})

const items = [[{
  label: 'Mitra menunggu verifikasi',
  icon: 'i-lucide-user-check',
  to: '/partners'
}, {
  label: 'Pesan masuk',
  icon: 'i-lucide-send',
  to: '/inbox'
}]] satisfies DropdownMenuItem[][]

const range = shallowRef<Range>({
  start: sub(new Date(), { days: 14 }),
  end: new Date()
})
</script>

<template>
  <UDashboardPanel id="home">
    <template #header>
      <UDashboardNavbar title="Home" :ui="{ right: 'gap-3' }">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UTooltip text="Notifications" :shortcuts="['N']">
            <UButton
              color="neutral"
              variant="ghost"
              square
              @click="isNotificationsSlideoverOpen = true"
            >
              <UChip color="error" :show="unreadCount > 0" inset>
                <UIcon name="i-lucide-bell" class="size-5 shrink-0" />
              </UChip>
            </UButton>
          </UTooltip>

          <UDropdownMenu :items="items">
            <UButton icon="i-lucide-plus" size="md" class="rounded-full" />
          </UDropdownMenu>
        </template>
      </UDashboardNavbar>

      <UDashboardToolbar>
        <template #left>
          <!-- NOTE: The `-ms-1` class is used to align with the `DashboardSidebarCollapse` button here. -->
          <HomeDateRangePicker v-model="range" class="-ms-1" />
        </template>
      </UDashboardToolbar>
    </template>

    <template #body>
      <HomeStats :range="range" />
      <HomeChart />
      <HomePendingPartners />
    </template>
  </UDashboardPanel>
</template>
