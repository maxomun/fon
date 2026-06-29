import { UserAccountMenu } from '@/components/layout/UserAccountMenu'

export function AppHeader() {
  return (
    <header className="app-header app-header--account">
      <div className="app-header__content">
        <div className="app-header__spacer" aria-hidden="true" />
        <UserAccountMenu />
      </div>
    </header>
  )
}
