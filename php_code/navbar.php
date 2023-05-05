<?php
//include('utils/init.php');
//session_start();

if (isset($_SESSION['role']) && $_SESSION['role'] == INVESTIGATOR) {
  // mostrar nav do investigador
  echo '
  <nav>
    <ul>
      <li><a href="experience_list.php">Experiences</a></li>
      <li><a href="ui_create_exp.php">Create Experience</a></li>
      <li style="float:right"><a class="logout-button" href="logout.php">Log out</a></li>
    </ul>
  </nav>
  '; 
} else {
  // mostrar nav do admin
  echo '
  <nav>
    <ul>
      <li><a href="experience_list.php">Experiences</a></li>
      <li><a href="register.html">Create Investigator</a></li>
      <li style="float:right"><a class="logout-button" href="logout.php">Log out</a></li>
    </ul>
  </nav>
  ';
}
?>