import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/body_measurement.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/premium_theme.dart';

class ProgressPage extends ConsumerStatefulWidget {
  final String? clientId;
  final String? clientName;
  final bool isTrainerView;
  
  const ProgressPage({
    super.key,
    this.clientId,
    this.clientName,
    this.isTrainerView = false,
  });

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  List<BodyMeasurement> _measurements = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedChartIndex;
  int? _expandedMeasurementIndex;
  
  final List<Map<String, dynamic>> _metrics = [
    {'key': 'weight', 'label': 'Вес', 'unit': 'кг', 'icon': Icons.monitor_weight},
    {'key': 'neck', 'label': 'Шея', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'chest', 'label': 'Грудь', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'waist', 'label': 'Талия', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'hips', 'label': 'Бёдра', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'bicepsLeft', 'label': 'Бицепс (левый)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'bicepsRight', 'label': 'Бицепс (правый)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'thighsLeft', 'label': 'Бедро (левое)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'thighsRight', 'label': 'Бедро (правое)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'calvesLeft', 'label': 'Икры (левые)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'calvesRight', 'label': 'Икры (правые)', 'unit': 'см', 'icon': Icons.straighten},
    {'key': 'bodyFat', 'label': 'Жир', 'unit': '%', 'icon': Icons.percent},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = widget.clientId ?? await _getCurrentUserId();
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('body_measurements')
          .select('*')
          .eq('user_id', userId)
          .order('date', ascending: true);
      
      setState(() {
        _measurements = (response as List).map((json) => BodyMeasurement.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      double? value;
      switch (metric) {
        case 'weight': value = m.weight; break;
        case 'neck': value = m.neck; break;
        case 'chest': value = m.chest; break;
        case 'waist': value = m.waist; break;
        case 'hips': value = m.hips; break;
        case 'bicepsLeft': value = m.bicepsLeft; break;
        case 'bicepsRight': value = m.bicepsRight; break;
        case 'thighsLeft': value = m.thighsLeft; break;
        case 'thighsRight': value = m.thighsRight; break;
        case 'calvesLeft': value = m.calvesLeft; break;
        case 'calvesRight': value = m.calvesRight; break;
        case 'bodyFat': value = m.bodyFat; break;
      }
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clientName != null 
        ? 'Прогресс: ${widget.clientName}' 
        : 'Мой прогресс';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!widget.isTrainerView)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: () {
                context.push('/add-measurement');
              },
              tooltip: 'Добавить замер',
            ),
        ],
      ),
      body: PremiumBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _error != null
                ? ErrorView(message: _error!, onRetry: _loadData)
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
                            if (!widget.isTrainerView) ...[
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
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Графики (аккордеон)
                            _buildChartsAccordion(),
                            const SizedBox(height: 24),
                            // Замеры (аккордеон)
                            _buildMeasurementsAccordion(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildChartsAccordion() {
    return Column(
      children: [
        for (int i = 0; i < _metrics.length; i++)
          _buildChartTile(_metrics[i], i, _metrics.length),
      ],
    );
  }

  Widget _buildChartTile(Map<String, dynamic> metric, int index, int total) {
    final isExpanded = _expandedChartIndex == index;
    final isFirst = index == 0;
    final isLast = index == total - 1;
    final spots = _getChartData(metric['key']);
    
    if (spots.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          topRight: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
        ),
        border: Border(
          bottom: !isLast
              ? BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_expandedChartIndex == index) {
                  _expandedChartIndex = null;
                } else {
                  _expandedChartIndex = index;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  Icon(metric['icon'], color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metric['label'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'график',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1115), Color(0xFF1A1D24)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: SizedBox(
                height: 200,
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
                                  _measurements[index].date,
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
                        spots: spots,
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
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsAccordion() {
    return Column(
      children: [
        for (int i = 0; i < _measurements.length; i++)
          _buildMeasurementTile(_measurements[i], i, _measurements.length),
      ],
    );
  }

  Widget _buildMeasurementTile(BodyMeasurement measurement, int index, int total) {
    final isExpanded = _expandedMeasurementIndex == index;
    final isFirst = index == 0;
    final isLast = index == total - 1;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          topRight: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
        ),
        border: Border(
          bottom: !isLast
              ? BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_expandedMeasurementIndex == index) {
                  _expandedMeasurementIndex = null;
                } else {
                  _expandedMeasurementIndex = index;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Helpers.formatDate(measurement.date),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1115), Color(0xFF1A1D24)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Column(
                children: [
                  if (measurement.weight != null)
                    _buildMeasurementRow('Вес', '${measurement.weight} кг'),
                  if (measurement.neck != null)
                    _buildMeasurementRow('Шея', '${measurement.neck} см'),
                  if (measurement.chest != null)
                    _buildMeasurementRow('Грудь', '${measurement.chest} см'),
                  if (measurement.waist != null)
                    _buildMeasurementRow('Талия', '${measurement.waist} см'),
                  if (measurement.hips != null)
                    _buildMeasurementRow('Бёдра', '${measurement.hips} см'),
                  if (measurement.bicepsLeft != null)
                    _buildMeasurementRow('Бицепс (левый)', '${measurement.bicepsLeft} см'),
                  if (measurement.bicepsRight != null)
                    _buildMeasurementRow('Бицепс (правый)', '${measurement.bicepsRight} см'),
                  if (measurement.thighsLeft != null)
                    _buildMeasurementRow('Бедро (левое)', '${measurement.thighsLeft} см'),
                  if (measurement.thighsRight != null)
                    _buildMeasurementRow('Бедро (правое)', '${measurement.thighsRight} см'),
                  if (measurement.calvesLeft != null)
                    _buildMeasurementRow('Икры (левые)', '${measurement.calvesLeft} см'),
                  if (measurement.calvesRight != null)
                    _buildMeasurementRow('Икры (правые)', '${measurement.calvesRight} см'),
                  if (measurement.bodyFat != null)
                    _buildMeasurementRow('Жир', '${measurement.bodyFat} %'),
                  if (measurement.notes != null)
                    _buildMeasurementRow('Заметки', measurement.notes!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}