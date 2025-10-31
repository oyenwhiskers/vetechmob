<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class MobileAuthController extends Controller
{
    /**
     * Register a new customer user account.
     * Matches existing customer by IC number to prevent duplicates.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'phone' => 'required|string|max:20',
            'ic_number' => 'required|string|max:20',
            'address' => 'nullable|string|max:500',
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Normalize IC number (uppercase, remove dashes)
            $icNumber = strtoupper(str_replace('-', '', $request->ic_number));
            
            // Check if user already exists with this email
            $existingUser = User::where('email', strtolower($request->email))->first();
            if ($existingUser) {
                if ($existingUser->role === 'customer') {
                    return response()->json([
                        'success' => false,
                        'message' => 'An account with this email already exists. Please log in instead.'
                    ], 409);
                } else {
                    return response()->json([
                        'success' => false,
                        'message' => 'This email is already registered for a different account type. Please use a different email.'
                    ], 409);
                }
            }

            // Look for existing customer by IC number (primary match)
            $customer = Customer::where('ic_number', $icNumber)->first();
            
            if (!$customer) {
                // If not found by IC, try email as fallback
                $customer = Customer::where('email', strtolower($request->email))->first();
            }
            
            if (!$customer) {
                // Create new customer profile
                $customer = Customer::create([
                    'name' => $request->name,
                    'email' => strtolower($request->email),
                    'phone' => $request->phone,
                    'ic_number' => $icNumber,
                    'address' => $request->address ?? '',
                ]);
            } else {
                // Update existing customer with any new information
                $customer->update([
                    'phone' => $request->phone,
                    'address' => $request->address ?? $customer->address,
                ]);
            }

            // Create user account linked to customer
            $user = User::create([
                'name' => $request->name,
                'email' => strtolower($request->email),
                'password' => Hash::make($request->password),
                'role' => 'customer',
                'customer_id' => $customer->id,
            ]);

            // Create Sanctum token for authentication
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
                        'profile_image' => $customer->profile_image ?? null,
                    ],
                    'token' => $token,
                    'token_type' => 'Bearer'
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Registration failed: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Login user and return token.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', strtolower($request->email))->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password'
            ], 401);
        }

        // Check if user is customer
        if ($user->role !== 'customer') {
            return response()->json([
                'success' => false,
                'message' => 'This account type cannot log in via mobile app'
            ], 403);
        }

        // Load customer profile
        $user->load('customer');

        // Create token
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'customer' => $user->customer ? [
                    'id' => $user->customer->id,
                    'name' => $user->customer->name,
                    'email' => $user->customer->email,
                    'phone' => $user->customer->phone,
                    'ic_number' => $user->customer->ic_number,
                    'address' => $user->customer->address,
                    'profile_image' => $user->customer->profile_image ?? null,
                ] : null,
                'token' => $token,
                'token_type' => 'Bearer'
            ]
        ], 200);
    }

    /**
     * Logout user (revoke token).
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully'
        ], 200);
    }

    /**
     * Get authenticated user details.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function user(Request $request)
    {
        $user = $request->user();
        $user->load('customer');

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'customer' => $user->customer ? [
                    'id' => $user->customer->id,
                    'name' => $user->customer->name,
                    'email' => $user->customer->email,
                    'phone' => $user->customer->phone,
                    'ic_number' => $user->customer->ic_number,
                    'address' => $user->customer->address,
                    'profile_image' => $user->customer->profile_image ?? null,
                ] : null,
            ]
        ], 200);
    }

    /**
     * Request password reset (placeholder - implement email sending).
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', strtolower($request->email))
                    ->where('role', 'customer')
                    ->first();

        if (!$user) {
            // Don't reveal if email exists for security
            return response()->json([
                'success' => true,
                'message' => 'If your email is registered, you will receive password reset instructions.'
            ], 200);
        }

        // TODO: Send password reset email
        // For now, return success message
        return response()->json([
            'success' => true,
            'message' => 'If your email is registered, you will receive password reset instructions.'
        ], 200);
    }

    /**
     * Reset password (placeholder - implement token verification).
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // TODO: Verify token and reset password
        return response()->json([
            'success' => true,
            'message' => 'Password reset functionality will be implemented with email service.'
        ], 200);
    }
    
    /**
     * Get OpenAI API Key for authenticated users
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOpenAIKey(Request $request)
    {
        // Get key from .env file on server
        $apiKey = env('OPENAI_API_KEY');
        
        if (empty($apiKey)) {
            return response()->json([
                'success' => false,
                'message' => 'OpenAI API key not configured on server'
            ], 500);
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'api_key' => $apiKey
            ]
        ]);
    }
}
