<?php

class Database {
    // Database credentials
    private $host = "localhost";
    private $db_name = "seijaku_pilates";
    private $username = "root";
    private $password = "";
    private $charset = "utf8mb4";
    
    public $conn;
    
    // Get database connection
    public function getConnection() {
        $this->conn = null;
        
        try {
            $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=" . $this->charset;
            
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
            ];
            
            $this->conn = new PDO($dsn, $this->username, $this->password, $options);
            
        } catch(PDOException $exception) {
            error_log("Connection error: " . $exception->getMessage());
            throw new Exception("Database connection failed");
        }
        
        return $this->conn;
    }
    
    // Test connection
    public function testConnection() {
        try {
            $conn = $this->getConnection();
            return true;
        } catch(Exception $e) {
            return false;
        }
    }
    
    // Get database info
    public function getDatabaseInfo() {
        try {
            $conn = $this->getConnection();
            $stmt = $conn->query("SELECT DATABASE() as db_name, VERSION() as version");
            return $stmt->fetch();
        } catch(Exception $e) {
            return null;
        }
    }
}
?>