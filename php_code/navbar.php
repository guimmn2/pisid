<?php
//include('utils/init.php');
//session_start();

if (isset($_SESSION['role']) && $_SESSION['role'] == INVESTIGATOR) {
  // mostrar nav do investigador
  echo '
  <nav>
    <ul>
      <li><a href="experience_list.php">Experiências</a></li>
      <li><a href="ui_create_exp.php">Criar Experiência</a></li>
      <li style="float:right"><a class="logout-button" href="logout.php">Log out</a></li>
    </ul>
  </nav>
  '; 
} else {
  // mostrar nav do admin
  echo '
  <nav>
    <ul>
      <li><a href="experience_list.php">Experiências</a></li>
      <li><a href="register.html">Registar Utilizador</a></li>
      <li><a href="investigator_list.php">Lista de investigadores</a></li>
      <li style="float:right"><a class="logout-button" href="logout.php">Log out</a></li>
    </ul>
  </nav>
  ';
}
?>