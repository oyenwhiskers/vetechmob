# Debugging 500 Internal Server Error - Registration Endpoint

## Problem
`POST http://inovetsmart.com/api/v1/register` returns **500 Internal Server Error**

## What is a 500 Error?
A 500 error means **the server encountered an unexpected condition** that prevented it from fulfilling the request. This is **NOT a client-side issue** - the mobile app is likely sending correct data, but something on the server is failing.

---

## Changes Made to Debug

### 1. ✅ Added Detailed Logging to `api_client.dart`
The app will now print detailed request/response information to the console:
- 🔵 REQUEST logs show exactly what's being sent
- 🟢 RESPONSE logs show successful responses
- 🔴 ERROR logs show detailed error information including status code and response body

**To view logs:**
- Run the app: `flutter run`
- Watch the console output when you tap "Create account"
- Look for the colored emoji markers (🔵🟢🔴)

### 2. ✅ Improved Error Display in `auth_provider.dart`
The error message shown to the user now includes:
- HTTP status code in brackets [500]
- Actual error message from server
- Validation errors if any

---

## Client-Side Verification ✅

Based on your API documentation, the mobile app is sending the **correct payload**:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+60123456789",
  "ic_number": "901234125678",  // ✅ Correctly strips dashes and uppercases
  "address": "123 Main Street",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!"
}
```

The `auth_service.dart` properly formats the IC number:
```dart
'ic_number': icNumber.replaceAll('-', '').toUpperCase()
```

---

## Server-Side Investigation Required 🔧

Since this is a **500 error**, the issue is on the **backend server**. Here's what to check:

### 1. Check Laravel Error Logs
```bash
# SSH into your server
ssh user@inovetsmart.com

# View Laravel logs
tail -f storage/logs/laravel.log

# Or check the latest log
cat storage/logs/laravel-$(date +%Y-%m-%d).log
```

### 2. Common Causes of 500 Errors in Laravel Registration

#### A. Database Connection Issues
- ❌ Database server not running
- ❌ Wrong credentials in `.env`
- ❌ Database doesn't exist
- ❌ User doesn't have permissions

**Check:** Run `php artisan migrate:status`

#### B. Missing or Invalid Database Tables
- ❌ `users` table doesn't exist
- ❌ `customers` table doesn't exist
- ❌ Missing columns (name, email, password, etc.)

**Check:** Run `php artisan migrate`

#### C. Validation or Logic Errors in RegisterController
Common issues:
- ❌ Hash facade not imported (`use Illuminate\Support\Facades\Hash;`)
- ❌ Trying to find customer by IC but query fails
- ❌ Trying to create user but email already exists
- ❌ Missing required fields in database schema

#### D. Sanctum Token Creation Issues
- ❌ Sanctum not properly installed
- ❌ `personal_access_tokens` table missing
- ❌ Token creation method fails

**Check:** Run `php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"`

#### E. Environment Configuration
- ❌ `APP_DEBUG=false` in production (hides error details)
- ❌ Missing environment variables
- ❌ Cache issues

**Fix:** 
```bash
php artisan config:clear
php artisan cache:clear
php artisan config:cache
```

### 3. Enable Debug Mode Temporarily

Edit `.env` on the server:
```env
APP_DEBUG=true
APP_ENV=local
```

**⚠️ IMPORTANT:** This will show detailed error messages in the API response. Test registration again and check the error details. **Remember to turn it off after debugging:**
```env
APP_DEBUG=false
APP_ENV=production
```

### 4. Test Registration with cURL

From your server or local machine:
```bash
curl -X POST http://inovetsmart.com/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+60123456789",
    "ic_number": "901234125678",
    "address": "Test Address",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }'
```

If this also returns 500, the issue is definitely server-side.

### 5. Check Server Resources
- ❌ Out of disk space
- ❌ Out of memory
- ❌ PHP max execution time reached
- ❌ PHP memory limit too low

```bash
# Check disk space
df -h

# Check PHP configuration
php -i | grep memory_limit
php -i | grep max_execution_time
```

### 6. Check Web Server Error Logs

**For Apache:**
```bash
tail -f /var/log/apache2/error.log
```

