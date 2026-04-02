import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../progress/presentation/pages/add_measurement_page.dart';
import '../../../progress/presentation/pages/add_progress_photo_page.dart';

class ClientProgressPage extends ConsumerStatefulWidget {
  const ClientProgressPage({super.key});

  @override
  ConsumerState<ClientProgressPage> createState() => _ClientProgressPageState();
}

class _ClientProgressPageState extends ConsumerState<ClientProgressPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _measurements = [];
  List<Map<String, dynamic>> _workoutWeights = [];
  String _selectedMetric = 'weight';

  final Map<String, String> _metrics = {
    'weight': 'Вес',
    'chest': 'Грудь',
    'waist': 'Талия',
    'hips': 'Бёдра',
    'biceps': 'Бицепс',
    'thighs': 'Бедро',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('body_measurements')
          .select('*')
          .eq('user_id', userId)
          .order('date', ascending: true);
      
      setState(() {
        _measurements = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  List<FlSpot> _getChartData(String metric) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _measurements.length; i++) {
      final m = _measurements[i];
      if (m[metric] != null) {
        spots.add(FlSpot(i.toDouble(), (m[metric] as num).toDouble()));
      }
    }
    return spots;
  }

  double _getChange(String metric) {
    if (_measurements.length < 2) return 0;
    final first = _measurements.first[metric];
    final last = _measurements.last[metric];
    if (first == null || last == null) return 0;
    return (last as num).toDouble() - (first as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Мой прогресс',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.green),
            onSelected: (value) {
              if (value == 'measurement') {
                context.push('/add-measurement');
              } else if (value == 'photo') {
                context.push('/add-progress-photo');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'measurement',
                child: Row(
                  children: [
                    Icon(Icons.monitor_weight, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Добавить замер'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'photo',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Добавить фото'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PremiumBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _measurements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 80,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет данных о прогрессе',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте первый замер',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => context.push('/add-measurement'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'Добавить замер',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Селектор метрики
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _metrics.entries.map((entry) {
                              final isSelected = _selectedMetric == entry.key;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMetric = entry.key;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? Colors.green : Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.green : Colors.grey,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // График
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _metrics[_selectedMetric] ?? _selectedMetric,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${_getChange(_selectedMetric).toStringAsFixed(1)} ${_selectedMetric == 'weight' ? 'кг' : 'см'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getChange(_selectedMetric) < 0 
                                          ? Colors.green 
                                          : (_getChange(_selectedMetric) > 0 ? Colors.red : Colors.grey),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 250,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.white.withOpacity(0.1),
                                          strokeWidth: 0.5,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '${value.toInt()}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            );
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 && index < _measurements.length) {
                                              return Text(
                                                Helpers.formatDate(
                                                  DateTime.parse(_measurements[index]['date']),
                                                  pattern: 'dd.MM',
                                                ),
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _getChartData(_selectedMetric),
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.green,
                                              strokeWidth: 0,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Последние замеры
                        const Text(
                          'Последние замеры',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._measurements.reversed.take(5).map((m) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Helpers.formatDate(DateTime.parse(m['date'])),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    if (m['weight'] != null)
                                      _buildMetricChip('Вес', '${m['weight']} кг'),
                                    if (m['chest'] != null)
                                      _buildMetricChip('Грудь', '${m['chest']} см'),
                                    if (m['waist'] != null)
                                      _buildMetricChip('Талия', '${m['waist']} см'),
                                    if (m['hips'] != null)
                                      _buildMetricChip('Бёдра', '${m['hips']} см'),
                                    if (m['biceps'] != null)
                                      _buildMetricChip('Бицепс', '${m['biceps']} см'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: Colors.green),
      ),
    );
  }
}