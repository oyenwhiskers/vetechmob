<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pet extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'name',
        'species',
        'breed',
        'age',
        'gender',
        'color',
        'weight',
        'microchip_number',
        'medical_notes',
        'pet_image',
        'special_notes',
    ];

    protected $casts = [
        'age' => 'integer',
        'weight' => 'decimal:2',
    ];

    /**
     * Get the customer that owns the pet.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * Get the treatments for the pet.
     */
    public function treatments(): HasMany
    {
        return $this->hasMany(Treatment::class);
    }

    /**
     * Get the bookings for the pet.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /**
     * Get the tag associated with the pet.
     */
    public function tag(): HasOne
    {
        return $this->hasOne(Tag::class);
    }
}
