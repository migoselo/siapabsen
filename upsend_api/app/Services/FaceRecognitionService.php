<?php

namespace App\Services;

use App\Models\UserFace;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class FaceRecognitionService
{
    private const MATCH_THRESHOLD = 0.85;

    public function registerFace(int $userId, UploadedFile $photo, ?array $embedding): array
    {
        $embedding = $this->resolveEmbedding($photo, $embedding);
        $path = $photo->storeAs(
            'face-register',
            $this->buildFileName($userId, 'register'),
            'public',
        );

        try {
            $oldPaths = DB::transaction(function () use ($userId, $path, $embedding): array {
                $oldFaces = UserFace::where('user_id', $userId)
                    ->lockForUpdate()
                    ->get();

                UserFace::where('user_id', $userId)->delete();
                UserFace::create([
                    'user_id' => $userId,
                    'image_path' => $path,
                    'embedding' => json_encode($embedding, JSON_THROW_ON_ERROR),
                    'is_active' => true,
                ]);

                return $oldFaces
                    ->pluck('image_path')
                    ->filter()
                    ->all();
            });
        } catch (\Throwable $exception) {
            Storage::disk('public')->delete($path);
            throw $exception;
        }

        foreach ($oldPaths as $oldPath) {
            if ($oldPath !== $path) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        return [
            'success' => true,
            'message' => 'Wajah berhasil didaftarkan.',
            'embedding_count' => count($embedding),
        ];
    }

    public function verifyFace(int $userId, UploadedFile $photo, ?array $embedding): array
    {
        $registeredFace = UserFace::where('user_id', $userId)
            ->where('is_active', true)
            ->latest('id')
            ->first();

        if ($registeredFace === null) {
            return [
                'matched' => false,
                'message' => 'User belum memiliki wajah yang didaftarkan.',
            ];
        }

        $embedding = $this->resolveEmbedding($photo, $embedding);
        $reference = json_decode(
            $registeredFace->embedding,
            true,
            512,
            JSON_THROW_ON_ERROR,
        );

        $bestSimilarity = $this->cosineSimilarity($embedding, $reference);

        $threshold = self::MATCH_THRESHOLD;
        if ($bestSimilarity >= $threshold) {
            return [
                'matched' => true,
                'message' => 'Wajah cocok dengan data yang sudah didaftarkan.',
                'similarity' => round($bestSimilarity, 4),
                'threshold' => $threshold,
            ];
        }

        return [
            'matched' => false,
            'message' => 'Wajah tidak cocok. Silakan coba lagi.',
            'similarity' => round($bestSimilarity, 4),
            'threshold' => $threshold,
        ];
    }

    protected function cosineSimilarity(array $left, array $right): float
    {
        if (count($left) === 0 || count($left) !== count($right)) {
            return 0.0;
        }

        $dot = 0.0;
        $leftNorm = 0.0;
        $rightNorm = 0.0;
        foreach ($left as $index => $value) {
            $leftValue = (float) $value;
            $rightValue = (float) ($right[$index] ?? 0);
            $dot += $leftValue * $rightValue;
            $leftNorm += $leftValue ** 2;
            $rightNorm += $rightValue ** 2;
        }

        $denominator = sqrt($leftNorm) * sqrt($rightNorm);
        return $denominator > 0 ? $dot / $denominator : 0.0;
    }

    protected function resolveEmbedding(UploadedFile $photo, ?array $embedding): array
    {
        if ($embedding !== null && count($embedding) > 0) {
            return array_map(static fn ($value): float => (float) $value, $embedding);
        }

        $generated = $this->extractEncoding($photo->getRealPath());
        if (!in_array(count($generated), [128, 192], true)) {
            throw new \RuntimeException('Embedding wajah tidak valid.');
        }

        return $generated;
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
