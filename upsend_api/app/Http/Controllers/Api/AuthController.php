<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'no_hp' => 'required|unique:users,no_hp',
            'password' => 'required|min:6',
            'home_location_id' => 'nullable',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'no_hp' => $request->no_hp,
            'password' => Hash::make($request->password),
            'role' => 'karyawan',
            'home_location_id' => $request->home_location_id,
            'is_active' => true,
        ]);

        return response()->json([
            'message' => 'Registrasi berhasil.',
            'user' => $user,
        ], 201);
    }

    // Login universal — satu endpoint untuk mobile & web.
    // Field 'no_hp' dipakai sebagai identifier umum, isinya bisa:
    // email, nomor HP, atau employee_id. Dicocokkan otomatis.
    // (Nama field tetap 'no_hp' supaya sinkron dengan Flutter
    // yang mengirim AuthLoginRequested(noHp: identifier, ...))
    public function login(Request $request)
    {
        $request->validate([
            'no_hp' => 'required',
            'password' => 'required',
        ]);

        $identifier = trim($request->no_hp);

        $user = User::where('email', $identifier)
            ->orWhere('no_hp', $identifier)
            ->orWhere('employee_id', $identifier)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email/No. HP/ID Karyawan atau password salah.',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Akun sudah dinonaktifkan.'], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user->load('homeLocation'),
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil logout.']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->load('homeLocation'));
    }
}