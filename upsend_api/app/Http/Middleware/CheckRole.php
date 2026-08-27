<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        if (! $request->user() || ! in_array($request->user()->role, $roles, true)) {
            return response()->json([
                'message' => 'Forbidden. Role tidak memiliki akses.',
            ], 403);
        }

        return $next($request);
    }
}
