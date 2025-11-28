<?php

class JWT {
    private $secret_key = "seijaku_pilates_secret_key_2024"; // Change this in production
    private $algorithm = 'HS256';
    
    // Encode JWT token
    public function encode($data) {
        $header = $this->base64UrlEncode(json_encode([
            'typ' => 'JWT',
            'alg' => $this->algorithm
        ]));
        
        $payload = $this->base64UrlEncode(json_encode($data));
        
        $signature = $this->base64UrlEncode(
            hash_hmac('sha256', "$header.$payload", $this->secret_key, true)
        );
        
        return "$header.$payload.$signature";
    }
    
    // Decode JWT token
    public function decode($token) {
        $parts = explode('.', $token);
        
        if (count($parts) !== 3) {
            return false;
        }
        
        list($header, $payload, $signature) = $parts;
        
        // Verify signature
        $expected_signature = $this->base64UrlEncode(
            hash_hmac('sha256', "$header.$payload", $this->secret_key, true)
        );
        
        if ($signature !== $expected_signature) {
            return false;
        }
        
        // Decode payload
        $decoded_payload = json_decode($this->base64UrlDecode($payload));
        
        // Check if token is expired
        if (isset($decoded_payload->exp) && $decoded_payload->exp < time()) {
            return false;
        }
        
        return $decoded_payload;
    }
    
    // Verify token
    public function verify($token) {
        return $this->decode($token) !== false;
    }
    
    // Get user ID from token
    public function getUserId($token) {
        $decoded = $this->decode($token);
        return $decoded ? $decoded->user_id : null;
    }
    
    // Base64 URL encode
    private function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    // Base64 URL decode
    private function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }
    
    // Get token from authorization header
    public function getTokenFromHeader() {
        $headers = getallheaders();
        
        if (isset($headers['Authorization'])) {
            $auth_header = $headers['Authorization'];
            
            if (preg_match('/Bearer\s+(.*)$/i', $auth_header, $matches)) {
                return $matches[1];
            }
        }
        
        return null;
    }
    
    // Validate and get user from token
    public function validateToken() {
        $token = $this->getTokenFromHeader();
        
        if (!$token) {
            return false;
        }
        
        $decoded = $this->decode($token);
        
        if (!$decoded) {
            return false;
        }
        
        return $decoded;
    }
}
?>