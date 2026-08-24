<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'service_booking_id',
    'actor_user_id',
    'type',
    'treatment_type',
    'title',
    'description',
    'meta',
    'photo_path',
    'checklist',
    'handled_at',
])]
class ServiceBookingHistory extends Model
{
    protected $appends = ['photo_url'];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
            'checklist' => 'array',
            'handled_at' => 'datetime',
        ];
    }

    public function serviceBooking(): BelongsTo
    {
        return $this->belongsTo(ServiceBooking::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    public function getPhotoUrlAttribute(): ?string
    {
        if (! $this->photo_path) {
            return null;
        }

        if (str_starts_with($this->photo_path, 'http://') || str_starts_with($this->photo_path, 'https://')) {
            return $this->photo_path;
        }

        return asset('storage/'.ltrim($this->photo_path, '/'));
    }
}
