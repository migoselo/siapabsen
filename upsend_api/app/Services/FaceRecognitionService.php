<?php

namespace App\Services;

use App\Models\UserFace;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class FaceRecognitionService
{
    public function registerFace(int $userId, UploadedFile $photo): array
    {
        $path = $photo->storeAs('face-register', $this->buildFileName($userId, 'register'), 'public');
        $fullPath = Storage::disk('public')->path($path);

        $encoding = $this->extractEncoding($fullPath);

        UserFace::updateOrCreate(
            ['user_id' => $userId],
            [
                'image_path' => $path,
                'embedding' => json_encode($encoding),
                'is_active' => true,
            ]
        );

        return [
            'success' => true,
            'message' => 'Wajah berhasil didaftarkan.',
            'encoding_count' => count($encoding),
        ];
    }

    public function verifyFace(int $userId, UploadedFile $photo): array
    {
        $registeredFaces = UserFace::where('user_id', $userId)
            ->where('is_active', true)
            ->get();

        if ($registeredFaces->isEmpty()) {
            return [
                'matched' => false,
                'message' => 'User belum memiliki wajah yang didaftarkan.',
            ];
        }

        $path = $photo->storeAs('face-verify', $this->buildFileName($userId, 'verify'), 'public');
        $fullPath = Storage::disk('public')->path($path);

        $candidateEncoding = $this->extractEncoding($fullPath);

        $references = $registeredFaces
            ->map(fn ($face) => json_decode($face->embedding, true, 512, JSON_THROW_ON_ERROR))
            ->all();

        $verification = $this->runPythonVerifier($fullPath, $references);

        if (isset($verification['matched']) && $verification['matched'] === true) {
            return [
                'matched' => true,
                'message' => 'Wajah cocok dengan data yang sudah didaftarkan.',
                'score' => round((1 - (float) ($verification['best_distance'] ?? 0)) * 100, 2),
                'best_distance' => (float) ($verification['best_distance'] ?? 0),
            ];
        }

        return [
            'matched' => false,
            'message' => 'Wajah tidak cocok dengan data yang sudah didaftarkan.',
            'best_distance' => (float) ($verification['best_distance'] ?? 1.0),
        ];
    }

    public function hasRegisteredFace(int $userId): bool
    {
        return UserFace::where('user_id', $userId)
            ->where('is_active', true)
            ->exists();
    }

    protected function extractEncoding(string $imagePath): array
    {
        $result = $this->runPythonWorker('register', $imagePath);

        if (($result['status'] ?? null) !== 'ok') {
            throw new \RuntimeException($result['message'] ?? 'Wajah tidak terdeteksi pada foto yang dikirim.');
        }

        if (empty($result['encoding'])) {
            throw new \RuntimeException('Tidak ada encoding wajah yang berhasil dibuat.');
        }

        return $result['encoding'];
    }

    protected function runPythonVerifier(string $candidatePath, array $references): array
    {
        $scriptPath = base_path('scripts/face_recognition_worker.py');
        $pythonCommand = $this->detectPython();
        $referencesFile = tempnam(sys_get_temp_dir(), 'face_refs_');

        if ($referencesFile === false) {
            throw new \RuntimeException('Gagal membuat file sementara untuk reference wajah.');
        }

        try {
            file_put_contents($referencesFile, json_encode($references, JSON_THROW_ON_ERROR));

            $command = sprintf(
                '%s %s verify %s %s',
                escapeshellarg($pythonCommand[0]),
                escapeshellarg($scriptPath),
                escapeshellarg($candidatePath),
                escapeshellarg($referencesFile)
            );

            $output = shell_exec($command);
            if (!is_string($output) || trim($output) === '') {
                throw new \RuntimeException('Gagal menjalankan verifier face recognition.');
            }

            $decoded = json_decode(trim($output), true);
            if (!is_array($decoded)) {
                throw new \RuntimeException('Output verifier face recognition tidak valid.');
            }

            return $decoded;
        } finally {
            if (is_file($referencesFile)) {
                @unlink($referencesFile);
            }
        }
    }

    protected function runPythonWorker(string $mode, string $imagePath): array
    {
        $scriptPath = base_path('scripts/face_recognition_worker.py');
        $pythonCommand = $this->detectPython();

        $command = sprintf(
            '%s %s %s %s',
            escapeshellarg($pythonCommand[0]),
            escapeshellarg($scriptPath),
            escapeshellarg($mode),
            escapeshellarg($imagePath)
        );

        $output = shell_exec($command);
        if (!is_string($output) || trim($output) === '') {
            throw new \RuntimeException('Gagal menjalankan script face recognition.');
        }

        $decoded = json_decode(trim($output), true);
        if (!is_array($decoded)) {
            throw new \RuntimeException('Output script face recognition tidak valid.');
        }

        return $decoded;
    }

    protected function detectPython(): array
    {
        $candidates = ['python3', 'python', 'py'];

        foreach ($candidates as $candidate) {
            $command = sprintf('%s -c "import sys; print(sys.executable)"', escapeshellarg($candidate));
            $output = shell_exec($command);
            if (is_string($output) && trim($output) !== '') {
                return [$candidate, trim($output)];
            }
        }

        throw new \RuntimeException('Python runtime tidak ditemukan. Instal Python dan library: pip install face-recognition opencv-python');
    }

    protected function buildFileName(int $userId, string $type): string
    {
        return sprintf('user_%d_%s_%s.jpg', $userId, $type, now()->format('YmdHis_u'));
    }
}
