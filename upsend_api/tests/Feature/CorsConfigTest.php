<?php

namespace Tests\Feature;

use Tests\TestCase;

class CorsConfigTest extends TestCase
{
    public function test_storage_routes_are_allowed_for_cross_origin_requests(): void
    {
        $paths = config('cors.paths');

        $this->assertContains('storage/*', $paths);
    }
}
