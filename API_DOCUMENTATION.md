# VETech Mobile API Documentation

## Overview
This is the complete API documentation for the VETech mobile application. The API enables customer users to register, manage their profile, book veterinary services, manage their pets, scan QR tags, and view medical treatment records.

**Base URL:** `http://127.0.0.1:8000/api/v1`  
**Authentication:** Bearer Token (Laravel Sanctum)  
**Response Format:** JSON

---

## Authentication Flow

### 1. Register New Account
**Endpoint:** `POST /register`  
**Authentication:** Not Required  
**Description:** Creates a new customer account. Uses IC number to link with existing customer records.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+60123456789",
  "ic_number": "901234-12-5678",
  "address": "123 Main Street, Sandakan",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+60123456789",
      "ic_number": "901234125678",
      "address": "123 Main Street, Sandakan"
    },
    "token": "1|AbCdEfGh...",
    "token_type": "Bearer"
  }
}
```

**Error Responses:**
- `422` Validation failed
- `409` Email already exists
- `500` Server error

**Notes:**
- IC number is used to match existing customer records
- If a customer with the same IC exists, they will be linked
- Email must be unique in the users table
- Password must meet Laravel's default requirements

---

### 2. Login
**Endpoint:** `POST /login`  
**Authentication:** Not Required

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+60123456789",
      "ic_number": "901234125678",
      "address": "123 Main Street, Sandakan"
    },
    "token": "2|XyZaBcDe...",
    "token_type": "Bearer"
  }
}
```

**Error Responses:**
- `401` Invalid credentials
- `403` Account type cannot login via mobile
- `422` Validation failed

---

### 3. Logout
**Endpoint:** `POST /logout`  
**Authentication:** Required  
**Headers:** `Authorization: Bearer {token}`

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### 4. Get Current User
**Endpoint:** `GET /user`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "customer"
    },
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+60123456789",
      "ic_number": "901234125678",
      "address": "123 Main Street, Sandakan"
    }
  }
}
```

---

## Dashboard

### Get Dashboard Overview
**Endpoint:** `GET /dashboard`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "statistics": {
      "total_pets": 2,
      "total_bookings": 5,
      "upcoming_bookings": 1,
      "total_treatments": 8
    },
    "next_booking": {
      "id": 3,
      "pet": {
        "id": 1,
        "name": "Buddy",
        "species": "dog"
      },
      "booking_date": "2025-10-30",
      "booking_time": "14:00",
      "service_type": "Vaccination"
    },
    "recent_bookings": [
      {
        "id": 3,
        "pet": {
          "id": 1,
          "name": "Buddy",
          "species": "dog"
        },
        "booking_date": "2025-10-30",
        "booking_time": "14:00",
        "service_type": "Vaccination",
        "status": "upcoming"
      }
    ],
    "pets": [
      {
        "id": 1,
        "name": "Buddy",
        "species": "dog",
        "breed": "Golden Retriever",
        "age": 3,
        "treatment_count": 5,
        "last_treatment_date": "2025-10-20"
      }
    ]
  }
}
```

---

## Profile Management