**For Nginx:**
```bash
tail -f /var/log/nginx/error.log
```

### 7. Check RegisterController Code

The controller should look something like this (from your API_DOCUMENTATION.md):

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class RegisterController extends Controller
{
    public function register(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|unique:users',
                'phone' => 'required|string',
                'ic_number' => 'required|string',
                'address' => 'required|string',
                'password' => 'required|string|min:8',
                'password_confirmation' => 'required|same:password',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Find or create customer by IC number
            $customer = Customer::where('ic_number', $request->ic_number)->first();
            
            if (!$customer) {
                $customer = Customer::create([
                    'name' => $request->name,
                    'email' => $request->email,
                    'phone' => $request->phone,
                    'ic_number' => $request->ic_number,
                    'address' => $request->address,
                ]);
            }

            // Create user account
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => 'customer',
                'customer_id' => $customer->id,
            ]);

            // Create Sanctum token
            $token = $user->createToken('mobile-app')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Registration successful',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'role' => $user->role,
                    ],
                    'customer' => [
                        'id' => $customer->id,
                        'name' => $customer->name,
                        'email' => $customer->email,
                        'phone' => $customer->phone,
                        'ic_number' => $customer->ic_number,
                        'address' => $customer->address,
                    ],
                    'token' => $token,
                    'token_type' => 'Bearer',
                ]
            ], 201);
            
        } catch (\Exception $e) {
            // This catch block should log the error
            \Log::error('Registration error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Server error',
                'error' => config('app.debug') ? $e->getMessage() : 'Internal server error'
            ], 500);
        }
    }
}
```

**Common mistakes in the controller:**
- Missing `try-catch` block
- Not checking if customer exists before creating user
- Wrong column names in database
- Missing `customer_id` foreign key in users table
- Not returning proper JSON response

---

## Next Steps to Debug

### Step 1: Run the Flutter App and Capture Logs
```powershell
flutter run
```

Then try to register and **copy the entire console output**, especially the 🔴 ERROR section.

### Step 2: Check Server Logs
Look at the actual error message in Laravel logs. This will tell you exactly what's failing.

### Step 3: Test with cURL
Test the endpoint directly with cURL to confirm it's a server issue.

### Step 4: Enable Debug Mode
Temporarily enable `APP_DEBUG=true` to see detailed error messages in the API response.

### Step 5: Share the Error Details
Once you have:
- Flutter console logs (the 🔴 ERROR output)
- Laravel error logs
- cURL response with debug mode on

You'll be able to pinpoint the exact issue.

---

## Expected Working Flow

When everything is working correctly, you should see:

### In Flutter Console:
```
🔵 REQUEST: POST http://inovetsmart.com/api/v1/register
📤 Headers: {Content-Type: application/json, Accept: application/json}
📦 Data: {name: Test User, email: test@example.com, phone: +60123456789, ic_number: 901234125678, address: Test Address, password: Password123!, password_confirmation: Password123!}

🟢 RESPONSE: 201 http://inovetsmart.com/api/v1/register
📥 Data: {success: true, message: Registration successful, data: {...}}
```

### In the App:
- User is redirected to Home Shell
- Dashboard loads with user data

---

## Quick Fixes to Try

### On the Server (SSH in):
```bash
# 1. Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# 2. Re-cache configuration
php artisan config:cache

# 3. Check migrations
php artisan migrate:status

# 4. If migrations haven't run:
php artisan migrate

# 5. Check if Sanctum is installed:
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# 6. Re-run Sanctum migrations:
php artisan migrate

# 7. Check Laravel logs:
tail -f storage/logs/laravel.log
```

---

## Summary

**The mobile app is working correctly** - it's sending the right data in the right format. The issue is on the **backend server**:

1. ✅ Mobile app sends correct payload
2. ✅ IC number is properly formatted (stripped dashes, uppercased)
3. ❌ Server returns 500 error (something failing on backend)

**You need to:**
1. Check Laravel error logs on the server
2. Enable debug mode temporarily to see error details
3. Verify database tables exist and have correct columns
4. Check that Sanctum is properly installed

Once you get the actual error message from the server logs, the fix will be straightforward!
