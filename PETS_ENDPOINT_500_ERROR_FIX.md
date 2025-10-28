# Server 500 Error - GET /pets Endpoint

## Problem Summary
- **Endpoint:** `GET http://inovetsmart.com/api/v1/pets`
- **Expected Response:** List of pets for authenticated customer
- **Actual Response:** 500 Internal Server Error with `{message: Server Error}`
- **Mobile App:** ✅ Working correctly (sending proper auth token)

---

## Your API Spec (from API_DOCUMENTATION.md)

### Expected Endpoint Behavior

**Endpoint:** `GET /pets`  
**Authentication:** Required (Bearer token)

**Expected Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Buddy",
      "species": "dog",
      "breed": "Golden Retriever",
      "age": 3,
      "gender": "male",
      "color": "Golden",
      "weight": 30.5,
      "microchip_id": "123456789",
      "medical_notes": "Allergic to chicken",
      "tag": {
        "id": 1,
        "tag_code": "1000",
        "status": "active",
        "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=1000"
      },
      "created_at": "2025-01-15T08:00:00.000000Z"
    }
  ]
}
```

---

## Laravel Backend Issues to Check

### 1. Check Laravel Error Logs (CRITICAL)

```bash
# SSH into server
ssh user@inovetsmart.com

# View last 100 lines of logs
tail -100 storage/logs/laravel.log

# Watch logs live (in another terminal, then trigger the error from mobile)
tail -f storage/logs/laravel.log
```

**Look for these specific errors:**

#### A. Table/Column Missing
```
SQLSTATE[42S02]: Base table or view not found: 1146 Table 'database.pets' doesn't exist
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'customer_id' in 'where clause'
```

#### B. Foreign Key Issues
```
SQLSTATE[23000]: Integrity constraint violation
SQLSTATE[HY000]: General error: 1364 Field 'customer_id' doesn't have a default value
```

#### C. Relationship Errors
```
Call to undefined method App\Models\Pet::tag()
Trying to get property 'customer_id' of non-object
```

---

### 2. Your PetsController Should Look Like This

**File:** `app/Http/Controllers/Api/V1/PetsController.php`

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Pet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PetsController extends Controller
{
    /**
     * Get all pets for authenticated customer
     * GET /api/v1/pets
     */
    public function index(Request $request)
    {
        try {
            // Get authenticated user
            $user = $request->user();
            
            // Check if user has customer_id
            if (!$user || !$user->customer_id) {
                Log::error('Pets index: User has no customer_id', ['user' => $user]);
                return response()->json([
                    'success' => false,
                    'message' => 'Customer profile not found'
                ], 404);
            }
            
            // Get pets with tag relationship
            $pets = Pet::where('customer_id', $user->customer_id)
                ->with('tag')  // Eager load tag relationship
                ->orderBy('created_at', 'desc')
                ->get();
            
            // Transform to match API spec
            $petsData = $pets->map(function($pet) {
                return [
                    'id' => $pet->id,
                    'name' => $pet->name,
                    'species' => $pet->species,
                    'breed' => $pet->breed,
                    'age' => $pet->age,
                    'gender' => $pet->gender,
                    'color' => $pet->color,
                    'weight' => $pet->weight,
                    'microchip_id' => $pet->microchip_id,
                    'medical_notes' => $pet->medical_notes,
                    'tag' => $pet->tag ? [
                        'id' => $pet->tag->id,
                        'tag_code' => $pet->tag->tag_code,
                        'status' => $pet->tag->status,
                        'qr_code_url' => "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data={$pet->tag->tag_code}"
                    ] : null,
                    'created_at' => $pet->created_at->toISOString(),
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $petsData
            ], 200);
            
        } catch (\Exception $e) {
            // Log the full error
            Log::error('Pets index error: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());
            
            return response()->json([
                'success' => false,
                'message' => 'Server error',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
```

---

### 3. Check Your Pet Model

**File:** `app/Models/Pet.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pet extends Model
{
    protected $table = 'pets';
    
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
    
    protected $casts = [
        'age' => 'integer',
        'weight' => 'float',
    ];
    
    /**
     * Relationship: Pet belongs to Customer
     */
    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }
    
    /**
     * Relationship: Pet has one Tag
     * IMPORTANT: Adjust table and foreign key names to match your database
     */
    public function tag()
    {
        // Adjust 'pet_tags' and 'pet_id' to match your actual table structure
        return $this->hasOne(PetTag::class, 'pet_id');
    }
}
```

---

### 4. Check Your Routes

**File:** `routes/api.php`

