<?php

namespace App\Logging;

use Monolog\LogRecord;
use Monolog\Processor\ProcessorInterface;

class PasswordLogMasker implements ProcessorInterface
{
    private const MASK = '*****';

    private const PROTECTED_KEYS = [
        'password',
        'password_confirmation',
        'old_password',
        'new_password',
        'new_password_confirmation',
        'token',
        'access_token',
        'refresh_token',
        'api_key',
        'secret',
        'authorization',
    ];

    public function __invoke(LogRecord $record): LogRecord
    {
        return $record->with(
            context: $this->mask($record->context),
            extra: $this->mask($record->extra),
        );
    }

    private function mask(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        $masked = [];

        foreach ($value as $key => $item) {
            $normalizedKey = strtolower((string) $key);
            $masked[$key] = in_array($normalizedKey, self::PROTECTED_KEYS, true)
                ? self::MASK
                : $this->mask($item);
        }

        return $masked;
    }
}
