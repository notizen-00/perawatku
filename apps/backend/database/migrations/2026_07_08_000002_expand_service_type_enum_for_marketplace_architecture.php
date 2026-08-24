<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $this->alterServiceTypeEnum([
            'consultation',
            'procedure',
            'caregiver',
            'homecare',
            'dokter_homecare',
            'perawat_homecare',
            'bidan_homecare',
            'konsultasi_tindakan',
        ]);
    }

    public function down(): void
    {
        $this->alterServiceTypeEnum([
            'dokter_homecare',
            'perawat_homecare',
            'bidan_homecare',
            'konsultasi_tindakan',
        ]);
    }

    private function alterServiceTypeEnum(array $values): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'sqlite') {
            return;
        }

        $list = collect($values)->map(fn ($value) => "'".addslashes($value)."'")->implode(', ');

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE services DROP CONSTRAINT IF EXISTS services_service_type_check');
            DB::statement("ALTER TABLE services ADD CONSTRAINT services_service_type_check CHECK (service_type IN ({$list}))");

            return;
        }

        DB::statement("ALTER TABLE services MODIFY service_type ENUM({$list}) NOT NULL");
    }
};
