<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileDashboardController extends Controller
{
    /**
     * Get dashboard overview for customer.
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

        $customer = $user->customer;

        try {
            // Get statistics
            $totalPets = $customer->pets()->count();
            $totalBookings = $customer->bookings()->count();
            $upcomingBookings = $customer->bookings()
                                        ->where('status', 'upcoming')
                                        ->where('booking_date', '>=', now()->toDateString())
                                        ->count();

            // Get recent bookings
            $recentBookings = $customer->bookings()
                                      ->with('pet')
                                      ->orderBy('booking_date', 'desc')
                                      ->orderBy('booking_time', 'desc')
                                      ->limit(5)
                                      ->get();

            // Get pets with recent treatments
            $petsWithTreatments = $customer->pets()
                                          ->withCount('treatments')
                                          ->with(['treatments' => function ($query) {
                                              $query->orderBy('treatment_date', 'desc')
                                                    ->limit(1);
                                          }])
                                          ->get();

            // Count total treatments
            $totalTreatments = DB::table('treatments')
                                ->join('pets', 'treatments.pet_id', '=', 'pets.id')
                                ->where('pets.customer_id', $customer->id)
                                ->count();

            // Get next upcoming booking
            $nextBooking = $customer->bookings()
                                   ->where('status', 'upcoming')
                                   ->where('booking_date', '>=', now()->toDateString())
                                   ->with('pet')
                                   ->orderBy('booking_date', 'asc')
                                   ->orderBy('booking_time', 'asc')
                                   ->first();

            return response()->json([
                'success' => true,
                'data' => [
                    'statistics' => [
                        'total_pets' => $totalPets,
                        'total_bookings' => $totalBookings,
                        'upcoming_bookings' => $upcomingBookings,
                        'total_treatments' => $totalTreatments,
                    ],
                    'next_booking' => $nextBooking ? [
                        'id' => $nextBooking->id,
                        'pet' => [
                            'id' => $nextBooking->pet->id,
                            'name' => $nextBooking->pet->name,
                            'species' => $nextBooking->pet->species,
                        ],
                        'booking_date' => $nextBooking->booking_date,
                        'booking_time' => $nextBooking->booking_time,
                        'service_type' => $nextBooking->service_type,
                    ] : null,
                    'recent_bookings' => $recentBookings->map(function ($booking) {
                        return [
                            'id' => $booking->id,
                            'pet' => $booking->pet ? [
                                'id' => $booking->pet->id,
                                'name' => $booking->pet->name,
                                'species' => $booking->pet->species,
                            ] : null,
                            'booking_date' => $booking->booking_date,
                            'booking_time' => $booking->booking_time,
                            'service_type' => $booking->service_type,
                            'status' => $booking->status,
                        ];
                    }),
                    'pets' => $petsWithTreatments->map(function ($pet) {
                        $lastTreatment = $pet->treatments->first();
                        return [
                            'id' => $pet->id,
                            'name' => $pet->name,
                            'species' => $pet->species,
                            'breed' => $pet->breed,
                            'age' => $pet->age,
                            'treatment_count' => $pet->treatments_count,
                            'last_treatment_date' => $lastTreatment ? $lastTreatment->treatment_date : null,
                        ];
                    }),
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to load dashboard: ' . $e->getMessage()
            ], 500);
        }
    }
}
