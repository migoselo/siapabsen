<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\App as LaravelApp;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Always bind a default currentTenant value so app('currentTenant') does not
        // throw when no tenant has been resolved for the request.
        if (! $this->app->bound('currentTenant')) {
            $this->app->instance('currentTenant', null);
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register middleware alias for tenant resolver used in routes/middleware
        try {
            $router = $this->app['router'] ?? null;
            if ($router) {
                $router->aliasMiddleware('currentTenant', \App\Http\Middleware\SetTenant::class);
            }
        } catch (\Throwable $e) {
            // ignore if router not available in this context
        }
    }
}
