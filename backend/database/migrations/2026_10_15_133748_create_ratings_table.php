<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rater_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('ratee_id')->constrained('users')->onDelete('cascade');
            $table->string('rateable_type'); // 'App\Models\Jastip' atau nanti 'App\Models\Tebengan'
            $table->unsignedBigInteger('rateable_id');
            $table->tinyInteger('stars'); // 1-5
            $table->text('review')->nullable();
            $table->string('role'); // 'driver' atau 'requester'
            $table->timestamps();

            $table->index(['rateable_type', 'rateable_id']);
            $table->unique(['rater_id', 'rateable_type', 'rateable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ratings');
    }
};