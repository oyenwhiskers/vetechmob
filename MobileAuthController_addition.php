// Add this method to your MobileAuthController class

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
