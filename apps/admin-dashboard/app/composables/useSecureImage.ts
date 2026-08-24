type UseSecureImageOptions = {
  enabled?: boolean
  mimeType?: string
}

function isHexString(value: string) {
  const s = value.trim()
  return s.length >= 2 && s.length % 2 === 0 && /^[0-9a-fA-F]+$/.test(s)
}

function hexToUint8Array(hex: string) {
  const clean = hex.trim()
  const out = new Uint8Array(clean.length / 2)
  for (let i = 0; i < clean.length; i += 2) {
    out[i / 2] = Number.parseInt(clean.slice(i, i + 2), 16)
  }
  return out
}

export function useSecureImage(url: MaybeRefOrGetter<string | undefined>, options: UseSecureImageOptions = {}) {
  const src = ref<string | undefined>(undefined)
  const pending = ref(false)
  const error = ref<unknown>(null)

  let lastObjectUrl: string | null = null

  function clearObjectUrl() {
    if (lastObjectUrl) URL.revokeObjectURL(lastObjectUrl)
    lastObjectUrl = null
  }

  async function load() {
    const resolved = toValue(url)
    if (!resolved || options.enabled === false) {
      clearObjectUrl()
      src.value = undefined
      return
    }

    pending.value = true
    error.value = null
    try {
      const res = await $fetch.raw<any>(resolved, {
        // Some backends may incorrectly return hex/text; handle below.
        responseType: 'arrayBuffer'
      })

      const contentType = res.headers.get('content-type') || options.mimeType || 'application/octet-stream'

      let bytes: Uint8Array
      const body = res._data

      if (typeof body === 'string' && isHexString(body)) {
        bytes = hexToUint8Array(body)
      }
      else if (body instanceof ArrayBuffer) {
        bytes = new Uint8Array(body)
      }
      else if (body?.buffer instanceof ArrayBuffer) {
        bytes = new Uint8Array(body.buffer)
      }
      else {
        bytes = new Uint8Array(0)
      }

      // Ensure we pass an ArrayBuffer-backed view (not SharedArrayBuffer) to Blob.
      // Copying creates a new ArrayBuffer.
      const safeBytes = new Uint8Array(bytes)
      const blobSafe = new Blob([safeBytes], { type: contentType })
      const objectUrl = URL.createObjectURL(blobSafe)
      clearObjectUrl()
      lastObjectUrl = objectUrl
      src.value = objectUrl
    }
    catch (e) {
      clearObjectUrl()
      src.value = undefined
      error.value = e
    }
    finally {
      pending.value = false
    }
  }

  watch(() => toValue(url), () => {
    load()
  }, { immediate: true })

  onBeforeUnmount(() => {
    clearObjectUrl()
  })

  return { src, pending, error, reload: load }
}
