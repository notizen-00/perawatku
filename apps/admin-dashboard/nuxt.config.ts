// https://nuxt.com/docs/api/configuration/nuxt-config
declare const process: any

export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui',
    '@vueuse/nuxt',
    '@pinia/nuxt',
    '@sidebase/nuxt-auth',
    '@nuxt/image'
  ],
  ssr:false,

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      siteUrl: process.env.NUXT_PUBLIC_SITE_URL,
      apiBase: process.env.NUXT_PUBLIC_API_BASE,
      storageBase: process.env.NUXT_PUBLIC_STORAGE_BASE
    }
  },

  auth: {
    isEnabled: true,
    baseURL: '/api/auth',
    globalAppMiddleware: true,
    provider: {
      type: 'local',
      pages: {
        login: '/login'
      },
      session: {
        dataResponsePointer: '/data'
      },
      refresh: {
        isEnabled: false
      },
      endpoints: {
        signIn: { path: '/login', method: 'post' },
        signOut: { path: '/logout', method: 'post' },
        getSession: { path: '/session', method: 'get' }
      },
      token: {
        signInResponseTokenPointer: '/token',
        type: 'Bearer',
        headerName: 'Authorization'
      }
    }
  },

  routeRules: {
    '/api/**': {
      cors: true
    }
  },

  compatibilityDate: '2024-07-11',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})