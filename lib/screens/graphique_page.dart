import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphiquePage extends StatelessWidget {
  const GraphiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistiques agricoles"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const Text(
              "Evolution de l'humidité (%)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      spots: const [
                        FlSpot(1, 30),
                        FlSpot(2, 35),
                        FlSpot(3, 40),
                        FlSpot(4, 32),
                        FlSpot(5, 55),
                        FlSpot(6, 60),
                        FlSpot(7, 50),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                ),
                title: Text("Humidité moyenne"),
                subtitle: Text("43%"),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  Icons.thermostat,
                  color: Colors.orange,
                ),
                title: Text("Température moyenne"),
                subtitle: Text("28°C"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}