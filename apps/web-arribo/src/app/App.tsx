import { BrowserRouter } from 'react-router-dom'
import { AppProviders } from '@/app/providers'
import { AppRouter } from '@/app/router'
import { DocumentMeta } from '@/components/layout/DocumentMeta'

export default function App() {
  return (
    <AppProviders>
      <BrowserRouter>
        <DocumentMeta />
        <AppRouter />
      </BrowserRouter>
    </AppProviders>
  )
}