```php
Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    // Pets endpoints
    Route::get('/pets', [PetsController::class, 'index']);
    Route::post('/pets', [PetsController::class, 'store']);
    Route::get('/pets/{id}', [PetsController::class, 'show']);
    Route::put('/pets/{id}', [PetsController::class, 'update']);
    Route::delete('/pets/{id}', [PetsController::class, 'destroy']);
    
    // Pet tag endpoints
    Route::post('/pets/scan-tag', [PetsController::class, 'scanTag']);
    Route::post('/pets/{id}/assign-tag', [PetsController::class, 'assignTag']);
    
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);
    
    // ... other routes
});
```

---

### 5. Database Schema Check

Run these queries on your server:

```bash
# Connect to database
mysql -u your_user -p your_database

# Check if pets table exists and see its structure
DESCRIBE pets;

# Check if customer_id column exists
SHOW COLUMNS FROM pets LIKE 'customer_id';

# Check sample data
SELECT id, customer_id, name, species FROM pets LIMIT 5;

# Check if there are pets with NULL customer_id (this would cause issues)
SELECT COUNT(*) FROM pets WHERE customer_id IS NULL;

# Check users table has customer_id
DESCRIBE users;
SHOW COLUMNS FROM users LIKE 'customer_id';

# Verify your user has a customer_id
SELECT id, email, customer_id FROM users WHERE email = 'your-email@example.com';
```

---

### 6. Common Fixes

#### Fix 1: Missing customer_id in users table

```sql
ALTER TABLE users ADD COLUMN customer_id BIGINT UNSIGNED NULL;
ALTER TABLE users ADD FOREIGN KEY (customer_id) REFERENCES customers(id);
```

#### Fix 2: Pets table doesn't exist

```bash
php artisan migrate
```

Or create migration:
```bash
php artisan make:migration create_pets_table
```

#### Fix 3: Tag relationship issues

Check your `pet_tags` table structure:
```sql
DESCRIBE pet_tags;
```

Make sure it has:
- `id` (primary key)
- `pet_id` (foreign key to pets table)
- `tag_code`
- `status`

---

### 7. Test Directly on Server

```bash
# Test with tinker
php artisan tinker

>>> $user = \App\Models\User::where('email', 'your-email@example.com')->first();
>>> $user->customer_id;  // Should return a number, not null
>>> \App\Models\Pet::where('customer_id', $user->customer_id)->count();
>>> \App\Models\Pet::where('customer_id', $user->customer_id)->get();
```

---

### 8. Enable Debug Mode Temporarily

**Edit `.env`:**
```env
APP_DEBUG=true
APP_ENV=local
```

**Test the endpoint again** - you'll see the exact error in the response.

**⚠️ IMPORTANT: Turn it back off after debugging:**
```env
APP_DEBUG=false
APP_ENV=production
```

---

### 9. Test with cURL

```bash
# First login to get token
curl -X POST http://inovetsmart.com/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "password": "your-password"
  }'

# Copy the token from response, then test pets
curl -X GET http://inovetsmart.com/api/v1/pets \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Accept: application/json" \
  -v
```

The `-v` flag will show you the full request/response including headers.

---

## Most Likely Causes (in order)

1. **User doesn't have `customer_id` field** (90% chance)
   - Check: `SELECT id, email, customer_id FROM users WHERE email = 'your-email';`
   - Fix: Update user record or fix registration logic

2. **Pets table missing or wrong structure** (5% chance)
   - Check: `DESCRIBE pets;`
   - Fix: Run migrations

3. **Tag relationship broken** (3% chance)
   - Check: Pet model's `tag()` method
   - Fix: Adjust foreign key names

4. **Authentication middleware issue** (2% chance)
   - Check: Routes file
   - Fix: Ensure `auth:sanctum` is applied

---

## Quick Diagnostic Script

Run this in `php artisan tinker` to diagnose:

```php
// Check if pets table exists
try {
    $count = \App\Models\Pet::count();
    echo "✓ Pets table exists with $count records\n";
} catch (\Exception $e) {
    echo "✗ Pets table issue: " . $e->getMessage() . "\n";
}

// Check user structure
$user = \App\Models\User::first();
if ($user) {
    echo $user->customer_id ? "✓ Users have customer_id\n" : "✗ Users missing customer_id\n";
}

// Check if Pet has tag relationship
try {
    $pet = \App\Models\Pet::with('tag')->first();
    echo "✓ Pet tag relationship works\n";
} catch (\Exception $e) {
    echo "✗ Pet tag relationship issue: " . $e->getMessage() . "\n";
}
```

---

## After You Fix It

1. Clear Laravel caches:
   ```bash
   php artisan config:clear
   php artisan cache:clear
   php artisan route:clear
   php artisan config:cache
   ```

2. Test again from mobile app - should work immediately!

---

## Share Laravel Logs

If you're still stuck, share the contents of `storage/logs/laravel.log` (the error section) and I'll tell you exactly what to fix!
