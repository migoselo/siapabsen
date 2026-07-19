<?php

namespace App\Helpers;

class DistanceHelper
{
    /**
     * Hitung jarak antara 2 titik koordinat pakai formula Haversine.
     * Return jarak dalam meter (dibulatkan).
     */
    public static function haversine(float $lat1, float $lng1, float $lat2, float $lng2): int
    {
        $earthRadius = 6371000; // meter

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return (int) round($earthRadius * $c);
    }
}
