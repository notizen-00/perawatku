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
        $this->alterTypeEnum(['obat', 'produk_kesehatan', 'layanan', 'sewa_alat_kesehatan']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $this->alterTypeEnum(['obat', 'produk_kesehatan']);
    }

    private function alterTypeEnum(array $values): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'sqlite') {
            return;
        }

        $list = collect($values)->map(fn ($value) => "'".addslashes($value)."'")->implode(', ');

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE products DROP CONSTRAINT IF EXISTS products_type_check');
            DB::statement("ALTER TABLE products ADD CONSTRAINT products_type_check CHECK (type IN ({$list}))");

            return;
        }

        DB::statement("ALTER TABLE products MODIFY type ENUM({$list}) NOT NULL");
    }
};
