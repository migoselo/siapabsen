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
    public function summary()
    {
        $today = now()->toDateString();

        return response()->json([
            'total_karyawan_aktif' => User::where('role', 'karyawan')->where('is_active', true)->count(),
            'total_lokasi' => Location::count(),
            'hadir_hari_ini' => Attendance::whereDate('check_in_time', $today)->distinct('employee_id')->count('employee_id'),
            'pending_review' => Attendance::where('status', 'pending')->count(),
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
        // Absen di luar radius (pending) atau yang udah ditolak -> indikasi kecurangan / kesalahan GPS
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
