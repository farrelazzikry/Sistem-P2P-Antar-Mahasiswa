<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone')->nullable()->after('nim');
            $table->string('profile_photo')->nullable()->after('phone');
            $table->boolean('is_runner')->default(false)->after('profile_photo');
            $table->string('vehicle_type')->nullable()->after('is_runner');
            $table->string('vehicle_plate')->nullable()->after('vehicle_type');
            $table->decimal('rating_as_driver', 3, 2)->default(0)->after('vehicle_plate');
            $table->decimal('rating_as_requester', 3, 2)->default(0)->after('rating_as_driver');
            $table->integer('total_trips')->default(0)->after('rating_as_requester');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'phone', 'profile_photo', 'is_runner',
                'vehicle_type', 'vehicle_plate',
                'rating_as_driver', 'rating_as_requester', 'total_trips',
            ]);
        });
    }
};