<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pet;
use App\Models\Tag;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class MobilePetController extends Controller
{
    /**
     * Get all pets for authenticated customer.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer profile not found'
                ], 404);
            }

            $pets = Pet::where('customer_id', $user->customer_id)
                       ->with(['tag'])
                       ->get();

            return response()->json([
                'success' => true,
                'data' => $pets->map(function ($pet) {
                    $firstTag = $pet->tag;
                    
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
                        'pet_image' => $pet->pet_image,
                        'tag' => $firstTag ? [
                            'id' => $firstTag->id,
                            'tag_code' => $firstTag->tag_code,
                            'status' => $firstTag->status,
                            'qr_code_url' => $firstTag->qr_code_path ?? $firstTag->qr_code_url ?? null,
                        ] : null,
                        'created_at' => $pet->created_at,
                    ];
                })
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('Pet index error: ' . $e->getMessage());
            \Log::error($e->getTraceAsString());
            
            return response()->json([
                'success' => false,
                'message' => 'Server error: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Create new pet.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $user = $request->user();
        
        if (!$user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Customer profile not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'species' => 'required|in:dog,cat,bird,rabbit,other',
            'breed' => 'nullable|string|max:255',
            'age' => 'nullable|integer|min:0',
            'gender' => 'nullable|in:male,female',
            'color' => 'nullable|string|max:255',
            'weight' => 'nullable|numeric|min:0',
            'microchip_id' => 'nullable|string|max:255',
            'microchip_number' => 'nullable|string|max:255',
            'medical_notes' => 'nullable|string|max:1000',
            'pet_image' => 'nullable|image|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $microchip = $request->input('microchip_number', $request->input('microchip_id'));

            $pet = Pet::create([
                'customer_id' => $user->customer_id,
                'name' => $request->name,
                'species' => $request->species,
                'breed' => $request->breed,
                'age' => $request->age,
                'gender' => $request->gender,
                'color' => $request->color,
                'weight' => $request->weight,
                'microchip_id' => $microchip,
                'medical_notes' => $request->medical_notes,
            ]);

            if ($request->hasFile('pet_image')) {
                $path = $request->file('pet_image')->store('pet_images', 'public');
                $publicPath = '/storage/' . ltrim($path, '/');
                $pet->pet_image = $publicPath;
                $pet->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'Pet added successfully',
                'data' => [
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
                    'pet_image' => $pet->pet_image,
                    'created_at' => $pet->created_at,
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to add pet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get specific pet details.
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request, Pet $pet)
    {
        try {
            $user = $request->user();
            
            // Verify pet belongs to customer
            if ($pet->customer_id !== $user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pet not found'
                ], 404);
            }

            $pet->load(['tag', 'customer']);
            $firstTag = $pet->tag;

            return response()->json([
                'success' => true,
                'data' => [
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
                    'pet_image' => $pet->pet_image,
                    'tag' => $firstTag ? [
                        'id' => $firstTag->id,
                        'tag_code' => $firstTag->tag_code,
                        'status' => $firstTag->status,
                        'qr_code_url' => $firstTag->qr_code_path ?? $firstTag->qr_code_url ?? null,
                        'issued_date' => $firstTag->issued_date,
                    ] : null,
                    'owner' => [
                        'id' => $pet->customer->id,
                        'name' => $pet->customer->name,
                        'phone' => $pet->customer->phone,
                    ],
                    'created_at' => $pet->created_at,
                    'updated_at' => $pet->updated_at,
                ]
            ], 200);
            
        } catch (\Exception $e) {
            \Log::error('Pet show error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Server error: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update pet details.
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Pet $pet)
    {
        $user = $request->user();
        
        // Verify pet belongs to customer
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pet not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'species' => 'sometimes|required|in:dog,cat,bird,rabbit,other',
            'breed' => 'nullable|string|max:255',
            'age' => 'nullable|integer|min:0',
            'gender' => 'nullable|in:male,female',
            'color' => 'nullable|string|max:255',
            'weight' => 'nullable|numeric|min:0',
            'microchip_id' => 'nullable|string|max:255',
            'microchip_number' => 'nullable|string|max:255',
            'medical_notes' => 'nullable|string|max:1000',
            'pet_image' => 'nullable|image|max:5120',
            'remove_pet_image' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $updates = $request->only([
                'name', 'species', 'breed', 'age', 'gender', 'color', 'weight', 'medical_notes'
            ]);
            $microchip = $request->input('microchip_number', $request->input('microchip_id'));
            if (!is_null($microchip)) {
                $updates['microchip_id'] = $microchip;
            }
            $pet->update($updates);

            // Remove existing image if requested
            if ($request->boolean('remove_pet_image')) {
                if (!empty($pet->pet_image)) {
                    $rel = ltrim(str_replace('/storage/', '', $pet->pet_image), '/');
                    if ($rel) {
                        try { Storage::disk('public')->delete($rel); } catch (\Throwable $t) {}
                    }
                }
                $pet->pet_image = null;
                $pet->save();
            }

            // Handle new image upload
            if ($request->hasFile('pet_image')) {
                if (!empty($pet->pet_image)) {
                    $rel = ltrim(str_replace('/storage/', '', $pet->pet_image), '/');
                    if ($rel) {
                        try { Storage::disk('public')->delete($rel); } catch (\Throwable $t) {}
                    }
                }
                $path = $request->file('pet_image')->store('pet_images', 'public');
                $publicPath = '/storage/' . ltrim($path, '/');
                $pet->pet_image = $publicPath;
                $pet->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'Pet updated successfully',
                'data' => [
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
                    'pet_image' => $pet->pet_image,
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update pet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete pet.
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request, Pet $pet)
    {
        $user = $request->user();
        
        // Verify pet belongs to customer
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pet not found'
            ], 404);
        }

        try {
            $pet->delete();

            return response()->json([
                'success' => true,
                'message' => 'Pet deleted successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete pet: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Scan QR code and assign tag to pet.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function scanAndAssignTag(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer profile not found'
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'tag_code' => 'required|string',
                'pet_id' => 'required|exists:pets,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Verify pet belongs to customer
            $pet = Pet::find($request->pet_id);
            if ($pet->customer_id !== $user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'You can only assign tags to your own pets'
                ], 403);
            }

            // Find tag by code
            $tag = Tag::where('tag_code', $request->tag_code)->first();
            
            if (!$tag) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid tag code'
                ], 404);
            }

            // Check if tag is already assigned
            if ($tag->pet_id && $tag->pet_id !== $pet->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'This tag is already assigned to another pet'
                ], 422);
            }

            // Check if tag is active
            if ($tag->status !== 'active') {
                return response()->json([
                    'success' => false,
                    'message' => 'This tag is not active'
                ], 422);
            }

            // Assign tag to pet
            $tag->update(['pet_id' => $pet->id]);

            $pet->load(['tag']);

            return response()->json([
                'success' => true,
                'message' => 'Tag assigned successfully',
                'data' => [
                    'pet' => [
                        'id' => $pet->id,
                        'name' => $pet->name,
                        'species' => $pet->species,
                    ],
                    'tag' => [
                        'id' => $tag->id,
                        'tag_code' => $tag->tag_code,
                        'status' => $tag->status,
                        'qr_code_url' => $tag->qr_code_path ?? $tag->qr_code_url ?? null,
                        'issued_date' => $tag->issued_date,
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Tag assignment error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to assign tag: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Assign tag to pet (alternative method).
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function assignTag(Request $request, Pet $pet)
    {
        $user = $request->user();
        
        // Verify pet belongs to customer
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pet not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'tag_code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Find tag by code
        $tag = Tag::where('tag_code', $request->tag_code)->first();
        
        if (!$tag) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid tag code'
            ], 404);
        }

        // Check if tag is already assigned
        if ($tag->pet_id && $tag->pet_id !== $pet->id) {
            return response()->json([
                'success' => false,
                'message' => 'This tag is already assigned to another pet'
            ], 422);
        }

        // Check if tag is active
        if ($tag->status !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'This tag is not active'
            ], 422);
        }

        try {
            // Assign tag to pet
            $tag->update(['pet_id' => $pet->id]);

            return response()->json([
                'success' => true,
                'message' => 'Tag assigned successfully',
                'data' => [
                    'tag' => [
                        'id' => $tag->id,
                        'tag_code' => $tag->tag_code,
                        'status' => $tag->status,
                        'qr_code_url' => $tag->qr_code_path,
                    ]
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to assign tag: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Release/unassign tag from pet.
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function releaseTag(Request $request, Pet $pet)
    {
        try {
            $user = $request->user();
            
            // Verify pet belongs to customer
            if ($pet->customer_id !== $user->customer_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pet not found'
                ], 404);
            }

            // Get the tag before releasing
            $tag = $pet->tag;
            
            if (!$tag) {
                return response()->json([
                    'success' => false,
                    'message' => 'No tag assigned to this pet'
                ], 400);
            }

            // Clear the pet_id from the tag to unassign it
            $tag->update(['pet_id' => null]);

            return response()->json([
                'success' => true,
                'message' => 'Tag released successfully',
                'data' => [
                    'pet' => [
                        'id' => $pet->id,
                        'name' => $pet->name,
                        'species' => $pet->species,
                    ],
                    'released_tag_code' => $tag->tag_code,
                ]
            ], 200);

        } catch (\Exception $e) {
            \Log::error('Tag release error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to release tag: ' . $e->getMessage()
            ], 500);
        }
    }


    /**
     * Get medical treatment records for a pet.
     * 
     * @param Request $request
     * @param Pet $pet
     * @return \Illuminate\Http\JsonResponse
     */
    public function treatments(Request $request, Pet $pet)
    {
        $user = $request->user();
        
        // Verify pet belongs to customer
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pet not found'
            ], 404);
        }

        $treatments = $pet->treatments()
                          ->with(['collaborator'])
                          ->orderBy('treatment_date', 'desc')
                          ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'pet' => [
                    'id' => $pet->id,
                    'name' => $pet->name,
                    'species' => $pet->species,
                ],
                'treatments' => $treatments->map(function ($treatment) {
                    return [
                        'id' => $treatment->id,
                        'treatment_date' => $treatment->treatment_date,
                        'treatment_location' => $treatment->treatment_location,
                        'diagnosis' => $treatment->diagnosis,
                        'disease' => $treatment->disease,
                        'medicine_prescribed' => $treatment->medicine_prescribed,
                        'notes' => $treatment->notes,
                        'collaborator' => $treatment->collaborator ? [
                            'id' => $treatment->collaborator->id,
                            'name' => $treatment->collaborator->name,
                            'clinic_name' => $treatment->collaborator->clinic_name,
                        ] : null,
                        'created_at' => $treatment->created_at,
                    ];
                })
            ]
        ], 200);
    }

    /**
     * Get specific treatment details.
     * 
     * @param Request $request
     * @param Pet $pet
     * @param int $treatmentId
     * @return \Illuminate\Http\JsonResponse
     */
    public function treatmentDetail(Request $request, Pet $pet, $treatmentId)
    {
        $user = $request->user();
        
        // Verify pet belongs to customer
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Pet not found'
            ], 404);
        }

        $treatment = $pet->treatments()->with(['collaborator'])->find($treatmentId);

        if (!$treatment) {
            return response()->json([
                'success' => false,
                'message' => 'Treatment record not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $treatment->id,
                'pet' => [
                    'id' => $pet->id,
                    'name' => $pet->name,
                    'species' => $pet->species,
                    'breed' => $pet->breed,
                    'age' => $pet->age,
                ],
                'treatment_date' => $treatment->treatment_date,
                'treatment_location' => $treatment->treatment_location,
                'diagnosis' => $treatment->diagnosis,
                'disease' => $treatment->disease,
                'medicine_prescribed' => $treatment->medicine_prescribed,
                'dosage' => $treatment->dosage,
                'notes' => $treatment->notes,
                'collaborator' => $treatment->collaborator ? [
                    'id' => $treatment->collaborator->id,
                    'name' => $treatment->collaborator->name,
                    'clinic_name' => $treatment->collaborator->clinic_name,
                    'phone' => $treatment->collaborator->phone,
                    'address' => $treatment->collaborator->address,
                ] : null,
                'created_at' => $treatment->created_at,
                'updated_at' => $treatment->updated_at,
            ]
        ], 200);
    }
}
