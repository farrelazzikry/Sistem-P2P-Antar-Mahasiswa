<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('jastips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('requester_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('runner_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('item_name');
            $table->text('item_description')->nullable();
            $table->string('buy_location');
            $table->string('delivery_location');
            $table->decimal('budget', 12, 2);
            $table->decimal('fee', 10, 2)->default(0);
            $table->string('whatsapp_number');
            $table->enum('status', ['open', 'taken', 'on_progress', 'done', 'cancelled'])
                ->default('open');
            $table->string('proof_photo')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jastips');
    }
};