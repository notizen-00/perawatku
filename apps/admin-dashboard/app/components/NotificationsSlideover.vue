<script setup lang="ts">
import { formatTimeAgo } from '@vueuse/core'
import type { Notification } from '~/types'
import { normalizeLaravelPaginated } from '~/services/shared/pagination'

const { isNotificationsSlideoverOpen } = useDashboard()

const { data: res, refresh } = await useFetch<any>('/api/shared/notifications', {
  query: { per_page: 20 }
})

const notifications = computed(() => normalizeLaravelPaginated<Notification>(res.value?.data).items)

watch(isNotificationsSlideoverOpen, (open) => {
  if (open) refresh()
})

async function openNotification(notification: Notification) {
  if (!notification.read_at) {
    try {
      await $fetch(`/api/shared/notifications/${notification.id}/read`, { method: 'PATCH' })
      notification.read_at = new Date().toISOString()
    }
    catch {
      // Non-critical -- still navigate even if marking as read failed.
    }
  }

  isNotificationsSlideoverOpen.value = false
  if (notification.action_url) {
    await navigateTo(notification.action_url)
  }
}
</script>

<template>
  <USlideover
    v-model:open="isNotificationsSlideoverOpen"
    title="Notifikasi"
  >
    <template #body>
      <p v-if="!notifications.length" class="text-sm text-muted text-center py-6">
        Belum ada notifikasi.
      </p>

      <button
        v-for="notification in notifications"
        :key="notification.id"
        type="button"
        class="w-full text-left px-3 py-2.5 rounded-md hover:bg-elevated/50 flex items-start gap-3 relative -mx-3 first:-mt-3 last:-mb-3"
        @click="openNotification(notification)"
      >
        <UChip color="error" :show="!notification.read_at" inset class="mt-1.5">
          <UIcon name="i-lucide-bell" class="size-5 shrink-0 text-muted" />
        </UChip>

        <div class="text-sm flex-1 min-w-0">
          <p class="flex items-center justify-between gap-2">
            <span class="text-highlighted font-medium truncate">{{ notification.title }}</span>
            <time
              :datetime="notification.created_at"
              class="text-muted text-xs shrink-0"
              v-text="formatTimeAgo(new Date(notification.created_at))"
            />
          </p>

          <p v-if="notification.body" class="text-dimmed">
            {{ notification.body }}
          </p>
        </div>
      </button>
    </template>
  </USlideover>
</template>
