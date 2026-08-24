<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'sqlite') {
            return;
        }

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('pasien', 'dokter', 'apotik', 'kurir', 'admin', 'mitra'))");
            DB::statement("ALTER TABLE users ALTER COLUMN role SET DEFAULT 'pasien'");

            return;
        }

        DB::statement("ALTER TABLE users
            MODIFY role ENUM('pasien','dokter','apotik','kurir','admin','mitra')
            DEFAULT 'pasien'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
