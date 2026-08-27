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
            $attendanceQuery->where('location_id', $request->location_id);
        }

        return response()->json([
            'total_karyawan_aktif' => $usersQuery->count(),
            'total_lokasi' => Location::count(),
            'hadir_hari_ini' => $attendanceQuery->distinct('employee_id')->count('employee_id'),
            'pending_review' => $attendanceQuery->where('status', 'pending')->count(),
        ]);
    }

    public function weeklyTrend(Request $request)
    {
        $startDate = now()->subDays(6)->toDateString();

        $attendanceQuery = Attendance::selectRaw(
                'CAST(check_in_time AS date) as attendance_date, COUNT(DISTINCT employee_id) as total'
            )
            ->whereDate('check_in_time', '>=', $startDate)
            ->whereHas('employee', function ($query) {
                $query->whereNotIn('role', ['admin', 'super_admin'])
                    ->where('is_active', true);
            })
            ->groupByRaw('CAST(check_in_time AS date)');
        if ($request->filled('location_id')) {
            $attendanceQuery->where('location_id', $request->location_id);
        }

        $attendances = $attendanceQuery->get()->keyBy('attendance_date');

        $chartData = [];
        $totalCount = 0;

        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $dayKey = $day->format('Y-m-d');
            $count = (int) ($attendances->get($dayKey)?->total ?? 0);
            $totalCount += $count;

            $chartData[] = [
                'date' => $dayKey,
                'label' => $day->translatedFormat('D'),
                'count' => $count,
            ];
        }

        $weeklyAverage = $totalCount > 0 ? round($totalCount / 7) : 0;

        return response()->json([
            'weeklyAverageLabel' => "Rata-rata $weeklyAverage hadir per hari",
            'chartData' => $chartData,
        ]);
    }

    public function todayAttendance(Request $request)
    {
        [$startDate, $endDate] = $this->periodDates($request);

        $attendanceQuery = Attendance::select(
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
            $attendanceQuery->where('location_id', $request->location_id);
        }

        $attendanceRecords = $attendanceQuery->get();
        $attendances = $attendanceRecords->keyBy('employee_id');

        $isPeriodView = !$request->filled('date') && $request->input('period', 'hari') !== 'hari';
        if ($isPeriodView) {
            $data = $attendanceRecords->map(function ($attendance) {
                return [
                    'id' => $attendance->employee_id,
                    'name' => $attendance->employee?->name ?? '-',
                    'location' => $attendance->location?->name ?? '-',
                    'checkIn' => optional($attendance->check_in_time)->format('H:i'),
                    'checkOut' => optional($attendance->check_out_time)->format('H:i'),
                    'status' => $attendance->check_out_time ? 'checkout' : 'working',
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

        // With a location filter, activity means employees who actually
        // checked in at that location on the selected date.
        if ($request->filled('location_id')) {
            $employeesQuery->whereIn('id', $attendances->keys());
        }

        $employees = $employeesQuery->get();

        $data = $employees->map(function ($emp) use ($attendances) {
            $att = $attendances->get($emp->id);
            $status = 'absent';

            if ($att) {
                $status = $att->check_out_time ? 'checkout' : 'working';
            }

            return [
                'id' => $emp->id,
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

    private function periodDates(Request $request): array
    {
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