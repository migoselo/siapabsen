<script setup>
/**
 * BasePeriodFilter.vue
 * Filter periode (Semua / Hari Ini / Minggu Ini / Bulan Ini / Custom + kalender).
 * Pakai: <BasePeriodFilter :model-value="filter" @change="onPeriodChange" />
 * modelValue: { period, startDate, endDate }
 * Emit `change` dengan objek baru { period, startDate, endDate }.
 */
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { Icon } from '@iconify/vue'
import { formatDateInput, formatDateDisplay, parseDateInput } from '../utils/date'

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => ({ period: 'all', startDate: '', endDate: '' }),
  },
})
const emit = defineEmits(['change'])

const quickPeriodOptions = [
  { value: 'all', label: 'Semua' },
  { value: 'today', label: 'Hari Ini' },
  { value: 'week', label: 'Minggu Ini' },
  { value: 'month', label: 'Bulan Ini' },
]
const weekdayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
const monthFormatter = new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' })

const showCustomPanel = ref(false)
const showCalendar = ref(false)
const activeDateField = ref('start')
const customStartDate = ref('')
const customEndDate = ref('')
const visibleMonth = ref(new Date())

// Saat panel custom terbuka, tombol Custom dianggap aktif
const activePeriod = computed(() => (showCustomPanel.value ? 'custom' : props.modelValue.period))
const todayDateValue = computed(() => formatDateInput(new Date()))
const calendarMonthLabel = computed(() => monthFormatter.format(visibleMonth.value))
const canSave = computed(
  () => customStartDate.value && customEndDate.value && customStartDate.value <= customEndDate.value,
)

const calendarDays = computed(() => {
  const year = visibleMonth.value.getFullYear()
  const month = visibleMonth.value.getMonth()
  const firstDay = new Date(year, month, 1).getDay()
  const isStart = activeDateField.value === 'start'
  const otherDate = isStart ? customEndDate.value : customStartDate.value
  const selectedValue = isStart ? customStartDate.value : customEndDate.value

  return Array.from({ length: 42 }, (_, index) => {
    const date = new Date(year, month, index - firstDay + 1)
    const value = formatDateInput(date)
    const outOfRange = isStart ? otherDate && value > otherDate : otherDate && value < otherDate
    return {
      day: date.getDate(),
      value,
      isCurrentMonth: date.getMonth() === month,
      isToday: value === todayDateValue.value,
      isSelected: value === selectedValue,
      disabled: value > todayDateValue.value || Boolean(outOfRange),
    }
  })
})

function selectPeriod(period) {
  if (period === 'custom') {
    customStartDate.value = props.modelValue.startDate
    customEndDate.value = props.modelValue.endDate
    showCustomPanel.value = true
    return
  }
  showCustomPanel.value = false
  showCalendar.value = false
  emit('change', { ...props.modelValue, period })
}

function cancelCustomPeriod() {
  showCalendar.value = false
  showCustomPanel.value = false
}

function saveCustomPeriod() {
  if (!canSave.value) return
  if (customStartDate.value > todayDateValue.value || customEndDate.value > todayDateValue.value) return
  showCalendar.value = false
  showCustomPanel.value = false
  emit('change', { period: 'custom', startDate: customStartDate.value, endDate: customEndDate.value })
}

function openCalendar(field) {
  activeDateField.value = field
  visibleMonth.value = parseDateInput(field === 'start' ? customStartDate.value : customEndDate.value)
  showCalendar.value = true
}

function changeCalendarMonth(offset) {
  visibleMonth.value = new Date(
    visibleMonth.value.getFullYear(),
    visibleMonth.value.getMonth() + offset,
    1,
  )
}

function selectCalendarDate(day) {
  if (day.disabled || !day.isCurrentMonth) return
  if (activeDateField.value === 'start') customStartDate.value = day.value
  else customEndDate.value = day.value
  showCalendar.value = false
}

function closeCalendar() {
  showCalendar.value = false
}
onMounted(() => document.addEventListener('click', closeCalendar))
onBeforeUnmount(() => document.removeEventListener('click', closeCalendar))
</script>

