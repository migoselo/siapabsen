<?php

namespace App\Services;

use Illuminate\Support\Facades\Mail;

class EmailDeliveryService
{
    public function send(string $to, string $subject, string $text): void
    {
        Mail::raw($text, function ($message) use ($to, $subject) {
            $message->to($to)->subject($subject);
        });
    }
}
