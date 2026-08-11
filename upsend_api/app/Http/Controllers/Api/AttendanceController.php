<?php

namespace App\Http\Controllers\Api;

use App\Helpers\DistanceHelper;
use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Location;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function nearbyLocations(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $locations = Location::all()->map(function ($loc) use ($request) {
            $distance = DistanceHelper::haversine(
                $request->lat, $request->lng, $loc->latitude, $loc->longitude
            );

            return [
                'id' => $loc->id,
                'name' => $loc->name,
                'distance' => $distance,
                'radius_meter' => $loc->radius_meter,
                'within_radius' => $distance <= $loc->radius_meter,
            ];
        })->sortBy('distance')->values();

        return response()->json($locations);
    }

   public function checkIn(Request $request)
{
    $data = $request->validate([
        'location_id' => 'required|exists:locations,id',
        'lat' => 'required|numeric|between:-90,90',
        'lng' => 'required|numeric|between:-180,180',
        'photo' => 'required|image|max:5120',
    ]);

    $employeeId = $request->user()->id;

    $openSession = Attendance::where('employee_id', $employeeId)
        ->whereNull('check_out_time')
        ->exists();

    if ($openSession) {
        return response()->json([
            'message' => 'Masih ada sesi check-in yang belum check-out. Check-out dulu sebelum absen baru.',
        ], 422);
    }

    $location = Location::findOrFail($data['location_id']);

    $distance = DistanceHelper::haversine(
        $data['lat'], $data['lng'], $location->latitude, $location->longitude
    );

    // TEGAS: tolak kalau di luar radius
    if ($distance > $location->radius_meter) {
        return response()->json([
            'message' => "Anda berada di luar radius absen (jarak: " . round($distance) . "m, maksimal: {$location->radius_meter}m).",
        ], 422);
    }

    $photoPath = $request->file('photo')->store('attendance-photos', 'public');

    $attendance = Attendance::create([
        'employee_id' => $employeeId,
        'user_id' => $employeeId,
        'location_id' => $location->id,
        'check_in_time' => now(),
        'check_in_lat' => $data['lat'],
        'check_in_long' => $data['lng'],
        'check_in_distance' => $distance,
        'check_in_photo' => $photoPath,
        'status' => 'approved',
    ]);

    return response()->json($attendance->load('location'), 201);
}

    public function checkOut(Request $request, Attendance $attendance)
{
    if ((int) $attendance->employee_id !== (int) $request->user()->id) {
        return response()->json(['message' => 'Bukan sesi absen kamu.'], 403);
    }
        if ($attendance->check_out_time) {
            return response()->json(['message' => 'Sesi ini sudah check-out.'], 422);
        }

        $data = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $location = $attendance->location;

        $distance = DistanceHelper::haversine(
            $data['lat'], $data['lng'], $location->latitude, $location->longitude
        );

        $attendance->update([
            'check_out_time' => now(),
            'check_out_lat' => $data['lat'],
            'check_out_long' => $data['lng'],
            'check_out_distance' => $distance,
        ]);

        return response()->json($attendance->fresh()->load('location'));
    }

    public function myOpenSession(Request $request)
    {
        $session = Attendance::where('employee_id', $request->user()->id)
            ->whereNull('check_out_time')
            ->with('location')
            ->latest('check_in_time')
            ->first();

        return response()->json(['open_session' => $session]);
    }

    public function myHistory(Request $request)
    {
        // employee_id selalu dari user yang login, bukan dari input request
        $query = Attendance::where('employee_id', $request->user()->id)->with('location');

        if ($request->filled('start_date')) {
            $query->whereDate('check_in_time', '>=', $request->start_date);
        }

        if ($request->filled('end_date')) {
            $query->whereDate('check_in_time', '<=', $request->end_date);
        }

        return response()->json($query->orderByDesc('check_in_time')->paginate(20));
    }
}
