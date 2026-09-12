<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DatabaseConnectionTest extends TestCase
{
    use RefreshDatabase;

    public function test_users_can_be_persisted_in_postgresql(): void
    {
        $this->assertSame('pgsql', DB::connection()->getDriverName());
        $this->assertSame('event_platform_test', DB::selectOne('select current_database() as name')->name);

        $user = User::factory()->create();

        $this->assertSame($user->email, User::findOrFail($user->id)->email);
    }
}
