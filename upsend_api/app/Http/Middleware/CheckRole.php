<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckRole
{
    public function handle(Request $request, Closure $next, string $role)
    {
        if (! $request->user() || $request->user()->role !== $role) {
            return response()->json([
                'message' => 'Forbidden. Akses ini khusus untuk role ' . $role . '.',
            ], 403);
        }

        return $next($request);
    }
}
