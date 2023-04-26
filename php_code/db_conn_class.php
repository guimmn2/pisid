<?php
class DbConn
{
    private $db;
    private $host;
    private $email;
    private $password;
    private $conn;

    function __construct($db, $host, $email, $password) {
        //get creds
        $this->db = $db;
        $this->host = $host;
        $this->email = $email;
        $this->password = $password;
        //establish connection
        $this->connect();
    }

    //establish connection
    private function connect() {
        $this->conn = new mysqli($this->host, $this->email, $this->password, $this->db);
        if ($this->conn->connect_errno) {
            die('Could not connect to DB '. $this->conn->connect_error);
        }
    }

    //return connection object (mysqli)
    function getConn() {
        if (!isset($this->conn)) {
            $this->connect();
        }
        return $this->conn;
    }

}
?>