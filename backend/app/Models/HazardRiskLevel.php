<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HazardRiskLevel extends Model
{
    protected $fillable = [
        'code',
        'label',
        'sort_order',
    ];

    public static function idByCode(string $code): ?int
    {
        static $cache = [];

        if (!array_key_exists($code, $cache)) {
            $cache[$code] = self::query()->where('code', $code)->value('id');
        }

        if ($cache[$code] !== null) {
            return (int) $cache[$code];
        }

        if ($code !== 'undefined') {
            return self::idByCode('undefined');
        }

        return null;
    }
}
