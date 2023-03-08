## A Experiência
O objectivo da experiência é descobrir que odores estimulam mais os ratos dada a administração de uma certa substância nos mesmos.
Para isto é necessário registar todas as experiências que são efectuadas. Uma experiência consiste em libertar ratos num labirinto, cujos corredores ligam apenas duas salas, e averiguar os seus movimentos pelas salas.

## A Registar (em tempo real)
- Todas as experiências, de forma sequencial (exp1, exp2, ..., expn). O intervalo entre as experiências pode ser desde minutos até dias.
- As entradas e as saídas das salas pelos ratos (só podem entrar/saír um de cada vez)

## A Registar/Definir (pelo cliente)
- Substâncias administradas nos ratos
- Odores de cada sala
- Quantidade de ratos
- Temperaturas a partir das quais a experiência deve ser abortada (<b>Y</b>: verificar equipamentos, <b>Z</b>: abortar)
- <b>X</b>: O tempo em segundos sem que nenhum rato entre ou saia de uma sala
<b> Isto será definido pelo cliente nos formulários dados pelos professores. Contudo, a parte do login e a criação/alteração propriamente dita das experiências (a escrita em BD), será da responsabilidade do grupo.</b>

## Critérios de Término
A experiência pode terminar se:
- Passaram <b>X</b> segundos sem que nenhum rato tenha entrado ou saído de alguma sala
- Temperatura diferente de um valor pré-determinado
- O número de ratos de uma sala ser maior ou igual que <b>Y</b>

<b>Em qualquer uma destas situações o investigador recebe um aviso que o alerta para abrir as portas. Contudo, no caso do 3º critério, devem os técnicos primeiro averiguar se existe algum problema com, por exemplo, aparelhos de ar condicionado e, se sim, proceder ao arranjo dos mesmos, em vez de abortar a experiência.</b>

## Android
Cada investigador deverá poder ver, em tempo real, a experiência. Sendo que em caso de falha desse serviço deve ter uma forma de reiniciar o processo (tem a ver com as leituras em tempo real MongoDB -> MySQL).