<template>
  <div class="period-filter" @click.stop>
    <span>Periode</span>
    <div class="period-controls">
      <div class="period-segmented">
        <button
          v-for="option in quickPeriodOptions"
          :key="option.value"
          type="button"
          :class="{ active: activePeriod === option.value }"
          @click="selectPeriod(option.value)"
        >
          {{ option.label }}
        </button>
      </div>

      <div class="custom-period">
        <button
          type="button"
          class="custom-period-button"
          :class="{ active: activePeriod === 'custom' }"
          @click="selectPeriod('custom')"
        >
          <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
          Custom
        </button>

        <div v-if="showCustomPanel" class="custom-date-range">
          <div class="date-range-fields">
            <label>
              <span>Dari</span>
              <button
                type="button"
                class="date-field"
                :class="{ focused: activeDateField === 'start' && showCalendar }"
                @click.stop="openCalendar('start')"
              >
                {{ formatDateDisplay(customStartDate) }}
                <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
              </button>
            </label>
            <span class="range-separator">-</span>
            <label>
              <span>Sampai</span>
              <button
                type="button"
                class="date-field"
                :class="{ focused: activeDateField === 'end' && showCalendar }"
                @click.stop="openCalendar('end')"
              >
                {{ formatDateDisplay(customEndDate) }}
                <Icon icon="material-symbols:calendar-today-outline" width="16" height="16" />
              </button>
            </label>

            <div
              v-if="showCalendar"
              class="calendar-popup"
              :class="{ 'calendar-for-end': activeDateField === 'end' }"
              @click.stop
            >
              <div class="calendar-header">
                <button type="button" aria-label="Bulan sebelumnya" @click="changeCalendarMonth(-1)">
                  <Icon icon="material-symbols:chevron-left-rounded" width="20" height="20" />
                </button>
                <strong>{{ calendarMonthLabel }}</strong>
                <button type="button" aria-label="Bulan berikutnya" @click="changeCalendarMonth(1)">
                  <Icon icon="material-symbols:chevron-right-rounded" width="20" height="20" />
                </button>
              </div>
              <div class="calendar-weekdays">
                <span v-for="weekday in weekdayLabels" :key="weekday">{{ weekday }}</span>
              </div>
              <div class="calendar-grid">
                <button
                  v-for="day in calendarDays"
                  :key="day.value"
                  type="button"
                  class="calendar-day"
                  :class="{ muted: !day.isCurrentMonth, today: day.isToday, selected: day.isSelected }"
                  :disabled="day.disabled"
                  @click="selectCalendarDate(day)"
                >
                  {{ day.day }}
                </button>
              </div>
            </div>
          </div>

          <div class="custom-date-actions">
            <button type="button" class="cancel-button" @click="cancelCustomPeriod">Batal</button>
            <button type="button" class="save-button" :disabled="!canSave" @click="saveCustomPeriod">
              Simpan
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.period-filter { display: flex; flex-direction: column; gap: 5px; font-family: inherit; }
.period-filter > span { color: #667085; font-size: 11px; }
.period-controls { display: flex; align-items: center; gap: 8px; }
.period-segmented {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 4px;
  border: 1px solid #d9dde5;
  border-radius: 10px;
  background: #fff;
}
.period-segmented button {
  height: 32px;
  padding: 0 16px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #667085;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.period-segmented button.active { background: #2f3b69; color: #fff; }
.custom-period { position: relative; }
.custom-period-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 40px;
  padding: 0 13px;
  border: 1px solid #d9dde5;
  border-radius: 10px;
  background: #fff;
  color: #667085;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
.custom-period-button.active { border-color: #2f3b69; background: #2f3b69; color: #fff; }

.custom-date-range {
  position: absolute;
  z-index: 40;
  top: calc(100% + 14px);
  left: 0;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: 12px;
  min-width: 356px;
  padding: 16px;
  border: 1px solid #d9dde5;
  border-radius: 12px;
  background: #fff;
  box-shadow: 0 16px 30px rgba(0, 0, 0, 0.1);
}
.date-range-fields { position: relative; display: flex; align-items: flex-end; gap: 12px; width: 100%; }
.custom-date-range label { display: flex; flex-direction: column; gap: 5px; }
.custom-date-range label span { color: #667085; font-size: 12px; font-weight: 600; }
.date-field {
  display: inline-flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 148px;
  min-width: 148px;
  height: 40px;
  padding: 0 11px;
  border: 1px solid #d9dde5;
  border-radius: 9px;
  background: #fff;
  color: #1c1c19;
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}
.date-field.focused { border-color: #2f3b69; box-shadow: 0 0 0 3px rgba(47, 59, 105, 0.12); }
.date-field .iconify { flex-shrink: 0; color: #667085; }
.range-separator { padding-bottom: 11px; color: #667085; font-size: 14px; font-weight: 600; }

.custom-date-actions { display: flex; justify-content: flex-end; gap: 8px; width: 100%; margin-top: 4px; }
.custom-date-actions button {
  height: 34px;
  padding: 0 14px;
  border-radius: 8px;
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}
.cancel-button { border: 1px solid #d9dde5; background: #fff; color: #667085; }
.save-button { border: 1px solid #2f3b69; background: #2f3b69; color: #fff; }
.save-button:disabled { opacity: 0.45; cursor: not-allowed; }

.calendar-popup {
  position: absolute;
  z-index: 50;
  top: calc(100% + 10px);
  left: 0;
  width: 328px;
  padding: 14px;
  border: 1px solid #d9dde5;
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 18px 36px rgba(28, 28, 25, 0.16);
}
.calendar-popup.calendar-for-end { left: auto; right: 0; }
.calendar-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.calendar-header strong { color: #1c1c19; font-size: 15px; text-transform: capitalize; }
.calendar-header button {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #667085;
  cursor: pointer;
}
.calendar-header button:hover { background: #f7f8fa; color: #2f3b69; }
.calendar-weekdays, .calendar-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
.calendar-weekdays { margin-bottom: 6px; }
.calendar-weekdays span { color: #667085; font-size: 11px; font-weight: 700; text-align: center; }
.calendar-weekdays span:first-child, .calendar-weekdays span:last-child { color: #c65a5a; }
.calendar-day {
  display: grid;
  place-items: center;
  width: 100%;
  aspect-ratio: 1;
  border: 0;
  border-radius: 8px;
  background: transparent;
  color: #1c1c19;
  font: inherit;
  font-size: 12px;
  cursor: pointer;
}
.calendar-day:hover:not(:disabled) { background: #eef0f7; color: #2f3b69; }
.calendar-day.muted { color: #b7bcc7; }
.calendar-day.today { box-shadow: inset 0 0 0 1px #2f3b69; }
.calendar-day.selected { background: #2f3b69; color: #fff; font-weight: 700; }
.calendar-day:disabled { color: #d5d8df; cursor: not-allowed; }
</style>