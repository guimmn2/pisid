import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:async';
import 'dart:math';

class Readings2 extends StatelessWidget {
  const Readings2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Readings T2';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(appTitle),
      ),
      body: const ReadingsMain(),
    );
  }
}

class ReadingsMain extends StatefulWidget {
  const ReadingsMain({Key? key}) : super(key: key);

  @override
  ReadingsMainState createState() {
    return ReadingsMainState();
  }
}

class ReadingsMainState extends State<ReadingsMain> {
  final List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  late Timer timer;
  var readingsValues = <double>[];
  var readingsTimes = <double>[];
  var minY = 10.0;
  var maxY = 30.0;
  double timeLimit = 3;

  @override
  void initState() {
    const interval = Duration(seconds:1);
    timer = Timer.periodic(interval, (Timer t) => getReadings());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          margin: EdgeInsets.all(10),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: timeLimit,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  margin: 5,
                ),
                leftTitles: SideTitles(
                  showTitles: true,
                  margin: 5,
                  reservedSize: 30,
                ),
                rightTitles: SideTitles(
                  showTitles: false,
                ),
                topTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: listReadings(),
                  dotData: FlDotData(show: false),
                  isCurved: false,
                  colors: gradientColors,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    colors: gradientColors
                        .map((color) => color.withOpacity(0.2))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: ElevatedButton(
            onPressed: () {
              readingsValues.clear();
              readingsTimes.clear();
              minY = 10.0;
              maxY = 30.0;
              Navigator.pop(context);
            },
            child: const Text('Alerts'),
          ),
        ));
  }

  getReadings() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');
    String? ip = prefs.getString('ip');
    String? port = prefs.getString('port');

    String readingsURL = "http://" + ip! + ":" + port! + "/scripts/getTemp2.php";
    var response = await http
        .post(Uri.parse(readingsURL), body: {'username': username, 'password': password});

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      var data = jsonData["readings"];
      setState(() {
        readingsValues.clear();
        readingsTimes.clear();
        minY = 10.0;
        maxY = 30.0;
        if (data != null && data.length > 0) {
          for (var reading in data) {
            DateTime readingTime = DateTime.parse(reading["Hora"].toString());
            DateTime currentTime = DateTime.now();
            double timeDiff = double.parse((currentTime.difference(readingTime).inSeconds/60).toStringAsFixed(2));
            print("CURRENT: " + currentTime.toString());
            print("READING: " + readingTime.toString());
            print("DIFF: " + timeDiff.toString());
            if (timeDiff>0.0 && timeDiff<timeLimit && !readingsTimes.contains(timeDiff)) {
              var value = double.parse(reading["Leitura"].toString());
              print("VALUE: " + value.toString());
              readingsTimes.add(timeDiff);
              readingsValues.add(value);
            }
          }
          if (readingsValues.isNotEmpty) {
            minY = readingsValues.reduce(min)-1;
            maxY = readingsValues.reduce(max)+1;
          }
        }
      });
    }
    print(" ");
  }

  listReadings() {
    var spots = <FlSpot>[];
    for (var i=0; i<readingsValues.length;i++) {
      spots.add(FlSpot(readingsTimes.elementAt(i), readingsValues.elementAt(i)));
    }
    return spots;
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

}
