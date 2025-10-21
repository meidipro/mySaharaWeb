import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../constants/app_colors.dart';

class BmiChart extends StatelessWidget {
  final double bmi;
  final String category;

  const BmiChart({
    super.key,
    required this.bmi,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI Chart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 40,
                  minY: 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text = '';
                          switch (value.toInt()) {
                            case 0:
                              text = 'Under';
                              break;
                            case 1:
                              text = 'Normal';
                              break;
                            case 2:
                              text = 'Over';
                              break;
                            case 3:
                              text = 'Obese';
                              break;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    // Underweight range (< 18.5)
                    _buildBarGroup(
                      0,
                      18.5,
                      AppColors.warning,
                      category == 'Underweight' ? bmi : null,
                    ),
                    // Normal range (18.5 - 24.9)
                    _buildBarGroup(
                      1,
                      24.9,
                      AppColors.success,
                      category == 'Normal' || category == 'Normal weight'
                          ? bmi
                          : null,
                    ),
                    // Overweight range (25 - 29.9)
                    _buildBarGroup(
                      2,
                      29.9,
                      AppColors.healthOrange,
                      category == 'Overweight' ? bmi : null,
                    ),
                    // Obese range (>= 30)
                    _buildBarGroup(
                      3,
                      35,
                      AppColors.error,
                      category == 'Obese' ? bmi : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
      int x, double toY, Color color, double? userBmi) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: toY,
          color: color.withOpacity(0.3),
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: false,
          ),
          rodStackItems: userBmi != null
              ? [
                  BarChartRodStackItem(0, userBmi, color),
                  BarChartRodStackItem(userBmi, toY, color.withOpacity(0.3)),
                ]
              : [],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('< 18.5', AppColors.warning),
        _buildLegendItem('18.5-25', AppColors.success),
        _buildLegendItem('25-30', AppColors.healthOrange),
        _buildLegendItem('≥ 30', AppColors.error),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
