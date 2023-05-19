<?php
class DbConn
{
    private $db;
    private $host;
    private $email;
    private $password;
    private $conn;

    function __construct($db, $host, $email, $password) {
        //get credentials
        $this->db = $db;
        $this->host = $host;
        $this->email = $email;
        $this->password = $password;
        //establish connection
        $this->connect();
    }

    //establish connection
    private function connect() {
        $this->conn = @new mysqli($this->host, $this->email, $this->password, $this->db, '3306');
        if ($this->conn->connect_errno) {
            //echo '<script type="text/javascript">alert("Usuário não existe"); window.location.href = "login.html";</script>';
            die("O Utilizador não existe!");
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
