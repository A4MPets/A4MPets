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
        Schema::create('hazard_reports', function (Blueprint $table) {
            $table->id();
            
            // Ubicación del peligro
            $table->decimal('incident_latitude', 10, 8);
            $table->decimal('incident_longitude', 11, 8);
            
            // Características del peligro
            $table->decimal('impact_radius_meters', 8, 2);
            $table->string('risk_level_code')->default('undefined');
            $table->string('category_code')->default('undefined');
            $table->string('estimated_duration_code')->default('undefined');
            $table->string('description')->nullable();
            $table->string('narrative_description')->nullable();
            $table->timestamp('reported_at')->nullable();
            $table->string('evidence_photo_url')->nullable();
            $table->string('reported_by_username')->default('Anónimo');
            
            // Relación con usuario (nullable para cuando no hay login)
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
            
            // Estado y sincronización
            $table->enum('status', ['created', 'synced', 'archived'])->default('created');
            
            // IDs para sincronización
            // local_id: identificador único local generado en el cliente
            $table->string('local_id')->unique()->nullable()->comment('ID generado localmente en el cliente');
            // remote_id: identificador único global en el servidor
            $table->string('remote_id')->unique()->nullable()->comment('ID del servidor global');
            
            // Timestamps de sincronización
            $table->timestamp('last_modified_at')->useCurrent()->comment('Última modificación local');
            $table->timestamp('synced_at')->nullable()->comment('Última sincronización exitosa');
            
            // Timestamps estándar
            $table->timestamps();
            
            // Índices para queries rápidas
            $table->index(['status', 'synced_at']);
            $table->index(['user_id']);
            $table->index(['incident_latitude', 'incident_longitude']);
            $table->index('local_id');
            $table->index('remote_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('hazard_reports');
    }
};
