<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('tebengans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('requester_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('runner_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('pickup_location');
            $table->string('destination');
            $table->dateTime('departure_time');
            $table->decimal('budget', 12, 2);
            $table->decimal('fee', 10, 2)->default(0);
            $table->string('whatsapp_number');
            $table->enum('status', ['open', 'taken', 'on_progress', 'done', 'cancelled'])
                ->default('open');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tebengans');
    }
};