import { useState } from 'react'

export function useTableRowSelection<TId extends number | string = number>() {
  const [selectedId, setSelectedId] = useState<TId | null>(null)

  function isSelected(id: TId) {
    return selectedId === id
  }

  function select(id: TId) {
    setSelectedId(id)
  }

  function clearSelection() {
    setSelectedId(null)
  }

  return {
    selectedId,
    setSelectedId,
    isSelected,
    select,
    clearSelection,
  }
}
