<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Storage;

class MobileProfileController extends Controller
{
    /**
     * Get customer profile.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request)
    {
        $user = $request->user();
        $user->load('customer');

        if (!$user->customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer profile not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                ],
                'customer' => [
                    'id' => $user->customer->id,
                    'name' => $user->customer->name,
                    'email' => $user->customer->email,
                    'phone' => $user->customer->phone,
                    'ic_number' => $user->customer->ic_number,
                    'profile_image' => $user->customer->profile_image
                        ? (str_starts_with($user->customer->profile_image, 'http') || str_starts_with($user->customer->profile_image, '/storage/')
                            ? $user->customer->profile_image
                            : Storage::url(ltrim(str_replace('/storage/', '', parse_url($user->customer->profile_image, PHP_URL_PATH) ?? $user->customer->profile_image), '/')))
                        : null,
                    'address' => $user->customer->address,
                ],
                'stats' => [
                    'total_pets' => $user->customer->pets()->count(),
                    'total_bookings' => $user->customer->bookings()->count(),
                ]
            ]
        ], 200);
    }

    /**
     * Update customer profile.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request)
    {
        $user = $request->user();
        
        if (!$user->customer) {
            return response()->json([
                'success' => false,
                'message' => 'Customer profile not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'phone' => 'sometimes|required|string|max:20',
            'address' => 'sometimes|nullable|string|max:500',
            'email' => 'sometimes|required|email|max:255|unique:users,email,' . $user->id,
            'profile_image' => 'sometimes|nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            'remove_profile_image' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Update user name and email if provided
            $userData = [];
            if ($request->has('name')) {
                $userData['name'] = $request->name;
            }
            if ($request->has('email')) {
                $userData['email'] = strtolower($request->email);
            }
            
            if (!empty($userData)) {
                $user->update($userData);
            }

            // Update customer profile
            $customerData = $request->only(['name', 'phone', 'address']);
            if ($request->has('email')) {
                $customerData['email'] = strtolower($request->email);
            }

            // Remove existing image when requested
            if ($request->boolean('remove_profile_image')) {
                $existing = $user->customer->profile_image;
                if ($existing) {
                    $existingPath = ltrim(str_replace('/storage/', '', parse_url($existing, PHP_URL_PATH) ?? $existing), '/');
                    Storage::disk('public')->delete($existingPath);
                }
                $customerData['profile_image'] = null;
            }

            // Save new image if uploaded
            if ($request->hasFile('profile_image')) {
                $existing = $user->customer->profile_image;
                if ($existing) {
                    $existingPath = ltrim(str_replace('/storage/', '', parse_url($existing, PHP_URL_PATH) ?? $existing), '/');
                    Storage::disk('public')->delete($existingPath);
                }
                $imagePath = $request->file('profile_image')->store('profile_images', 'public');
                $customerData['profile_image'] = $imagePath; // store storage path only
            }
            
            if (!empty($customerData)) {
                $user->customer->update($customerData);
            }

            $user->refresh();
            $user->load('customer');

            return response()->json([
                'success' => true,
                'message' => 'Profile updated successfully',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                    ],
                    'customer' => [
                        'id' => $user->customer->id,
                        'name' => $user->customer->name,
                        'email' => $user->customer->email,
                        'phone' => $user->customer->phone,
                        'ic_number' => $user->customer->ic_number,
                        'address' => $user->customer->address,
                        'profile_image' => $user->customer->profile_image
                            ? (str_starts_with($user->customer->profile_image, 'http') || str_starts_with($user->customer->profile_image, '/storage/')
                                ? $user->customer->profile_image
                                : Storage::url(ltrim(str_replace('/storage/', '', parse_url($user->customer->profile_image, PHP_URL_PATH) ?? $user->customer->profile_image), '/')))
                            : null,
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update profile: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update password.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updatePassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'password' => ['required', 'confirmed', Password::defaults()],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        // Verify current password
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect'
            ], 422);
        }

        try {
            $user->update([
                'password' => Hash::make($request->password)
            ]);

            // Revoke all other tokens
            $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

            return response()->json([
                'success' => true,
                'message' => 'Password updated successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update password: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete account.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        // Verify password
        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password is incorrect'
            ], 422);
        }

        try {
            // Revoke all tokens
            $user->tokens()->delete();
            
            // Delete user (keeps customer record for historical data)
            $user->delete();

            return response()->json([
                'success' => true,
                'message' => 'Account deleted successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete account: ' . $e->getMessage()
            ], 500);
        }
    }
}
