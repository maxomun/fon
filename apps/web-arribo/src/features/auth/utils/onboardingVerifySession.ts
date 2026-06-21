import type { NavigateFunction } from 'react-router-dom'

const VERIFY_SETUP_PREFIX = 'facturaon:onboarding:setup:'
const VERIFY_LOCK_PREFIX = 'facturaon:onboarding:verify-lock:'

function setupStorageKey(verifyToken: string) {
  return `${VERIFY_SETUP_PREFIX}${verifyToken}`
}

function lockStorageKey(verifyToken: string) {
  return `${VERIFY_LOCK_PREFIX}${verifyToken}`
}

export function readCachedSetupToken(verifyToken: string): string | null {
  const value = sessionStorage.getItem(setupStorageKey(verifyToken))?.trim()
  return value || null
}

export function cacheSetupToken(verifyToken: string, setupToken: string) {
  sessionStorage.setItem(setupStorageKey(verifyToken), setupToken)
  sessionStorage.setItem(lockStorageKey(verifyToken), 'done')
}

export function clearVerifySession(verifyToken: string) {
  sessionStorage.removeItem(setupStorageKey(verifyToken))
  sessionStorage.removeItem(lockStorageKey(verifyToken))
}

export function beginVerifySession(verifyToken: string): 'start' | 'pending' | 'done' {
  const lockKey = lockStorageKey(verifyToken)

  if (sessionStorage.getItem(lockKey) === 'done') {
    return 'done'
  }

  if (sessionStorage.getItem(lockKey) === 'pending') {
    return 'pending'
  }

  sessionStorage.setItem(lockKey, 'pending')
  return 'start'
}

export function failVerifySession(verifyToken: string) {
  sessionStorage.removeItem(lockStorageKey(verifyToken))
}

export function waitForCachedSetupToken(
  verifyToken: string,
  onReady: (setupToken: string) => void,
) {
  const cached = readCachedSetupToken(verifyToken)
  if (cached) {
    onReady(cached)
    return () => undefined
  }

  const intervalId = window.setInterval(() => {
    const setupToken = readCachedSetupToken(verifyToken)
    if (setupToken) {
      window.clearInterval(intervalId)
      onReady(setupToken)
    }
  }, 250)

  return () => {
    window.clearInterval(intervalId)
  }
}

export function redirectToSetupPassword(setupToken: string, navigate: NavigateFunction) {
  navigate(
    `/onboarding/establecer-password?token=${encodeURIComponent(setupToken)}`,
    { replace: true },
  )
}
