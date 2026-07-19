<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Location;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function index()
    {
        return response()->json(Location::orderBy('name')->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_meter' => 'nullable|integer|min:1',
        ]);

        $location = Location::create($data);

        return response()->json($location, 201);
    }

    public function show(Location $location)
    {
        return response()->json($location);
    }

    public function update(Request $request, Location $location)
    {
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'latitude' => 'sometimes|required|numeric|between:-90,90',
            'longitude' => 'sometimes|required|numeric|between:-180,180',
            'radius_meter' => 'sometimes|nullable|integer|min:1',
        ]);

        $location->update($data);

        return response()->json($location);
    }

    public function destroy(Location $location)
    {
        $location->delete();

        return response()->json(['message' => 'Lokasi berhasil dihapus.']);
    }
}
