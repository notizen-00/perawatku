<script setup lang="ts">
definePageMeta({
  auth: false,
  layout: "blank",
});

const store = useAuthStore();
const toast = useToast();

const form = reactive({
  email: "",
  password: "",
  remember: true,
});

const loading = computed(() => store.status === "loading");
const showPassword = ref(false);

async function onSubmit() {
  try {
    await store.login({ email: form.email, password: form.password });
  } catch (err: any) {
    toast.add({
      color: "error",
      title: "Login gagal",
      description:
        err?.data?.message ||
        err?.message ||
        "Periksa email/password & API base URL.",
    });
  }
}
</script>

<template>
  <div class="relative min-h-screen overflow-hidden">
    <div
      class="absolute inset-0 bg-gradient-to-br from-primary/10 via-transparent to-primary/5"
    />
    <div
      class="absolute -top-40 -left-40 size-[32rem] rounded-full bg-primary/10 blur-3xl"
    />
    <div
      class="absolute -bottom-40 -right-40 size-[32rem] rounded-full bg-primary/10 blur-3xl"
    />

    <div
      class="relative mx-auto grid min-h-screen max-w-6xl items-center gap-10 px-6 py-10 lg:grid-cols-2"
    >
      <div class="hidden lg:block">
        <div class="space-y-6">
          <div class="inline-flex items-center gap-3">
            <div
              class="flex size-11 items-center justify-center rounded-2xl bg-primary text-inverted shadow-sm ring-1 ring-primary/20"
            >
              <UIcon name="i-lucide-shield" class="size-6" />
            </div>
            <div class="leading-tight">
              <div class="text-sm text-dimmed">Perawatku Admin</div>
              <!-- <div class="text-lg font-semibold">
                Dashboard premium untuk tim kamu
              </div> -->
            </div>
          </div>

          <h1 class="text-3xl font-semibold tracking-tight">
            Aplikasi Dashboard admin perawatku.
          </h1>

          <div class="grid max-w-lg gap-3 sm:grid-cols-2">
            <!-- <UCard>
              <div class="flex items-start gap-3">
                <div
                  class="mt-0.5 flex size-9 items-center justify-center rounded-xl bg-primary/10 ring-1 ring-primary/15"
                >
                  <UIcon
                    name="i-lucide-key-round"
                    class="size-5 text-primary"
                  />
                </div>
                <div class="space-y-0.5">
                  <div class="font-medium">Token-based auth</div>
                  <div class="text-sm text-dimmed">
                    Login + session dari Laravel.
                  </div>
                </div>
              </div>
            </UCard> -->
            <!-- 
            <UCard>
              <div class="flex items-start gap-3">
                <div
                  class="mt-0.5 flex size-9 items-center justify-center rounded-xl bg-primary/10 ring-1 ring-primary/15"
                >
                  <UIcon name="i-lucide-route" class="size-5 text-primary" />
                </div>
                <div class="space-y-0.5">
                  <div class="font-medium">API proxy</div>
                  <div class="text-sm text-dimmed">
                    Frontend tetap ke `/api/*`.
                  </div>
                </div>
              </div>
            </UCard> -->
          </div>
        </div>
      </div>

      <div class="w-full">
        <div class="mx-auto w-full max-w-md">
          <UCard class="backdrop-blur">
            <template #header>
              <div class="space-y-1.5">
                <div class="flex items-center gap-3 lg:hidden">
                  <div
                    class="flex size-10 items-center justify-center rounded-2xl bg-primary text-inverted shadow-sm ring-1 ring-primary/20"
                  >
                    <UIcon name="i-lucide-shield" class="size-5" />
                  </div>
                  <div class="font-semibold">Medic Admin</div>
                </div>

                <h2 class="text-xl font-semibold">Masuk ke akun</h2>
                <p class="text-sm text-dimmed">
                  Gunakan kredensial yang terdaftar di sistem.
                </p>
              </div>
            </template>

            <form class="space-y-4" @submit.prevent="onSubmit">
              <UFormField label="Email">
                <UInput
                  v-model="form.email"
                  type="email"
                  autocomplete="email"
                  placeholder="nama@perusahaan.com"
                  required
                  icon="i-lucide-mail"
                />
              </UFormField>

              <UFormField label="Password">
                <UInput
                  v-model="form.password"
                  :type="showPassword ? 'text' : 'password'"
                  autocomplete="current-password"
                  placeholder="••••••••"
                  required
                  icon="i-lucide-lock"
                  :trailing-icon="
                    showPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'
                  "
                  @click:trailing="showPassword = !showPassword"
                />
              </UFormField>

              <div class="flex items-center justify-between gap-3">
                <UCheckbox v-model="form.remember" label="Ingat saya" />
                <UButton variant="link" color="neutral" class="px-0">
                  Lupa password?
                </UButton>
              </div>

              <UButton type="submit" block size="lg" :loading="loading">
                Masuk
              </UButton>
            </form>
          </UCard>

          <!-- <p class="mt-6 text-center text-xs text-dimmed">
            Kesulitan login?
          </p> -->
        </div>
      </div>
    </div>
  </div>
</template>
