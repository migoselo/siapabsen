<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\LeaveBalance;
use App\Models\LeaveType;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class LeaveRequestController extends Controller
{
    public function balances(Request $request)
    {
        $year = (int) $request->query('year', now()->year);
        $userId = $request->user()->id;

        $currentYearBalances = LeaveBalance::where('user_id', $userId)
            ->where('year', $year)
            ->get();

        // Only inspect the previous year when the current year has no data.
        if ($currentYearBalances->isEmpty()) {
            $previousBalances = LeaveBalance::where('user_id', $userId)
                ->where('year', $year - 1)
                ->get();

            foreach ($previousBalances as $previousBalance) {
                LeaveBalance::firstOrCreate(
                    [
                        'user_id' => $userId,
                        'leave_type_id' => $previousBalance->leave_type_id,
                        'year' => $year,
                    ],
                    [
                        'quota_days' => $previousBalance->quota_days,
                        'used_days' => 0,
                        'tenant_id' => $previousBalance->tenant_id,
                    ],
                );
            }
        }

        $balances = LeaveBalance::with('leaveType')
            ->where('user_id', $userId)
            ->where('year', $year)
            ->get();

        $quotaBalances = collect();

        foreach ($balances as $balance) {
            $name = strtolower((string) ($balance->leaveType?->name ?? ''));
            $key = match (true) {
                str_contains($name, 'tahunan') => 'annual',
                str_contains($name, 'khusus'), str_contains($name, 'penting') => 'special',
                str_contains($name, 'sakit') => 'sick',
                default => null,
            };

            if ($key !== null) $quotaBalances->push($balance);
        }

        $sharedQuota = $quotaBalances->max('quota_days') ?? 0;
        $sharedUsed = $quotaBalances->sum('used_days');
        $remaining = max(0, (int) $sharedQuota - (int) $sharedUsed);
        $result = ['annual' => $remaining, 'special' => $remaining, 'sick' => $remaining];

        return response()->json([
            'year' => $year,
            'balances' => $result,
        ]);
    }

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
            'start_time' => 'nullable|date_format:H:i|required_if:type,Lembur',
            'end_time' => 'nullable|date_format:H:i|required_if:type,Lembur|after:start_time',
            'reason' => 'required|string',
            'attachment' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ], [
            'leave_type_id.exists' => 'Tipe cuti tidak valid. Silakan pilih tipe cuti yang tersedia.',
            'start_date.required' => 'Tanggal mulai harus diisi.',
            'start_date.date' => 'Tanggal mulai harus berupa tanggal yang valid.',
            'end_date.required' => 'Tanggal selesai harus diisi.',
            'end_date.date' => 'Tanggal selesai harus berupa tanggal yang valid.',
            'end_date.after_or_equal' => 'Tanggal selesai harus sama atau setelah tanggal mulai.',
            'reason.required' => 'Alasan cuti harus diisi.',
            'reason.string' => 'Alasan cuti harus berupa teks.',
            'start_time.required_if' => 'Jam mulai lembur harus diisi.',
            'end_time.required_if' => 'Jam selesai lembur harus diisi.',
            'end_time.after' => 'Jam selesai harus setelah jam mulai.',
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

        if ($startDate->format('Y') !== $endDate->format('Y')) {
            return response()->json([
                'message' => 'Pengajuan cuti harus berada dalam tahun yang sama.',
            ], 422);
        }

        $isQuotaLeave = str_starts_with(strtolower($data['type'] ?? ''), 'cuti ');
        $leaveYear = (int) $startDate->format('Y');

        if ($isQuotaLeave) {
            $leaveBalances = LeaveBalance::with('leaveType')
                ->where('user_id', $request->user()->id)
                ->where('year', $leaveYear)
                ->lockForUpdate()
                ->get()
                ->filter(fn ($balance) => in_array(
                    strtolower((string) ($balance->leaveType?->name ?? '')),
                    ['cuti tahunan', 'cuti sakit', 'cuti penting'],
                    true,
                ));

            if ($leaveBalances->isEmpty()) {
                return response()->json([
                    'message' => 'Kuota cuti untuk tahun tersebut belum tersedia.',
                ], 422);
            }

            $remainingDays = max(0, (int) $leaveBalances->max('quota_days') - (int) $leaveBalances->sum('used_days'));
            if ($totalDays > $remainingDays) {
                return response()->json([
                    'message' => "Sisa hari cuti hanya {$remainingDays} hari.",
                ], 422);
            }
        }

        $attachmentPath = $request->hasFile('attachment')
            ? $request->file('attachment')->store('leave-attachments', 'public')
            : null;

        $payload = [
            'user_id' => $request->user()->id,
            'leave_type_id' => $data['leave_type_id'] ?? 1,
            'type' => $data['type'] ?? 'Cuti',
            'start_date' => $data['start_date'],
            'end_date' => $data['end_date'],
            'reason' => $data['reason'],
            'attachment_path' => $attachmentPath,
            'status' => 'pending',
            'total_days' => $totalDays,
        ];

        // Some environments (remote DB) might not have the overtime
        // columns yet. Only include them if the column exists to avoid
        // SQL errors like "Invalid column name 'start_time'".
        try {
            if (\Illuminate\Support\Facades\Schema::hasColumn('leave_requests', 'start_time') &&
                isset($data['start_time'])) {
                $payload['start_time'] = $data['start_time'];
            }

            if (\Illuminate\Support\Facades\Schema::hasColumn('leave_requests', 'end_time') &&
                isset($data['end_time'])) {
                $payload['end_time'] = $data['end_time'];
            }
        } catch (\Throwable $e) {
            // If checking schema fails for any reason, continue without
            // adding overtime columns. This keeps the endpoint resilient
            // while ops team runs migrations.
        }

        $leaveRequest = DB::transaction(function () use ($payload, $isQuotaLeave, $request, $data, $leaveYear, $totalDays) {
            if ($isQuotaLeave) {
                $leaveBalances = LeaveBalance::with('leaveType')
                    ->where('user_id', $request->user()->id)
                    ->where('year', $leaveYear)
                    ->lockForUpdate()
                    ->get()
                    ->filter(fn ($balance) => in_array(
                        strtolower((string) ($balance->leaveType?->name ?? '')),
                        ['cuti tahunan', 'cuti sakit', 'cuti penting'],
                        true,
                    ))
                    ->sortByDesc(fn ($balance) => $balance->leave_type_id === $data['leave_type_id']);

                $remainingDays = max(0, (int) $leaveBalances->max('quota_days') - (int) $leaveBalances->sum('used_days'));
                if ($totalDays > $remainingDays) {
                    abort(422, "Sisa hari cuti hanya {$remainingDays} hari.");
                }

                $daysToAllocate = $totalDays;
                foreach ($leaveBalances as $leaveBalance) {
                    $available = max(0, (int) $leaveBalance->quota_days - (int) $leaveBalance->used_days);
                    $days = min($daysToAllocate, $available);
                    if ($days > 0) {
                        $leaveBalance->increment('used_days', $days);
                        $daysToAllocate -= $days;
                    }
                    if ($daysToAllocate === 0) break;
                }
            }

            return LeaveRequest::create($payload);
        });

        return response()->json($leaveRequest, 201);
    }

    public function destroy(Request $request, $id)
    {
        $leaveRequest = LeaveRequest::where('user_id', $request->user()->id)->findOrFail($id);

        if ($leaveRequest->status !== 'pending') {
            return response()->json([
                'message' => 'Pengajuan yang sudah diproses tidak bisa dibatalkan.',
            ], 422);
        }

        DB::transaction(function () use ($leaveRequest) {
            $isQuotaLeave = str_starts_with(strtolower((string) $leaveRequest->type), 'cuti ');
            if ($isQuotaLeave && $leaveRequest->leave_type_id) {
                $leaveBalance = LeaveBalance::where('user_id', $leaveRequest->user_id)
                    ->where('leave_type_id', $leaveRequest->leave_type_id)
                    ->where('year', $leaveRequest->start_date->year)
                    ->lockForUpdate()
                    ->first();

                if ($leaveBalance) {
                    $leaveBalance->decrement(
                        'used_days',
                        min((int) $leaveRequest->total_days, (int) $leaveBalance->used_days),
                    );
                }
            }

            $leaveRequest->delete();
        });

        return response()->json(['message' => 'Pengajuan berhasil dibatalkan.']);
    }
}