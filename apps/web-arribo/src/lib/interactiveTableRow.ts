import type { KeyboardEvent } from 'react'

export function interactiveRowClassName(
  isSelected: boolean,
  extraClass?: string,
): string | undefined {
  const classes = [
    isSelected ? 'data-table__row--selected' : undefined,
    extraClass,
  ].filter(Boolean)

  return classes.length > 0 ? classes.join(' ') : undefined
}

export function handleInteractiveRowKeyDown(
  event: KeyboardEvent<HTMLTableRowElement>,
  onSelect: () => void,
) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    onSelect()
  }
}

export function buildInteractiveRowProps(options: {
  rowId: number
  isSelected: boolean
  onSelect: (id: number) => void
  onDoubleClick?: () => void
  extraClassName?: string
}) {
  return {
    className: interactiveRowClassName(options.isSelected, options.extraClassName),
    tabIndex: 0 as const,
    'aria-selected': options.isSelected,
    onClick: () => options.onSelect(options.rowId),
    onKeyDown: (event: KeyboardEvent<HTMLTableRowElement>) =>
      handleInteractiveRowKeyDown(event, () => options.onSelect(options.rowId)),
    onDoubleClick: options.onDoubleClick,
  }
}

export function stopRowClickPropagation(event: { stopPropagation: () => void }) {
  event.stopPropagation()
}
