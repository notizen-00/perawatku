<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('products') && ! Schema::hasColumn('products', 'pharmacy_id')) {
            Schema::table('products', function (Blueprint $table) {
                $table->foreignId('pharmacy_id')->nullable()->after('id')->constrained('pharmacies')->nullOnDelete();
            });
        }

        if (Schema::hasTable('orders') && ! Schema::hasColumn('orders', 'pharmacy_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->foreignId('pharmacy_id')->nullable()->after('patient_user_id')->constrained('pharmacies')->nullOnDelete();
            });
        }

        if (Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_user_id') && Schema::hasColumn('products', 'pharmacy_id')) {
            $this->backfillByOwner('products', 'pharmacy_user_id', 'pharmacy_id');
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_user_id') && Schema::hasColumn('orders', 'pharmacy_id')) {
            $this->backfillByOwner('orders', 'pharmacy_user_id', 'pharmacy_id');
        }

        if (Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_id')) {
            if (! $this->hasIndex('products', 'products_pharmacy_id_is_active_index')) {
                Schema::table('products', function (Blueprint $table) {
                    $table->index(['pharmacy_id', 'is_active'], 'products_pharmacy_id_is_active_index');
                });
            }

            if (! $this->hasIndex('products', 'products_pharmacy_id_sku_unique')) {
                Schema::table('products', function (Blueprint $table) {
                    $table->unique(['pharmacy_id', 'sku'], 'products_pharmacy_id_sku_unique');
                });
            }
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_id')) {
            if (! $this->hasIndex('orders', 'orders_pharmacy_id_status_index')) {
                Schema::table('orders', function (Blueprint $table) {
                    $table->index(['pharmacy_id', 'status'], 'orders_pharmacy_id_status_index');
                });
            }
        }

        if (! $this->isSqlite() && Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_user_id')) {
            $this->dropForeignKeyByColumn('products', 'pharmacy_user_id');
            $this->dropIndexIfExists('products', 'products_pharmacy_user_id_is_active_index');
            $this->dropUniqueIfExists('products', 'products_pharmacy_user_id_sku_unique');

            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('pharmacy_user_id');
            });
        }

        if (! $this->isSqlite() && Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_user_id')) {
            $this->dropForeignKeyByColumn('orders', 'pharmacy_user_id');
            $this->dropIndexIfExists('orders', 'orders_pharmacy_user_id_status_index');

            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('pharmacy_user_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('products') && ! Schema::hasColumn('products', 'pharmacy_user_id')) {
            Schema::table('products', function (Blueprint $table) {
                $table->foreignId('pharmacy_user_id')->nullable()->after('id')->constrained('users')->nullOnDelete();
            });
        }

        if (Schema::hasTable('orders') && ! Schema::hasColumn('orders', 'pharmacy_user_id')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->foreignId('pharmacy_user_id')->nullable()->after('patient_user_id')->constrained('users')->nullOnDelete();
            });
        }

        if (Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_id') && Schema::hasColumn('products', 'pharmacy_user_id')) {
            $this->backfillByPharmacy('products', 'pharmacy_id', 'pharmacy_user_id');
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_id') && Schema::hasColumn('orders', 'pharmacy_user_id')) {
            $this->backfillByPharmacy('orders', 'pharmacy_id', 'pharmacy_user_id');
        }

        if (Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_user_id')) {
            if (! $this->hasIndex('products', 'products_pharmacy_user_id_is_active_index')) {
                Schema::table('products', function (Blueprint $table) {
                    $table->index(['pharmacy_user_id', 'is_active'], 'products_pharmacy_user_id_is_active_index');
                });
            }

            if (! $this->hasIndex('products', 'products_pharmacy_user_id_sku_unique')) {
                Schema::table('products', function (Blueprint $table) {
                    $table->unique(['pharmacy_user_id', 'sku'], 'products_pharmacy_user_id_sku_unique');
                });
            }
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_user_id')) {
            if (! $this->hasIndex('orders', 'orders_pharmacy_user_id_status_index')) {
                Schema::table('orders', function (Blueprint $table) {
                    $table->index(['pharmacy_user_id', 'status'], 'orders_pharmacy_user_id_status_index');
                });
            }
        }

        if (Schema::hasTable('products') && Schema::hasColumn('products', 'pharmacy_id')) {
            $this->dropForeignKeyByColumn('products', 'pharmacy_id');
            $this->dropUniqueIfExists('products', 'products_pharmacy_id_sku_unique');
            $this->dropIndexIfExists('products', 'products_pharmacy_id_is_active_index');

            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('pharmacy_id');
            });
        }

        if (Schema::hasTable('orders') && Schema::hasColumn('orders', 'pharmacy_id')) {
            $this->dropForeignKeyByColumn('orders', 'pharmacy_id');
            $this->dropIndexIfExists('orders', 'orders_pharmacy_id_status_index');

            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('pharmacy_id');
            });
        }
    }

    private function hasIndex(string $table, string $indexName): bool
    {
        return Schema::hasIndex($table, $indexName);
    }

    private function dropIndexIfExists(string $table, string $indexName): void
    {
        if ($this->hasIndex($table, $indexName)) {
            Schema::table($table, function (Blueprint $table) use ($indexName) {
                $table->dropIndex($indexName);
            });
        }
    }

    /**
     * Unlike dropIndexIfExists(), this drops an index that backs a UNIQUE
     * constraint. On Postgres, DROP INDEX fails for those with "Dependent
     * objects still exist" -- the constraint must be dropped instead, which
     * is what Blueprint::dropUnique() does (ALTER TABLE ... DROP CONSTRAINT).
     */
    private function dropUniqueIfExists(string $table, string $indexName): void
    {
        if ($this->hasIndex($table, $indexName)) {
            Schema::table($table, function (Blueprint $table) use ($indexName) {
                $table->dropUnique($indexName);
            });
        }
    }

    private function dropForeignKeyByColumn(string $table, string $column): void
    {
        if ($this->isSqlite()) {
            return;
        }

        // Schema::getForeignKeys() is driver-agnostic (MySQL/Postgres/SQL
        // Server), unlike querying information_schema directly -- MySQL and
        // Postgres don't expose the same columns there.
        $foreignKey = collect(Schema::getForeignKeys($table))
            ->first(fn (array $fk) => in_array($column, $fk['columns'], true));

        if ($foreignKey) {
            Schema::table($table, function (Blueprint $blueprint) use ($foreignKey) {
                $blueprint->dropForeign($foreignKey['name']);
            });
        }
    }

    private function backfillByOwner(string $table, string $ownerColumn, string $pharmacyIdColumn): void
    {
        if ($this->isSqlite()) {
            return;
        }

        if ($this->isPgsql()) {
            DB::statement("
                UPDATE {$table} t
                SET {$pharmacyIdColumn} = ph.id
                FROM pharmacies ph
                WHERE ph.owner_user_id = t.{$ownerColumn}
                AND t.{$pharmacyIdColumn} IS NULL
            ");

            return;
        }

        DB::statement("
            UPDATE {$table} t
            INNER JOIN pharmacies ph ON ph.owner_user_id = t.{$ownerColumn}
            SET t.{$pharmacyIdColumn} = ph.id
            WHERE t.{$pharmacyIdColumn} IS NULL
        ");
    }

    private function backfillByPharmacy(string $table, string $pharmacyIdColumn, string $ownerColumn): void
    {
        if ($this->isSqlite()) {
            return;
        }

        if ($this->isPgsql()) {
            DB::statement("
                UPDATE {$table} t
                SET {$ownerColumn} = ph.owner_user_id
                FROM pharmacies ph
                WHERE ph.id = t.{$pharmacyIdColumn}
                AND t.{$ownerColumn} IS NULL
            ");

            return;
        }

        DB::statement("
            UPDATE {$table} t
            INNER JOIN pharmacies ph ON ph.id = t.{$pharmacyIdColumn}
            SET t.{$ownerColumn} = ph.owner_user_id
            WHERE t.{$ownerColumn} IS NULL
        ");
    }

    private function isSqlite(): bool
    {
        return DB::connection()->getDriverName() === 'sqlite';
    }

    private function isPgsql(): bool
    {
        return DB::connection()->getDriverName() === 'pgsql';
    }
};
