<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, CheckCircle2, Plus, Trash2 } from 'lucide-vue-next'
import api from '../api'

const route = useRoute()
const router = useRouter()
const employees = ref([])
const loading = ref(false)

const isEdit = computed(() => Boolean(route.params.employeeId))
const selectedEmployeeId = ref(route.params.employeeId ? String(route.params.employeeId) : '')
const selectedEmployee = computed(() =>
  employees.value.find((item) => String(item.id) === selectedEmployeeId.value),
)
const basic = ref(0)
const positionAllowance = ref(0)
const certificationAllowance = ref(0)
const internetAllowance = ref(0)
const mealAllowance = ref(0)
const taxMethod = ref('TER Bulanan')
const bpjsEmployment = ref(true)
const bpjsHealth = ref(true)
const loan = ref(0)
const customComponents = ref([])
const money = (value) => `Rp ${Math.round(value || 0).toLocaleString('id-ID')}`

async function fetchEmployees() {
  loading.value = true
  try {
    const res = await api.get('/users', { params: { per_page: 100 } })
    employees.value = Array.isArray(res.data?.data) ? res.data.data : []
    if (!selectedEmployeeId.value && employees.value[0]) {
      selectedEmployeeId.value = String(employees.value[0].id)
    }
  } catch (error) {
    console.error('Gagal mengambil data karyawan:', error)
    employees.value = []
  } finally {
    loading.value = false
  }
}

watch(
  selectedEmployee,
  (employee) => {
    if (!employee) return
    basic.value = Number(employee.gaji_pokok ?? employee.basic_salary ?? employee.basic ?? 0)
    positionAllowance.value = Number(employee.tunjangan_jabatan ?? employee.transport_allowance ?? 0)
    internetAllowance.value = Number(employee.allowance_variable ?? employee.attendance_allowance ?? 0)
    mealAllowance.value = Number(employee.meal_allowance ?? 0)
    loan.value =
      Number(employee.potongan ?? employee.other_deduction ?? employee.loan_deduction ?? 0)
  },
  { immediate: true },
)

function handleBack() {
  router.push({ name: 'gaji' })
}

async function handleSave() {
  if (!selectedEmployee.value) {
    window.alert('Pilih identitas karyawan terlebih dahulu.')
    return
  }

  const payload = {
    user_id: Number(selectedEmployeeId.value),
    payroll_period: new Date().toISOString().slice(0, 10),
    basic_salary: Number(basic.value || 0),
    transport_allowance: Number(positionAllowance.value || 0),
    meal_allowance: Number(mealAllowance.value || 0),
    attendance_allowance: Number(internetAllowance.value || 0),
    other_allowance: customComponents.value.reduce((sum, item) => sum + Number(item.amount || 0), 0),
    tax_deduction: taxMethod.value === 'Ditanggung Kantor' ? 0 : Number(calculation.value.tax || 0),
    other_deduction: Number(loan.value || 0),
    bank_name: 'Bank Mandiri',
    bank_account_name: selectedEmployee.value.name,
    bank_account_number: '0000000000',
  }

  try {
    if (isEdit.value) {
      const existing = await api.get('/payrolls', { params: { user_id: payload.user_id, per_page: 1 } })
      const payroll = Array.isArray(existing.data?.data) ? existing.data.data[0] : null
      if (payroll?.id) {
        await api.put(`/payrolls/${payroll.id}`, payload)
      } else {
        await api.post('/payrolls', payload)
      }
    } else {
      await api.post('/payrolls', payload)
    }

    window.alert('Data gaji berhasil disiapkan.')
    router.push({ name: 'gaji' })
  } catch (error) {
    console.error('Gagal menyimpan payroll:', error)
    window.alert(error.response?.data?.message || 'Gagal menyimpan data gaji.')
  }
}

