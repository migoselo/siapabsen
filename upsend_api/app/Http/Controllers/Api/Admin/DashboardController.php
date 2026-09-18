<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Location;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary(Request $request)
    {
        [$startDate, $endDate] = $this->periodDates($request);

        $usersQuery = User::whereNotIn('role', ['admin', 'super_admin'])
            ->where('is_active', true);
        $attendanceQuery = Attendance::whereBetween('check_in_time', [
            $startDate . ' 00:00:00',
            $endDate . ' 23:59:59',
        ])
            ->whereHas('employee', function ($query) {
                $query->whereNotIn('role', ['admin', 'super_admin'])
                    ->where('is_active', true);
            });

        if ($request->filled('location_id')) {
            $usersQuery->where('home_location_id', $request->location_id);
            $attendanceQuery->whereHas('employee', function ($query) use ($request) {
                $query->where('home_location_id', $request->location_id);
            });
        }

        $hadirHariIni = (clone $attendanceQuery)->distinct('employee_id')->count('employee_id');
        $pendingReview = (clone $attendanceQuery)->where('status', 'pending')->count();

        return response()->json([
            'total_karyawan_aktif' => $usersQuery->count(),
            'total_lokasi' => Location::count(),
            'hadir_hari_ini' => $hadirHariIni,
            'pending_review' => $pendingReview,
        ]);
    }

    public function trend(Request $request)
    {
        return match ($request->input('period', 'hari')) {
            'minggu' => $this->weeklyBucketTrend($request),
            'bulan' => $this->monthlyBucketTrend($request),
            default => $this->dailyBucketTrend($request),
        };
    }

    private function dailyBucketTrend(Request $request)
    {
        $days = 7;
        $rangeStart = now()->subDays($days - 1)->startOfDay();
        $counts = $this->attendanceDailyCounts($rangeStart, now()->endOfDay(), $request);

        $chartData = [];
        $totalCount = 0;
        $today = now()->toDateString();

        for ($i = $days - 1; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $dayKey = $day->format('Y-m-d');
            $count = (int) ($counts[$dayKey] ?? 0);
            $totalCount += $count;

            $chartData[] = [
                'label' => $day->translatedFormat('D'),
                'count' => $count,
                'start_date' => $dayKey,
                'end_date' => $dayKey,
                'isCurrent' => $dayKey === $today,
            ];
        }

        return response()->json([
            'averageLabel' => "Rata-rata " . ($totalCount > 0 ? round($totalCount / $days) : 0) . " hadir per hari",
            'chartData' => $chartData,
        ]);
    }

    private function weeklyBucketTrend(Request $request)
    {
        $weeks = 8;
        $rangeStart = now()->subWeeks($weeks - 1)->startOfWeek();
        $counts = $this->attendanceDailyCounts($rangeStart, now()->endOfWeek(), $request);

        $chartData = [];
        $totalCount = 0;
        $currentWeekKey = now()->startOfWeek()->toDateString();

        for ($i = $weeks - 1; $i >= 0; $i--) {
            $weekStart = now()->subWeeks($i)->startOfWeek();
            $weekEnd = $weekStart->copy()->endOfWeek();

            $weekTotal = 0;
            for ($d = $weekStart->copy(); $d->lte($weekEnd); $d->addDay()) {
                $weekTotal += (int) ($counts[$d->format('Y-m-d')] ?? 0);
            }
            $totalCount += $weekTotal;

            $chartData[] = [
                'label' => $weekStart->format('d/m') . '-' . $weekEnd->format('d/m'),
                'count' => $weekTotal,
                'start_date' => $weekStart->toDateString(),
                'end_date' => $weekEnd->toDateString(),
                'isCurrent' => $weekStart->toDateString() === $currentWeekKey,
            ];
        }

        return response()->json([
            'averageLabel' => "Rata-rata " . ($totalCount > 0 ? round($totalCount / $weeks) : 0) . " hadir per minggu",
            'chartData' => $chartData,
        ]);
    }

    private function monthlyBucketTrend(Request $request)
    {
        $months = 12;
        $rangeStart = now()->startOfMonth()->subMonths($months - 1); 
        $counts = $this->attendanceDailyCounts($rangeStart, now()->endOfMonth(), $request);

        $chartData = [];
        $totalCount = 0;
        $currentMonthKey = now()->format('Y-m');

        for ($i = $months - 1; $i >= 0; $i--) {
            $monthStart = now()->startOfMonth()->subMonths($i); 
            $monthEnd = $monthStart->copy()->endOfMonth();
            $monthKey = $monthStart->format('Y-m');

            $monthTotal = 0;
            for ($d = $monthStart->copy(); $d->lte($monthEnd); $d->addDay()) {
                $monthTotal += (int) ($counts[$d->format('Y-m-d')] ?? 0);
            }
            $totalCount += $monthTotal;

            $chartData[] = [
                'label' => $monthStart->translatedFormat('M'),
                'count' => $monthTotal,
                'start_date' => $monthStart->toDateString(),
                'end_date' => $monthEnd->toDateString(),
                'isCurrent' => $monthKey === $currentMonthKey,
            ];
        }

        return response()->json([
            'averageLabel' => "Rata-rata " . ($totalCount > 0 ? round($totalCount / $months) : 0) . " hadir per bulan",
            'chartData' => $chartData,
        ]);
    }

    private function attendanceDailyCounts($rangeStart, $rangeEnd, Request $request): array
    {
        $query = Attendance::selectRaw(
            'CAST(check_in_time AS date) as attendance_date, COUNT(DISTINCT employee_id) as total'
        )
            ->whereBetween('check_in_time', [$rangeStart->toDateTimeString(), $rangeEnd->toDateTimeString()])
            ->whereHas('employee', function ($q) {
                $q->whereNotIn('role', ['admin', 'super_admin'])->where('is_active', true);
            })
            ->groupByRaw('CAST(check_in_time AS date)');

        if ($request->filled('location_id')) {
            $query->where('location_id', $request->location_id);
        }

        return $query->pluck('total', 'attendance_date')->toArray();
    }

    public function todayAttendance(Request $request)
    {
        [$startDate, $endDate] = $this->periodDates($request);

        $attendanceQuery = Attendance::select(
            'id',
            'employee_id',
            'location_id',
            'check_in_time',
            'check_out_time',
        )
            ->whereBetween('check_in_time', [
                $startDate . ' 00:00:00',
                $endDate . ' 23:59:59',
            ])
            ->orderBy('check_in_time')
            ->with(['location:id,name', 'employee:id,name,home_location_id'])
            ->whereHas('employee', function ($query) {
                $query->whereNotIn('role', ['admin', 'super_admin'])
                    ->where('is_active', true);
            });

        if ($request->filled('location_id')) {
            $attendanceQuery->whereHas('employee', function ($query) use ($request) {
                $query->where('home_location_id', $request->location_id);
            });
        }

        $attendanceRecords = $attendanceQuery->get();
        $attendances = $attendanceRecords->keyBy(fn($attendance) => (string) $attendance->employee_id);

        $isPeriodView = $startDate !== $endDate;
        if ($isPeriodView) {
            $today = now()->toDateString();
            $data = $attendanceRecords->map(function ($attendance) use ($today) {
                return [
                    'id' => $attendance->employee_id,
                    'attendanceId' => $attendance->id,
                    'name' => $attendance->employee?->name ?? '-',
                    'location' => $attendance->location?->name ?? '-',
                    'checkIn' => optional($attendance->check_in_time)->format('H:i'),
                    'checkOut' => optional($attendance->check_out_time)->format('H:i'),
                    'status' => $this->attendanceDisplayStatus($attendance, $today),
                ];
            })->values();

            return response()->json([
                'date' => $startDate === $endDate ? $startDate : "$startDate - $endDate",
                'employees' => $data,
            ]);
        }

        $employeesQuery = User::whereNotIn('role', ['admin', 'super_admin'])
            ->where('is_active', true)
            ->select('id', 'name', 'home_location_id')
            ->with('homeLocation:id,name')
            ->orderBy('name');

        if ($request->filled('location_id')) {
            $employeesQuery->where('home_location_id', $request->location_id);
        }

        $employees = $employeesQuery->get();

        $today = now()->toDateString();
        $isToday = $startDate === $today;
        $data = $employees->map(function ($emp) use ($attendances, $isToday, $today, $startDate) {
            $att = $attendances->get((string) $emp->id);
            $status = $att
                ? $this->attendanceDisplayStatus($att, $today)
                : ($isToday ? 'absent' : 'alpha');

            return [
                'id' => $emp->id,
                'attendanceId' => $att?->id,
                'name' => $emp->name,
                'location' => $att?->location?->name ?? $emp->homeLocation?->name ?? '-',
                'checkIn' => optional($att?->check_in_time)->format('H:i'),
                'checkOut' => optional($att?->check_out_time)->format('H:i'),
                'status' => $status,
            ];
        });

        return response()->json([
            'date' => $startDate === $endDate ? $startDate : "$startDate - $endDate",
            'employees' => $data,
        ]);
    }

    private function attendanceDisplayStatus(Attendance $attendance, string $today): string
    {
        $checkInDate = $attendance->check_in_time?->toDateString();

        if (
            $attendance->check_out_time &&
            $attendance->check_out_time->toDateString() !== $checkInDate
        ) {
            return 'lupa_absen';
        }

        if ($attendance->check_out_time) {
            return 'checkout';
        }

        return $checkInDate === $today ? 'working' : 'lupa_absen';
    }

    private function periodDates(Request $request): array
    {
        if ($request->filled('start_date') && $request->filled('end_date')) {
            return [$request->start_date, $request->end_date];
        }

        if ($request->filled('date')) {
            return [$request->date, $request->date];
        }

        $today = now();
        return match ($request->input('period', 'hari')) {
            'minggu' => [
                $today->copy()->startOfWeek()->toDateString(),
                $today->copy()->endOfWeek()->toDateString(),
            ],
            'bulan' => [
                $today->copy()->startOfMonth()->toDateString(),
                $today->copy()->endOfMonth()->toDateString(),
            ],
            default => [$today->toDateString(), $today->toDateString()],
        };
    }

    public function byLocation(Request $request)
    {
        $query = Attendance::select(
            'location_id',
            DB::raw('COUNT(DISTINCT employee_id) as total_hadir'),
            DB::raw("SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as total_pending"),
            DB::raw("SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as total_rejected")
        )
            ->with('location:id,name')
            ->groupBy('location_id');

        if ($request->filled('start_date')) {
            $query->whereDate('check_in_time', '>=', $request->start_date);
        }

        if ($request->filled('end_date')) {
            $query->whereDate('check_in_time', '<=', $request->end_date);
        }

        return response()->json($query->get());
    }

    public function anomalies(Request $request)
    {
        $query = Attendance::whereIn('status', ['pending', 'rejected'])
            ->with(['employee:id,name', 'location:id,name']);

        if ($request->filled('location_id')) {
            $query->where('location_id', $request->location_id);
        }

        return response()->json($query->orderByDesc('check_in_time')->paginate(20));
    }

    public function export(Request $request)
    {
        $query = Attendance::with(['employee:id,name', 'location:id,name']);

        if ($request->filled('location_id')) {
            $query->where('location_id', $request->location_id);
        }

        if ($request->filled('start_date')) {
            $query->whereDate('check_in_time', '>=', $request->start_date);
        }

        if ($request->filled('end_date')) {
            $query->whereDate('check_in_time', '<=', $request->end_date);
        }

        $data = $query->orderBy('check_in_time')->get();

        // TODO: pasang package maatwebsite/excel, lalu ganti jadi:
        // return Excel::download(new AttendanceExport($data), 'laporan-absensi.xlsx');
        return response()->json($data);
    }
}