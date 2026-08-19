<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FaceRecognitionService;
use Illuminate\Http\Request;

class FaceRecognitionController extends Controller
{
    public function __construct(
        protected FaceRecognitionService $faceRecognitionService,
    ) {}

    public function register(Request $request)
    {
        $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
            'embedding' => [
                'required',
                'array',
                function (string $attribute, mixed $value, \Closure $fail): void {
                    if (is_array($value) && !in_array(count($value), [128, 192], true)) {
                        $fail('Embedding harus berisi 128 atau 192 nilai.');
                    }
                },
            ],
            'embedding.*' => ['numeric'],
        ]);

        try {
            $result = $this->faceRecognitionService->registerFace(
                $request->user()->id,
                $request->file('photo'),
                $request->input('embedding'),
            );

            return response()->json($result, 200);
        } catch (\Throwable $th) {
            return response()->json([
                'success' => false,
                'message' => $th->getMessage(),
            ], 422);
        }
    }

    public function verify(Request $request)
    {
        $request->validate([
            'photo' => ['required', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
            'embedding' => [
                'required',
                'array',
                function (string $attribute, mixed $value, \Closure $fail): void {
                    if (is_array($value) && !in_array(count($value), [128, 192], true)) {
                        $fail('Embedding harus berisi 128 atau 192 nilai.');
                    }
                },
            ],
            'embedding.*' => ['numeric'],
        ]);

        try {
            $result = $this->faceRecognitionService->verifyFace(
                $request->user()->id,
                $request->file('photo'),
                $request->input('embedding'),
            );

            if (($result['matched'] ?? false) === true) {
                return response()->json($result, 200);
            }

            return response()->json($result, 403);
        } catch (\Throwable $th) {
            return response()->json([
                'matched' => false,
                'message' => $th->getMessage(),
            ], 422);
        }
    }

    public function status(Request $request)
    {
        return response()->json([
            'registered' => $this->faceRecognitionService->hasRegisteredFace($request->user()->id),
        ]);
    }
}