### 1. Get Profile
**Endpoint:** `GET /profile`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "customer": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+60123456789",
      "ic_number": "901234125678",
      "address": "123 Main Street, Sandakan"
    },
    "stats": {
      "total_pets": 2,
      "total_bookings": 5
    }
  }
}
```

---

### 2. Update Profile
**Endpoint:** `PUT /profile`  
**Authentication:** Required

**Request Body:**
```json
{
  "name": "John Doe Updated",
  "phone": "+60129999999",
  "address": "456 New Street, Sandakan",
  "email": "newemail@example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe Updated",
      "email": "newemail@example.com"
    },
    "customer": {
      "id": 1,
      "name": "John Doe Updated",
      "email": "newemail@example.com",
      "phone": "+60129999999",
      "ic_number": "901234125678",
      "address": "456 New Street, Sandakan"
    }
  }
}
```

**Notes:**
- All fields are optional
- Email must be unique if updating

---

### 3. Update Password
**Endpoint:** `PUT /profile/password`  
**Authentication:** Required

**Request Body:**
```json
{
  "current_password": "OldPass123!",
  "password": "NewPass123!",
  "password_confirmation": "NewPass123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Password updated successfully"
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Current password is incorrect"
}
```

**Notes:**
- All other tokens will be revoked except current session

---

### 4. Delete Account
**Endpoint:** `DELETE /profile`  
**Authentication:** Required

**Request Body:**
```json
{
  "password": "SecurePass123!"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

**Notes:**
- Requires password confirmation
- User account deleted but customer record preserved
- All tokens are revoked

---

## Booking Management

### 1. Get All Bookings
**Endpoint:** `GET /bookings`  
**Authentication:** Required  
**Query Parameters:**
- `status` (optional): Filter by status (upcoming, completed, cancelled)

**Examples:**
- `GET /bookings` - All bookings
- `GET /bookings?status=upcoming` - Only upcoming

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "pet": {
        "id": 1,
        "name": "Buddy",
        "species": "dog"
      },
      "booking_date": "2025-10-30",
      "booking_time": "14:00",
      "service_type": "Vaccination",
      "status": "upcoming",
      "notes": "Annual vaccination",
      "created_at": "2025-10-28T10:00:00.000000Z"
    }
  ]
}
```

---

### 2. Create Booking
**Endpoint:** `POST /bookings`  
**Authentication:** Required

**Request Body:**
```json
{
  "pet_id": 1,
  "booking_date": "2025-11-05",
  "booking_time": "10:30",
  "service_type": "General Checkup",
  "notes": "Regular health checkup"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "id": 2,
    "pet": {
      "id": 1,
      "name": "Buddy",
      "species": "dog"
    },
    "booking_date": "2025-11-05",
    "booking_time": "10:30",
    "service_type": "General Checkup",
    "status": "upcoming",
    "notes": "Regular health checkup",
    "created_at": "2025-10-28T12:00:00.000000Z"
  }
}
```

**Validation Rules:**
- `pet_id`: Required, must belong to your pets
- `booking_date`: Required, must be today or future date
- `booking_time`: Required, format HH:MM (24-hour)
- `service_type`: Required, string
- `notes`: Optional

**Error Responses:**
- `403` Pet doesn't belong to you
- `422` Validation failed

---

### 3. Get Booking Details
**Endpoint:** `GET /bookings/{id}`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "pet": {
      "id": 1,
      "name": "Buddy",
      "species": "dog",
      "breed": "Golden Retriever",
      "age": 3
    },
    "booking_date": "2025-10-30",
    "booking_time": "14:00",
    "service_type": "Vaccination",
    "status": "upcoming",
    "notes": "Annual vaccination",
    "created_at": "2025-10-28T10:00:00.000000Z",
    "updated_at": "2025-10-28T10:00:00.000000Z"
  }
}
```

---

### 4. Update Booking
**Endpoint:** `PUT /bookings/{id}`  
**Authentication:** Required

**Request Body:**
```json
{
  "booking_date": "2025-11-06",
  "booking_time": "15:00",
  "service_type": "Vaccination + Checkup",
  "notes": "Updated appointment"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Booking updated successfully",
  "data": {
    "id": 1,
    "pet": {
      "id": 1,
      "name": "Buddy"
    },
    "booking_date": "2025-11-06",
    "booking_time": "15:00",
    "service_type": "Vaccination + Checkup",
    "status": "upcoming",
    "notes": "Updated appointment"
  }
}
```

**Notes:**
- Only upcoming bookings can be updated
- All fields are optional

---

