<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('jastips', function (Blueprint $table) {
            $table->boolean('reminder_sent')->default(false)->after('status');
        });
        Schema::table('tebengans', function (Blueprint $table) {
            $table->boolean('reminder_sent')->default(false)->after('status');
        });
    }
    public function down(): void
    {
        Schema::table('jastips', function (Blueprint $table) {
            $table->dropColumn('reminder_sent'); });
        Schema::table('tebengans', function (Blueprint $table) {
            $table->dropColumn('reminder_sent'); });
    }
};
