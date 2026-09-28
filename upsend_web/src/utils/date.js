export function formatDateInput(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function formatDateDisplay(value) {
  if (!value) return 'dd / mm / yyyy'
  const [year, month, day] = value.split('-')
  return `${day} / ${month} / ${year}`
}

export function parseDateInput(value) {
  if (!value) return new Date()
  const [year, month, day] = value.split('-').map(Number)
  return new Date(year, month - 1, day)
}

/**
 * Hitung rentang tanggal dari filter { period, startDate, endDate }.
 */
export function dateRangeForPeriod(filter) {
  const today = new Date()
  const todayValue = formatDateInput(today)

  if (filter.period === 'all') return { startDate: '', endDate: '' }
  if (filter.period === 'today') return { startDate: todayValue, endDate: todayValue }

  if (filter.period === 'week') {
    const start = new Date(today)
    const day = start.getDay()
    const daysSinceMonday = day === 0 ? 6 : day - 1
    start.setDate(today.getDate() - daysSinceMonday)
    const end = new Date(start)
    end.setDate(start.getDate() + 6)
    return { startDate: formatDateInput(start), endDate: formatDateInput(end) }
  }

  if (filter.period === 'month') {
    return {
      startDate: formatDateInput(new Date(today.getFullYear(), today.getMonth(), 1)),
      endDate: formatDateInput(new Date(today.getFullYear(), today.getMonth() + 1, 0)),
    }
  }

  return { startDate: filter.startDate, endDate: filter.endDate }
}