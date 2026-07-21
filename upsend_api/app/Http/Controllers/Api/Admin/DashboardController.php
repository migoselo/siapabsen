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
        $today = now()->toDateString();

        $usersQuery = User::where('role', 'karyawan')->where('is_active', true);
        $attendanceQuery = Attendance::whereDate('check_in_time', $today);

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

        $attendanceQuery = Attendance::whereDate('check_in_time', '>=', $startDate);
        if ($request->filled('location_id')) {
            $attendanceQuery->where('location_id', $request->location_id);
        }

        $attendances = $attendanceQuery->get()->groupBy(fn ($attendance) => $attendance->check_in_time->format('Y-m-d'));

        $chartData = [];
        $totalCount = 0;

        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i);
            $dayKey = $day->format('Y-m-d');
            $count = $attendances->get($dayKey)?->unique('employee_id')->count() ?? 0;
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
        $date = $request->filled('date') ? $request->date : now()->toDateString();

        $employees = User::where('role', 'karyawan')
            ->where('is_active', true)
            ->with('homeLocation:id,name')
            ->orderBy('name')
            ->get();

        $attendanceQuery = Attendance::whereDate('check_in_time', $date);

        if ($request->filled('location_id')) {
            $attendanceQuery->where('location_id', $request->location_id);
        }

        $attendances = $attendanceQuery->get()->keyBy('employee_id');

        $data = $employees->map(function ($emp) use ($attendances) {
            $att = $attendances->get($emp->id);
            $status = 'absent';

            if ($att) {
                $status = $att->check_out_time ? 'checkout' : 'working';
            }

            return [
                'id' => $emp->id,
                'name' => $emp->name,
                'location' => $emp->homeLocation->name ?? '-',
                'checkIn' => optional($att?->check_in_time)->format('H:i'),
                'checkOut' => optional($att?->check_out_time)->format('H:i'),
                'status' => $status,
            ];
        });

        return response()->json([
            'date' => $date,
            'employees' => $data,
        ]);
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