const calculation = computed(() => {
  const fixed = Number(positionAllowance.value || 0) + Number(certificationAllowance.value || 0)
  const variable =
    Number(internetAllowance.value || 0) +
    Number(mealAllowance.value || 0) +
    customComponents.value.reduce((sum, item) => sum + Number(item.amount || 0), 0)
  const gross = Number(basic.value || 0) + fixed + variable
  const employment = bpjsEmployment.value ? Number(basic.value || 0) * 0.03 : 0
  const health = bpjsHealth.value ? Math.min(Number(basic.value || 0), 12000000) * 0.01 : 0
  const tax = taxMethod.value === 'Ditanggung Kantor' ? 0 : gross * 0.0122
  const deductions = employment + health + tax + Number(loan.value || 0)
  return {
    fixed,
    variable,
    gross,
    employment,
    health,
    tax,
    deductions,
    takeHome: gross - deductions,
    companyCost:
      gross +
      (bpjsEmployment.value ? Number(basic.value || 0) * 0.1026 : 0) +
      (bpjsHealth.value ? Math.min(Number(basic.value || 0), 12000000) * 0.0417 : 0),
  }
})
function addComponent() {
  customComponents.value.push({ id: Date.now(), name: 'Tunjangan Kustom', amount: 0 })
}
function removeComponent(id) {
  customComponents.value = customComponents.value.filter((item) => item.id !== id)
}

onMounted(() => {
  fetchEmployees()
})
</script>

<template>
  <main class="form-page">
    <div class="detail-header">
      <button class="back-btn" type="button" @click="handleBack" title="Kembali">
        <ArrowLeft :size="22" />
      </button>
      <h1 class="detail-title">Form Gaji</h1>
    </div>
    <div class="layout">
      <div class="form-column">
        <section class="card employee-card">
          <p class="eyebrow">INFORMASI KARYAWAN</p>
          <label v-if="!isEdit"
            >Pilih Karyawan<select v-model="selectedEmployeeId" required>
              <option disabled value="">Pilih identitas karyawan</option>
              <option v-for="item in employees" :key="item.id" :value="String(item.id)">
                {{ item.name }} · {{ item.code }} · {{ item.title }}
              </option>
            </select></label
          ><template v-if="selectedEmployee"
            ><h2>{{ selectedEmployee.name }}</h2>
            <p>
              {{ selectedEmployee.title }} · {{ selectedEmployee.division }} ·
              {{ selectedEmployee.code }}
            </p></template
          >
          <small v-if="isEdit" class="locked-note"
            >Identitas karyawan terkunci saat mengedit.</small
          >
        </section>
        <section class="card">
          <h2>1. Pendapatan Pokok & Tunjangan Tetap</h2>
          <div class="fields">
            <label>Gaji Pokok<input v-model.number="basic" type="number" min="0" /></label
            ><label
              >Tunjangan Jabatan<input
                v-model.number="positionAllowance"
                type="number"
                min="0" /></label
            ><label
              >Tunjangan Sertifikasi<input
                v-model.number="certificationAllowance"
                type="number"
                min="0"
            /></label>
          </div>
        </section>
        <section class="card">
          <h2>2. Tunjangan Variabel & Operasional</h2>
          <div class="fields">
            <label
              >Tunjangan Internet & WFH<input
                v-model.number="internetAllowance"
                type="number"
                min="0" /></label
            ><label
              >Makan & Transport<input v-model.number="mealAllowance" type="number" min="0"
            /></label>
          </div>
          <div v-for="component in customComponents" :key="component.id" class="custom-row">
            <input v-model="component.name" /><input
              v-model.number="component.amount"
              type="number"
              min="0"
            /><button class="danger" title="Hapus komponen" @click="removeComponent(component.id)">
              <Trash2 :size="15" />
            </button>
          </div>
          <button class="add" @click="addComponent">
            <Plus :size="16" /> Tambah Komponen Tunjangan
          </button>
        </section>
        <section class="card">
          <h2>3. Kebijakan Potongan & Pajak</h2>
          <div class="switches">
            <label><input v-model="bpjsEmployment" type="checkbox" /> BPJS Ketenagakerjaan</label
            ><label><input v-model="bpjsHealth" type="checkbox" /> BPJS Kesehatan</label>
          </div>
          <label
            >Metode PPh 21<select v-model="taxMethod">
              <option>TER Bulanan</option>
              <option>Gross Up</option>
              <option>Ditanggung Kantor</option>
            </select></label
          ><label>Potongan Kasbon<input v-model.number="loan" type="number" min="0" /></label>
        </section>
        <div class="actions">
          <button class="back" type="button" @click="handleBack">Batal</button
          ><button class="save" type="button" @click="handleSave">Simpan Perubahan</button>
        </div>
      </div>
      <aside class="preview">
        <section class="hero">
          <p>ESTIMASI TAKE HOME PAY</p>
          <strong>{{ money(calculation.takeHome) }}</strong
          ><small>Nett masuk rekening</small>
        </section>
        <section class="card">
          <h2>Simulasi Slip Payroll</h2>
          <dl>
            <dt>Gaji Kotor</dt>
            <dd>{{ money(calculation.gross) }}</dd>
            <dt>BPJS Ketenagakerjaan</dt>
            <dd>- {{ money(calculation.employment) }}</dd>
            <dt>BPJS Kesehatan</dt>
            <dd>- {{ money(calculation.health) }}</dd>
            <dt>PPh 21</dt>
            <dd>- {{ money(calculation.tax) }}</dd>
            <dt>Kasbon</dt>
            <dd>- {{ money(loan) }}</dd>
          </dl>
          <div class="total">
            <span>Total Potongan</span><b>- {{ money(calculation.deductions) }}</b>
          </div>
          <div class="company">
            Total Biaya Perusahaan <b>{{ money(calculation.companyCost) }}</b>
          </div>
          <p class="valid"><CheckCircle2 :size="16" /> Perhitungan payroll siap ditinjau</p>
        </section>
      </aside>
    </div>
  </main>
