# Server 500 Errors - Debugging Guide

## Current Issues

### 1. GET /pets endpoint → 500 Internal Server Error
```
GET http://inovetsmart.com/api/v1/pets
Status: 500
Response: {message: Server Error}
```

### 2. GET /dashboard endpoint → Connection Timeout
```
GET http://inovetsmart.com/api/v1/dashboard
Timeout after 20 seconds
```

---

## Root Cause: Backend Server Issues

Both errors indicate **server-side problems**. The mobile app is sending correct requests, but the Laravel backend is failing.

### Why 500 Errors Occur

**500 Internal Server Error** means:
- PHP/Laravel code has an unhandled exception
- Database query is failing
- Missing or incorrectly configured resources
- Server is overloaded or misconfigured

---

## Immediate Server Checks Required

### 1. Check Laravel Error Logs

```bash
# SSH into your server
ssh user@inovetsmart.com

# View latest Laravel errors
tail -100 storage/logs/laravel.log

# Or watch logs in real-time
tail -f storage/logs/laravel.log
```

**Look for:**
- SQL errors (foreign key constraints, missing tables)
- Authentication errors (token validation issues)
- Missing relationships (e.g., pets trying to load customer that doesn't exist)

### 2. Test Endpoints with cURL

```bash
# First, get a valid token by logging in
curl -X POST http://inovetsmart.com/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'

# Copy the token from response, then test pets endpoint
curl -X GET http://inovetsmart.com/api/v1/pets \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"

# Test dashboard endpoint
curl -X GET http://inovetsmart.com/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json"
```

### 3. Enable Debug Mode (Temporarily)

Edit `.env` on server:
```env
APP_DEBUG=true
APP_ENV=local
```

**⚠️ IMPORTANT:** This will show detailed error messages in API responses. Test the endpoints again and you'll see the exact error. **Turn it back off after debugging:**
```env
APP_DEBUG=false
APP_ENV=production
```

---

## Common Causes & Fixes

### Issue 1: Database Table or Column Missing

**Error:** `SQLSTATE[42S02]: Base table or view not found`

**Fix:**
```bash
php artisan migrate
php artisan migrate:status
```

### Issue 2: Foreign Key Constraint Errors

**Error:** `SQLSTATE[23000]: Integrity constraint violation`

**Common scenario:** Pets table references `customer_id` but customer doesn't exist

**Fix:** Verify data integrity:
```sql
-- Check if pets table has proper foreign keys
SELECT * FROM pets WHERE customer_id NOT IN (SELECT id FROM customers);

-- Fix orphaned records
DELETE FROM pets WHERE customer_id NOT IN (SELECT id FROM customers);
```

### Issue 3: Authentication Token Issues

**Error:** `Unauthenticated` or token-related errors

**Fix:**
```bash
php artisan config:clear
php artisan cache:clear
php artisan config:cache
```

### Issue 4: Pets Controller Has Bugs

**Check your `PetsController.php`:**

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Pet;
use Illuminate\Http\Request;

class PetsController extends Controller
{
    public function index(Request $request)
    {
        try {
            // Get authenticated user's customer ID
            $user = $request->user();
            
            if (!$user || !$user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer not found'
                ], 404);
            }
            
            // Get pets for this customer
            $pets = Pet::where('customer_id', $user->customer_id)
                ->with('tag') // Eager load tag relationship
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => $pets
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('Pets fetch error: ' . $e->getMessage());
            \Log::error($e->getTraceAsString());
            
            return response()->json([
                'success' => false,
                'message' => 'Server error',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
```

### Issue 5: Missing Relationships in Models

**Check `Pet.php` model:**

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pet extends Model
{
    protected $fillable = [
        'customer_id',
        'name',
        'species',
        'breed',
        'age',
        'gender',
        'color',
        'weight',
        'microchip_id',
        'medical_notes',
    ];

    // Relationship to customer
    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    // Relationship to tag
    public function tag()
    {
        return $this->hasOne(PetTag::class, 'pet_id');
    }

    // Make sure to hide timestamps if not needed
    protected $hidden = [];
    
    // Cast attributes
    protected $casts = [
        'age' => 'integer',
        'weight' => 'float',
    ];
}
```

### Issue 6: Dashboard Timeout

**Possible causes:**
- Complex queries taking too long
- Missing database indexes
- Server overloaded

**Check `DashboardController.php`:**

```php
public function index(Request $request)
{
    try {
        $user = $request->user();
        $customerId = $user->customer_id;
        
        // Use query optimization
        $stats = [
            'total_pets' => Pet::where('customer_id', $customerId)->count(),
            'total_bookings' => Booking::where('customer_id', $customerId)->count(),
            'upcoming_bookings' => Booking::where('customer_id', $customerId)
                ->where('status', 'upcoming')
                ->count(),
            'total_treatments' => Treatment::whereHas('pet', function($q) use ($customerId) {
                $q->where('customer_id', $customerId);
            })->count(),
        ];
        
        // Use limits to avoid huge queries
        $nextBooking = Booking::where('customer_id', $customerId)
            ->where('status', 'upcoming')
            ->orderBy('booking_date')
            ->orderBy('booking_time')
            ->with('pet')
            ->first();
            
        $recentBookings = Booking::where('customer_id', $customerId)
            ->orderBy('created_at', 'desc')
            ->with('pet')
            ->limit(5) // Limit results
            ->get();
            
        $pets = Pet::where('customer_id', $customerId)
            ->with('tag')
            ->limit(10) // Limit results
            ->get();
        
        return response()->json([
            'success' => true,
            'data' => [
                'statistics' => $stats,
                'next_booking' => $nextBooking,
                'recent_bookings' => $recentBookings,
                'pets' => $pets,
            ]
        ], 200);
        
    } catch (\Exception $e) {
        \Log::error('Dashboard error: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'Server error'
        ], 500);
    }
}
```

---

## Quick Server Fixes to Try

### 1. Clear all caches
```bash
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
php artisan config:cache
```

### 2. Check database connection
```bash
php artisan tinker
>>> DB::connection()->getPdo();
>>> \App\Models\Pet::count();
```

### 3. Check if routes are registered
```bash
php artisan route:list | grep pets
php artisan route:list | grep dashboard
```

### 4. Verify middleware is applied
Check `routes/api.php`:
```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::get('/pets', [PetsController::class, 'index']);
    Route::get('/dashboard', [DashboardController::class, 'index']);
    // ... other routes
});
```

### 5. Check server resources
```bash
# Check disk space
df -h

# Check PHP memory limit
php -i | grep memory_limit

# Check PHP max execution time
php -i | grep max_execution_time
```

---

## Testing Locally (If Possible)

If you have local server access:

```bash
# Start Laravel local server
php artisan serve

# In another terminal, test with local URL
curl -X GET http://127.0.0.1:8000/api/v1/pets \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

Update `lib/core/constants.dart` to point to local:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
// Or for Android emulator:
// static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

---

## What to Check in Laravel Logs

Look for these patterns:

### SQL Errors
```
SQLSTATE[42S02]: Base table or view not found
SQLSTATE[42S22]: Column not found
SQLSTATE[23000]: Integrity constraint violation
```

### PHP Errors
```
Call to undefined method
Trying to get property of non-object
Class not found
```

### Laravel Specific
```
Too few arguments to function
Method does not exist
Undefined variable
```

---

## After Fixing Server Issues

1. **Turn debug mode OFF**:
   ```env
   APP_DEBUG=false
   APP_ENV=production
   ```

2. **Clear caches**:
   ```bash
   php artisan config:cache
   php artisan route:cache
   ```

3. **Test from mobile app**:
   - The app will now work correctly once server is fixed
   - Check console logs in Flutter for success messages

---

## Mobile App Is Working Correctly

The Flutter app is:
- ✅ Sending correct authentication headers
- ✅ Using proper endpoints
- ✅ Handling errors gracefully
- ✅ Showing clear error messages

The problem is **100% on the server side**. Once you fix the Laravel backend issues, the app will immediately start working.

---

## Need More Help?

Share the **Laravel error logs** (from `storage/logs/laravel.log`) and I can help pinpoint the exact issue and provide a fix.
