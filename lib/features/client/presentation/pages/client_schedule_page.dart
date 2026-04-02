import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';

class ClientSchedulePage extends ConsumerStatefulWidget {
  const ClientSchedulePage({super.key});

  @override
  ConsumerState<ClientSchedulePage> createState() => _ClientSchedulePageState();
}

class _ClientSchedulePageState extends ConsumerState<ClientSchedulePage> {
  final List<String> _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  final List<int> _hours = List.generate(18, (index) => index + 6);
  
  late PageController _pageController;
  int _currentPageIndex = DateTime.now().weekday - 1;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadSchedule();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final startOfWeek = _getStartOfWeek(_selectedDate);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      
      // Клиент видит только свои тренировки
      final response = await Supabase.instance.client
          .from('schedule_slots')
          .select('*')
          .eq('client_id', userId)
          .gte('start_time', startOfWeek.toIso8601String())
          .lt('start_time', endOfWeek.toIso8601String())
          .order('start_time', ascending: true);
      
      setState(() {
        _slots = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading schedule: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  DateTime _getStartOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String getWeekRange() {
    final start = _getStartOfWeek(_selectedDate);
    final end = start.add(const Duration(days: 6));
    return '${start.day}.${start.month} - ${end.day}.${end.month}';
  }

  Future<void> _selectDate(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _showCalendar = false;
    });
    _loadSchedule();
  }

  void _openCalendar() {
    setState(() => _showCalendar = true);
  }

  List<Map<String, dynamic>> _getSlotsForDay(DateTime date) {
    return _slots.where((slot) {
      final slotDate = DateTime.parse(slot['start_time']);
      return slotDate.year == date.year &&
             slotDate.month == date.month &&
             slotDate.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _getStartOfWeek(_selectedDate);
    final today = DateTime.now();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Моё расписание',
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
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.green, size: 20),
            onPressed: _openCalendar,
          ),
        ],
      ),
      body: PremiumBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : Column(
                children: [
                  if (_showCalendar)
                    Container(
                      color: const Color(0xFF0F1115),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                onPressed: () => setState(() => _showCalendar = false),
                              ),
                            ],
                          ),
                          _buildCalendar(),
                        ],
                      ),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                              _loadSchedule();
                            });
                          },
                          child: const Icon(Icons.chevron_left, color: Colors.green, size: 24),
                        ),
                        Text(
                          getWeekRange(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 7));
                              _loadSchedule();
                            });
                          },
                          child: const Icon(Icons.chevron_right, color: Colors.green, size: 24),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: List.generate(7, (index) {
                        final date = weekStart.add(Duration(days: index));
                        final isToday = date.year == today.year &&
                                       date.month == today.month &&
                                       date.day == today.day;
                        final isSelected = date.year == _selectedDate.year &&
                                          date.month == _selectedDate.month &&
                                          date.day == _selectedDate.day;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadSchedule();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green.withOpacity(0.15) : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday ? Border.all(color: Colors.green, width: 0.5) : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _weekDays[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isToday ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.green : (isToday ? Colors.green : Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  const Divider(height: 8, color: Colors.white12),
                  
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: _hours.length,
                      itemBuilder: (context, hourIndex) {
                        final hour = _hours[hourIndex];
                        final slotsForHour = _getSlotsForDay(_selectedDate)
                            .where((slot) => DateTime.parse(slot['start_time']).hour == hour)
                            .toList();
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Text(
                                  '$hour:00',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                              Expanded(
                                child: slotsForHour.isEmpty
                                    ? const SizedBox(height: 36)
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: slotsForHour.map((slot) {
                                            final workoutTitle = slot['workout_title'] ?? 'Тренировка';
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                workoutTitle,
                                                style: const TextStyle(fontSize: 12, color: Colors.green),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, _) => _selectDate(selectedDay),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          weekendTextStyle: const TextStyle(color: Colors.grey),
          defaultTextStyle: const TextStyle(color: Colors.white),
          todayTextStyle: const TextStyle(color: Colors.green),
          selectedTextStyle: const TextStyle(color: Colors.white),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.green),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.grey),
          weekendStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}