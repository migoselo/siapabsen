<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\LeaveType;
use Illuminate\Http\Request;

class LeaveRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = LeaveRequest::where('user_id', $request->user()->id)
            ->orderByDesc('created_at');

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => 'nullable|string|max:255',
            'leave_type_id' => 'nullable|integer|exists:leave_types,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'required|string',
            'attachment_path' => 'nullable|string',
        ], [
            'leave_type_id.exists' => 'Tipe cuti tidak valid. Silakan pilih tipe cuti yang tersedia.',
            'start_date.required' => 'Tanggal mulai harus diisi.',
            'start_date.date' => 'Tanggal mulai harus berupa tanggal yang valid.',
            'end_date.required' => 'Tanggal selesai harus diisi.',
            'end_date.date' => 'Tanggal selesai harus berupa tanggal yang valid.',
            'end_date.after_or_equal' => 'Tanggal selesai harus sama atau setelah tanggal mulai.',
            'reason.required' => 'Alasan cuti harus diisi.',
            'reason.string' => 'Alasan cuti harus berupa teks.',
        ]);

        $typeName = trim((string) ($data['type'] ?? ''));
        if ($typeName === '' && !empty($data['leave_type_id'])) {
            $leaveType = LeaveType::find($data['leave_type_id']);
            $typeName = $leaveType?->name ?? 'Cuti';
        }

        if ($typeName !== '') {
            $leaveType = LeaveType::firstOrCreate([
                'name' => $typeName,
            ]);
            $data['leave_type_id'] = $leaveType->id;
            $data['type'] = $typeName;
        }

        // Calculate total_days
        $startDate = new \DateTime($data['start_date']);
        $endDate = new \DateTime($data['end_date']);
        $interval = $startDate->diff($endDate);
        $totalDays = $interval->days + 1; // +1 to include both start and end date

        $payload = [
            'user_id' => $request->user()->id,
            'leave_type_id' => $data['leave_type_id'] ?? 1,
            'type' => $data['type'] ?? 'Cuti',
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'reason' => $data['reason'],
            'attachment_path' => $data['attachment_path'] ?? null,
            'status' => 'pending',
            'total_days' => $totalDays,
        ];

        $leaveRequest = LeaveRequest::create($payload);

        return response()->json($leaveRequest, 201);
    }
}
