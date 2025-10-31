<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class MobileBookingController extends Controller
{
    /**
     * Get all bookings for authenticated customer.
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        if (!$user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Customer profile not found'
            ], 404);
        }

    $status = $request->query('status'); // pending, confirmed, completed, cancelled
    $petId = $request->query('pet_id'); // optional filter by pet
    $date = $request->query('date'); // optional filter by specific date (YYYY-MM-DD)

        $query = Booking::where('customer_id', $user->customer_id)
                       ->with(['pet']);

        if ($status) {
            $query->where('status', $status);
        }

        if ($petId) {
            $query->where('pet_id', $petId);
        }

        if ($date) {
            $query->whereDate('booking_date', $date);
        }

        $bookings = $query->orderBy('booking_date', 'desc')
                         ->orderBy('booking_time', 'desc')
                         ->get();

        return response()->json([
            'success' => true,
            'data' => $bookings->map(function ($booking) {
                return $this->formatBooking($booking);
            })
        ], 200);
    }

    /**
     * Create new booking.
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
            'pet_id' => 'required|exists:pets,id',
            'booking_date' => 'required|date|after_or_equal:today',
            'booking_time' => 'required|date_format:H:i',
            'service_type' => 'required|string|max:255',
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Verify pet belongs to customer
        $pet = \App\Models\Pet::find($request->pet_id);
        if ($pet->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'You can only book appointments for your own pets'
            ], 403);
        }

        try {
            $booking = Booking::create([
                'customer_id' => $user->customer_id,
                'pet_id' => $request->pet_id,
                'booking_date' => $request->booking_date,
                'booking_time' => $request->booking_time,
                'service_type' => $request->service_type,
                'status' => 'pending',
                'notes' => $request->notes,
            ]);

            $booking->load('pet');

            return response()->json([
                'success' => true,
                'message' => 'Booking created successfully',
                'data' => $this->formatBooking($booking),
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create booking: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get specific booking details.
     * 
     * @param Request $request
     * @param Booking $booking
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Request $request, Booking $booking)
    {
        $user = $request->user();
        
        // Verify booking belongs to customer
        if ($booking->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Booking not found'
            ], 404);
        }

        $booking->load('pet');

        return response()->json([
            'success' => true,
            'data' => $this->formatBooking($booking),
        ], 200);
    }

    /**
     * Update booking (only upcoming bookings).
     * 
     * @param Request $request
     * @param Booking $booking
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Booking $booking)
    {
        $user = $request->user();
        
        // Verify booking belongs to customer
        if ($booking->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Booking not found'
            ], 404);
        }

        // Only allow updating pending bookings
        if ($booking->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending bookings can be updated'
            ], 422);
        }

        $validator = Validator::make($request->all(), [
            'booking_date' => 'sometimes|required|date|after_or_equal:today',
            'booking_time' => 'sometimes|required|date_format:H:i',
            'service_type' => 'sometimes|required|string|max:255',
            'notes' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $booking->update($request->only([
                'booking_date',
                'booking_time',
                'service_type',
                'notes'
            ]));

            $booking->load('pet');

            return response()->json([
                'success' => true,
                'message' => 'Booking updated successfully',
                'data' => $this->formatBooking($booking),
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update booking: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Normalize booking payload to fixed formats:
     * booking_date -> YYYY-MM-DD, booking_time -> HH:mm (no timezone drift)
     */
    private function formatBooking(Booking $booking): array
    {
        $pet = $booking->pet;

        // Normalize date to Y-m-d
        $date = $booking->booking_date ? Carbon::parse($booking->booking_date)->toDateString() : null;

        // Normalize time to H:i (keep the exact time set, avoid timezone conversions)
        $time = null;
        if ($booking->booking_time) {
            try {
                $time = Carbon::parse($booking->booking_time)->format('H:i');
            } catch (\Throwable $e) {
                // If parsing fails, fallback to raw string
                $time = (string) $booking->booking_time;
            }
        }

        $is_appointment = $booking->booking_by !== null;

        return [
            'id' => $booking->id,
            'is_appointment' => $is_appointment,
            'pet' => $pet ? [
                'id' => $pet->id,
                'name' => $pet->name,
                'species' => $pet->species,
                'breed' => $pet->breed ?? null,
                'age' => $pet->age ?? null,
            ] : null,
            'booking_date' => $date,
            'booking_time' => $time,
            'service_type' => $booking->service_type,
            'status' => $booking->status,
            'notes' => $booking->notes,
            'created_at' => $booking->created_at,
            'updated_at' => $booking->updated_at,
        ];
    }

    /**
     * Cancel booking.
     * 
     * @param Request $request
     * @param Booking $booking
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Request $request, Booking $booking)
    {
        $user = $request->user();
        
        // Verify booking belongs to customer
        if ($booking->customer_id !== $user->customer_id) {
            return response()->json([
                'success' => false,
                'message' => 'Booking not found'
            ], 404);
        }

        // Only allow cancelling pending bookings
        if ($booking->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Only pending bookings can be cancelled'
            ], 422);
        }

        try {
            $booking->update(['status' => 'cancelled']);

            return response()->json([
                'success' => true,
                'message' => 'Booking cancelled successfully'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to cancel booking: ' . $e->getMessage()
            ], 500);
        }
    }
}
