import { defineStore } from 'pinia'

type Credentials = { email: string, password: string }

export const useAuthStore = defineStore('auth', () => {
  const auth = useAuth()
  const authState = useAuthState()

  const token = computed(() => authState.token.value)
  const user = computed<any>(() => auth.data.value || null)

  async function login(credentials: Credentials) {
    return auth.signIn(credentials, { callbackUrl: '/', redirect: true })
  }

  async function logout() {
    return auth.signOut({ callbackUrl: '/login', redirect: true })
  }

  return {
    status: auth.status,
    token,
    user,
    login,
    logout,
    getSession: auth.getSession,
    refresh: auth.refresh
  }
})

