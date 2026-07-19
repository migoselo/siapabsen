<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::with('homeLocation');

        if ($request->filled('location_id')) {
            $query->where('home_location_id', $request->location_id);
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        return response()->json($query->orderBy('name')->paginate(20));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'no_hp' => 'nullable|string|max:255',
            'role' => 'required|in:admin,karyawan',
            'home_location_id' => 'required|exists:locations,id',
        ]);

        $data['password'] = Hash::make($data['password']);

        $user = User::create($data);

        return response()->json($user->load('homeLocation'), 201);
    }

    public function show(User $user)
    {
        return response()->json($user->load('homeLocation'));
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,' . $user->id,
            'no_hp' => 'nullable|string|max:255',
            'role' => 'sometimes|required|in:admin,karyawan',
            'is_active' => 'sometimes|boolean',
        ]);

        $user->update($data);

        return response()->json($user->load('homeLocation'));
    }

    public function transfer(Request $request, User $user)
    {
        $data = $request->validate([
            'home_location_id' => 'required|exists:locations,id',
        ]);

        $user->update(['home_location_id' => $data['home_location_id']]);

        return response()->json($user->load('homeLocation'));
    }

    public function destroy(User $user)
    {
        // Soft-nonaktifkan, bukan hard delete, biar histori attendance tetap utuh
        $user->update(['is_active' => false]);

        return response()->json(['message' => 'Karyawan berhasil dinonaktifkan.']);
    }
}