### 5. Cancel Booking
**Endpoint:** `DELETE /bookings/{id}`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "Booking cancelled successfully"
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Only upcoming bookings can be cancelled"
}
```

---

## Pet Management

### 1. Get All Pets
**Endpoint:** `GET /pets`  
**Authentication:** Required

**Success Response (200):**
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

### 2. Create Pet
**Endpoint:** `POST /pets`  
**Authentication:** Required

**Request Body:**
```json
{
  "name": "Max",
  "species": "cat",
  "breed": "Persian",
  "age": 2,
  "gender": "male",
  "color": "White",
  "weight": 4.5,
  "microchip_id": "987654321",
  "medical_notes": "No known allergies"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Pet added successfully",
  "data": {
    "id": 2,
    "name": "Max",
    "species": "cat",
    "breed": "Persian",
    "age": 2,
    "gender": "male",
    "color": "White",
    "weight": 4.5,
    "microchip_id": "987654321",
    "medical_notes": "No known allergies",
    "created_at": "2025-10-28T12:00:00.000000Z"
  }
}
```

**Validation Rules:**
- `name`: Required, string, max 255
- `species`: Required, one of: dog, cat, bird, rabbit, other
- `breed`: Optional, string
- `age`: Optional, integer, min 0
- `gender`: Optional, one of: male, female
- `color`: Optional, string
- `weight`: Optional, numeric, min 0
- `microchip_id`: Optional, string
- `medical_notes`: Optional, string, max 1000

---

### 3. Get Pet Details
**Endpoint:** `GET /pets/{id}`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
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
      "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=1000",
      "issued_date": "2025-10-27"
    },
    "owner": {
      "id": 1,
      "name": "John Doe",
      "phone": "+60123456789"
    },
    "created_at": "2025-01-15T08:00:00.000000Z",
    "updated_at": "2025-10-20T10:00:00.000000Z"
  }
}
```

---

### 4. Update Pet
**Endpoint:** `PUT /pets/{id}`  
**Authentication:** Required

**Request Body:**
```json
{
  "name": "Buddy Updated",
  "age": 4,
  "weight": 32.0,
  "medical_notes": "Allergic to chicken and beef"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Pet updated successfully",
  "data": {
    "id": 1,
    "name": "Buddy Updated",
    "species": "dog",
    "breed": "Golden Retriever",
    "age": 4,
    "gender": "male",
    "color": "Golden",
    "weight": 32.0,
    "microchip_id": "123456789",
    "medical_notes": "Allergic to chicken and beef"
  }
}
```

**Notes:**
- All fields are optional
- Same validation rules as create

---

### 5. Delete Pet
**Endpoint:** `DELETE /pets/{id}`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "message": "Pet deleted successfully"
}
```

---

## Pet Tag Assignment

### 1. Scan and Assign Tag
**Endpoint:** `POST /pets/scan-tag`  
**Authentication:** Required  
**Description:** Scans a QR code and assigns the tag to a pet.

**Request Body:**
```json
{
  "tag_code": "1000",
  "pet_id": 1
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Tag assigned successfully",
  "data": {
    "pet": {
      "id": 1,
      "name": "Buddy",
      "species": "dog"
    },
    "tag": {
      "id": 1,
      "tag_code": "1000",
      "status": "active",
      "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=1000",
      "issued_date": "2025-10-27"
    }
  }
}
```

**Error Responses:**
- `403` Pet doesn't belong to you
- `404` Invalid tag code
- `422` Tag already assigned or not active

---

### 2. Assign Tag to Pet (Alternative)
**Endpoint:** `POST /pets/{id}/assign-tag`  
**Authentication:** Required

**Request Body:**
```json
{
  "tag_code": "1000"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Tag assigned successfully",
  "data": {
    "tag": {
      "id": 1,
      "tag_code": "1000",
      "status": "active",
      "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=1000"
    }
  }
}
```

---

## Medical Treatment Records

### 1. Get Pet Treatment History
**Endpoint:** `GET /pets/{id}/treatments`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "pet": {
      "id": 1,
      "name": "Buddy",
      "species": "dog"
    },
    "treatments": [
      {
        "id": 5,
        "treatment_date": "2025-10-20",
        "treatment_location": "clinic",
        "diagnosis": "Routine vaccination",
        "disease": "Preventive",
        "medicine_prescribed": "Rabies vaccine",
        "notes": "Annual vaccination completed",
        "collaborator": {
          "id": 1,
          "name": "CLINIC SECOND",
          "clinic_name": "CLINIC SECOND Clinic"
        },
        "created_at": "2025-10-20T14:00:00.000000Z"
      }
    ]
  }
}
```

