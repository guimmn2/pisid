import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

//import 'package:ionicons/ionicons.dart';
import 'dart:convert';
import 'dart:async';
import './readings1.dart';
import './readings2.dart';
import './readingsrooms.dart';



class Alerts extends StatelessWidget {
//class Alerts extends StatefulWidget {
  const Alerts({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    const appTitle = 'Alertas';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(appTitle),
      ),
      body: const AlertsMain(),
    );
  }
}

class AlertsMain extends StatefulWidget {
  const AlertsMain({Key? key}) : super(key: key);
  @override
  AlertsMainState createState() {
    return AlertsMainState();
  }
}

class AlertsMainState extends State<AlertsMain> {
  int currentIndex = 2;
  late Timer timer;
  DateTime selectedDate = DateTime.now();
  var mostRecentAlert = 0;

  var tableFields = ['mensagem', 'leitura', 'sala', 'sensor', 'tipo', 'hora', 'horaescrita'];
  var tableAlerts = <int, List<String>>{};

  int _selectedIndex = 0;
  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;

    });
    mostRecentAlert = 0;
    tableAlerts.clear();
    if (index==0) {
    Navigator.push(
      context,
          MaterialPageRoute(builder: (context) => const Readings1()),
    );}
    if (index==1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Readings2()),
      );}
    if (index==2) {
      //await new Future.delayed(const Duration(seconds : 1));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const readingsrooms()),

      );}
  }


  @override
  void initState() {
    const oneSec = Duration(seconds:1);
    timer = Timer.periodic(oneSec, (Timer t) => getAlerts());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
            //  ElevatedButton(
             //   onPressed: () {
              //    selectDate(context);
              //  },
              //  child: const Text("Choose Date"),
              //U),
             // Text(
             //     "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: listFields(),
                  rows: listAlerts(),
                ),
              ),
            ],
          ),
        ),

    bottomNavigationBar: BottomNavigationBar(
      //currentIndex:currentIndex,
      //onTap:(index)=>setState(() => currentIndex = index),
      iconSize:40,
      selectedFontSize:16,
      unselectedFontSize:16,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon:Icon(Icons.sensors),
          label:'Temp Sensor 1',
          backgroundColor:Colors.blue,
        ),
        BottomNavigationBarItem(
          icon:Icon(Icons.sensors),
          //<ion-icon name="thermometer-outline"></ion-icon>
          label:'Temp Sensor 2',
          backgroundColor:Colors.blue,
        ),
        BottomNavigationBarItem(
          icon:Icon(Icons.gesture),
          label:'Mouses/Room',
          backgroundColor:Colors.blue,
        ),
      ],
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        //iconSize: 40,
        onTap: _onItemTapped,
        elevation: 5
    )

    );
  }

  selectDate(BuildContext context) async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 2),
      lastDate: DateTime(selectedDate.year + 2),
    );
    if (selected != null && selected != selectedDate) {
      setState(() {
        selectedDate = selected;
      });
      getAlerts();
    }
  }

  getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? ip = prefs.getString('ip');
    String? port = prefs.getString('port');
    // String password = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";
    String? password = prefs.getString('password');
    String alertsURL = "http://" + ip! + ":" + port! + "/scripts/getAlerts.php";
    var response = await http
        .post(Uri.parse(alertsURL), body: {'username': username, 'password': password});
    if (response.statusCode == 200) {

      print("response " + response.body);
      var jsonData = json.decode(response.body);
      var alerts = jsonData["alerts"];
      if (alerts != null && alerts.length > 0) {
        setState(() {
          tableAlerts.clear();
          for (var i = 0; i < alerts.length; i++) {
            Map<String, dynamic> alert = alerts[i];
            int timeKey = int.parse(
                alert["hora"].toString().split(" ")[1].replaceAll(":", ""));
            var alertValues = <String>[];
            for (var key in alert.keys) {
              if (alert[key] == null) {
                alertValues.add("");
              } else {
                alertValues.add(alert[key]);
              }
            }
            tableAlerts[timeKey] = alertValues;
          }
        });
      }
    }
  }

  listAlerts() {
    var alertsList = <DataRow>[];
    if (tableAlerts.isEmpty) return alertsList;
    for (var i = tableAlerts.length - 1; i >= 0; i--) {
      var key = tableAlerts.keys.elementAt(i);
      var alertRow = <DataCell>[];
      tableAlerts[key]?.forEach((alertField) {
        if (key>mostRecentAlert) {
          alertRow.add(DataCell(Text(alertField, style: const TextStyle(color: Colors.blue))));
        } else {
          alertRow.add(DataCell(Text(alertField)));
        }
      });
      alertsList.add(DataRow(cells: alertRow));
    }
    mostRecentAlert = tableAlerts.keys.elementAt(tableAlerts.length-1);
    return alertsList;
  }

  listFields() {
    var fields = <DataColumn>[];
    for (var field in tableFields) {
      fields.add(DataColumn(label: Text(field)));
    }
    return fields;
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

}