</template>

<style scoped>
.form-page {
  min-height: 100%;
  padding: 32px;
  color: #172033;
  background: #f8fafc;
  font-family: 'Plus Jakarta Sans', sans-serif;
}
.page-header,
.actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.detail-header {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 24px;
}
.back-btn {
  display: inline-grid;
  width: 40px;
  height: 40px;
  place-items: center;
  padding: 0;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #475569;
  background: #ffffff;
  cursor: pointer;
}
.back-btn:hover {
  color: #172554;
  border-color: #172554;
}
.detail-title {
  margin: 0;
  font-size: 26px;
  color: #172033;
}
h1 {
  margin: 4px 0 25px;
  font-size: 26px;
}
h2 {
  margin: 0 0 18px;
  font-size: 16px;
}
.eyebrow {
  margin: 0 0 8px;
  color: #64748b;
  font-size: 11px;
  letter-spacing: 0.12em;
}
.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 24px;
  max-width: 1280px;
}
.form-column,
.preview {
  display: grid;
  align-content: start;
  gap: 18px;
}
.card {
  padding: 22px;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  background: white;
}
.employee-card h2 {
  margin-bottom: 5px;
}
.employee-card p:last-child {
  margin: 0;
  color: #64748b;
  font-size: 13px;
}
.fields {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
label {
  display: grid;
  gap: 7px;
  margin-bottom: 14px;
  color: #475569;
  font-size: 13px;
}
input,
select {
  box-sizing: border-box;
  width: 100%;
  padding: 11px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
  outline: 0;
  color: #172033;
  background: white;
}
input:focus,
select:focus {
  border-color: #6366f1;
}
.switches {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 16px;
}
.switches label {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
}
.switches input {
  width: auto;
}
.custom-row {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 10px;
  margin-bottom: 10px;
}
.add,
.save,
.back,
.danger {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  padding: 11px 15px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
  cursor: pointer;
}
.add {
  width: 100%;
  color: #4338ca;
  background: #eef2ff;
}
.danger {
  color: #be123c;
  background: white;
}
.actions {
  justify-content: flex-end;
}
.save {
  color: white;
  background: #172554;
  border-color: #172554;
}
.back {
  color: #475569;
  background: white;
}
.hero {
  padding: 25px;
  border-radius: 14px;
  color: white;
  background: #172554;
}
.hero p {
  margin: 0 0 12px;
  color: #c7d2fe;
  font-size: 11px;
  letter-spacing: 0.08em;
}
.hero strong {
  display: block;
  margin-bottom: 8px;
  font-size: 28px;
}
.hero small {
  color: #c7d2fe;
}
dl {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 14px 8px;
  margin: 0;
  font-size: 13px;
}
dt {
  color: #64748b;
}
dd {
  margin: 0;
  font-weight: 600;
}
.total,
.company {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-top: 20px;
  padding: 13px;
  border-radius: 9px;
  background: #fff1f2;
}
.total b {
  color: #be123c;
}
.company {
  background: #eef2ff;
}
.company b {
  color: #3730a3;
}
.valid {
  display: flex;
  align-items: center;
  gap: 7px;
  margin: 18px 0 0;
  color: #059669;
  font-size: 12px;
}
@media (max-width: 900px) {
  .form-page {
    padding: 20px;
  }
  .layout {
    grid-template-columns: 1fr;
  }
  .preview {
    order: -1;
  }
}
@media (max-width: 600px) {
  .fields,
  .switches {
    grid-template-columns: 1fr;
  }
}
</style>
