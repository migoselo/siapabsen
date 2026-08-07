<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AttendanceAdminController extends Controller
{
    public function index(Request $request)
    {
        $query = Attendance::with(['employee', 'location']);

        if ($request->filled('location_id')) {
            $query->where('location_id', $request->location_id);
        }

        if ($request->filled('employee_id')) {
            $query->where('employee_id', $request->employee_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('date')) {
            $query->whereDate('check_in_time', $request->date);
        }

        return response()->json($query->orderByDesc('check_in_time')->paginate(20));
    }

    public function show(Attendance $attendance)
    {
        $attendance->load(['employee', 'location']);
        $attendance->photo_available = (bool) $attendance->check_in_photo
            && Storage::disk('public')->exists($attendance->check_in_photo);

        return response()->json($attendance);
    }

    public function photo(Attendance $attendance)
    {
        $photoPath = $attendance->check_in_photo;
        if (! $photoPath || ! Storage::disk('public')->exists($photoPath)) {
            return response()->json(['message' => 'Foto tidak ditemukan.'], 404);
        }

        return response()->file(Storage::disk('public')->path($photoPath));
    }

    public function approve(Attendance $attendance)
    {
        $attendance->update(['status' => 'approved']);

        return response()->json($attendance->fresh());
    }

    public function reject(Request $request, Attendance $attendance)
    {
        $request->validate([
            'reason' => 'nullable|string|max:255',
        ]);

        $attendance->update(['status' => 'rejected']);

        return response()->json($attendance->fresh());
    }
}
