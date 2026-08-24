<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('service_booking_histories', function (Blueprint $table) {
            if (! Schema::hasColumn('service_booking_histories', 'treatment_type')) {
                $table->string('treatment_type')->nullable()->after('type');
            }

            if (! Schema::hasColumn('service_booking_histories', 'photo_path')) {
                $table->string('photo_path')->nullable()->after('meta');
            }

            if (! Schema::hasColumn('service_booking_histories', 'checklist')) {
                $table->json('checklist')->nullable()->after('photo_path');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('service_booking_histories', function (Blueprint $table) {
            if (Schema::hasColumn('service_booking_histories', 'checklist')) {
                $table->dropColumn('checklist');
            }

            if (Schema::hasColumn('service_booking_histories', 'photo_path')) {
                $table->dropColumn('photo_path');
            }

            if (Schema::hasColumn('service_booking_histories', 'treatment_type')) {
                $table->dropColumn('treatment_type');
            }
        });
    }
};