---

### 2. Get Treatment Details
**Endpoint:** `GET /pets/{petId}/treatments/{treatmentId}`  
**Authentication:** Required

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 5,
    "pet": {
      "id": 1,
      "name": "Buddy",
      "species": "dog",
      "breed": "Golden Retriever",
      "age": 3
    },
    "treatment_date": "2025-10-20",
    "treatment_location": "clinic",
    "diagnosis": "Routine vaccination",
    "disease": "Preventive",
    "medicine_prescribed": "Rabies vaccine",
    "dosage": "1ml",
    "notes": "Annual vaccination completed",
    "collaborator": {
      "id": 1,
      "name": "CLINIC SECOND",
      "clinic_name": "CLINIC SECOND Clinic",
      "phone": "+60165305733",
      "address": "Taman Mutiara T102, Lorong Mutiara 2A"
    },
    "created_at": "2025-10-20T14:00:00.000000Z",
    "updated_at": "2025-10-20T14:00:00.000000Z"
  }
}
```

---

## Error Response Format

All error responses follow this structure:

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field_name": ["Specific error message"]
  }
}
```

**Common HTTP Status Codes:**
- `200` OK - Request successful
- `201` Created - Resource created successfully
- `401` Unauthorized - Invalid or missing token
- `403` Forbidden - Access denied
- `404` Not Found - Resource not found
- `422` Unprocessable Entity - Validation failed
- `500` Internal Server Error - Server error

---

## Authentication Headers

All protected endpoints require this header:

```
Authorization: Bearer {your_token_here}
```

**Example:**
```
Authorization: Bearer 1|AbCdEfGhIjKlMnOpQrStUvWxYz123456
```

---

## Important Notes for Mobile Development

### 1. Token Management
- Store the token securely (encrypted SharedPreferences/Keychain)
- Include token in all authenticated requests
- Token is revoked on logout
- Password change revokes all other tokens

### 2. IC Number Matching
- IC number is the primary identifier for linking existing customers
- Always uppercase and strip dashes before sending
- Format: 901234-12-5678 → 901234125678

### 3. Pet Species
Valid values: `dog`, `cat`, `bird`, `rabbit`, `other`

### 4. Booking Status
Valid values: `upcoming`, `completed`, `cancelled`

### 5. Pet Gender
Valid values: `male`, `female`

### 6. Treatment Location
Valid values: `clinic`, `home`

### 7. Date/Time Formats
- Date: `YYYY-MM-DD` (e.g., 2025-10-30)
- Time: `HH:MM` 24-hour format (e.g., 14:00)
- DateTime: ISO 8601 format in responses

### 8. QR Code Scanning
- QR codes contain only the tag code (e.g., "1000")
- Use `POST /pets/scan-tag` with scanned code
- Tag must be active and unassigned

### 9. Image/File Upload
Currently not implemented. Pet photos and document uploads can be added later if needed.

### 10. Pagination
Currently not implemented. All lists return complete datasets. Can be added if needed for large datasets.

---

## Testing the API

### Using cURL:

**Register:**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+60123456789",
    "ic_number": "901234-12-5678",
    "address": "Test Address",
    "password": "Password123!",
    "password_confirmation": "Password123!"
  }'
```

**Login:**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

**Get Dashboard (with token):**
```bash
curl -X GET http://127.0.0.1:8000/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Version History

### v1.0 (Current)
- Authentication (register, login, logout)
- Profile management
- Booking management
- Pet management
- Pet tag assignment via QR scanning
- Medical treatment records viewing
- Dashboard overview

---

## Support

For API issues or questions during mobile development:
1. Check this documentation first
2. Verify request format and headers
3. Check error responses for specific issues
4. Ensure IC number format is correct
5. Verify token is valid and not expired

---

**Last Updated:** October 28, 2025  
**API Version:** 1.0  
**System:** VETech DVS Sandakan
