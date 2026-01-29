import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Progress Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _xpVelocityGraph(),
            const SizedBox(height: 24),
            _monthlyActivityGrid(),
          ],
        ),
      ),
    );
  }

  /// ================= XP VELOCITY GRAPH =================
  Widget _xpVelocityGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "XP VELOCITY",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 2),
                      FlSpot(3, 2.8),
                      FlSpot(4, 3.5),
                      FlSpot(5, 4.2),
                    ],
                    isCurved: true,
                    color: Colors.greenAccent,
                    barWidth: 4,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.greenAccent.withOpacity(0.2),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// ================= MONTH WISE ACTIVITY =================
  Widget _monthlyActivityGrid() {
    final months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];

    final activeMonths = [1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ACTIVITY FORGE",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final isActive = activeMonths[index] == 1;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.greenAccent
                          : Colors.greenAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.8),
                          blurRadius: 8,
                        )
                      ]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    months[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  /// ================= COMMON CARD STYLE =================
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF111A2E),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
        )
      ],
    );
  }
}