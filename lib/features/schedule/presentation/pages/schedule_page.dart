import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/schedule_viewmodel.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/theme/premium_theme.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  final List<String> _weekDays = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
  final List<int> _hours = List.generate(18, (index) => index + 6); // 6:00 - 23:00
  
  late PageController _pageController;
  int _currentPageIndex = DateTime.now().weekday - 1;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  Map<DateTime, int> _workoutsCount = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
      _loadClients();
      _updateWorkoutsCount();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    await ref.read(scheduleViewModelProvider.notifier).loadWeekSchedule();
    _updateWorkoutsCount();
  }

  Future<void> _loadClients() async {
    await ref.read(scheduleViewModelProvider.notifier).loadClients();
  }

  Future<void> _updateWorkoutsCount() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    final response = await Supabase.instance.client
        .from('schedule_slots')
        .select('start_time')
        .eq('trainer_id', userId)
        .gte('start_time', startOfMonth.toIso8601String())
        .lte('start_time', endOfMonth.toIso8601String());
    
    final Map<DateTime, int> count = {};
    for (final slot in response) {
      final date = DateTime.parse(slot['start_time']);
      final day = DateTime(date.year, date.month, date.day);
      count[day] = (count[day] ?? 0) + 1;
    }
    
    setState(() {
      _workoutsCount = count;
    });
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  void _showDeleteConfirmation(BuildContext context, ScheduleSlot slot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Удалить', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text('Удалить запись "${slot.displayName}"?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(scheduleViewModelProvider.notifier).deleteSlot(slot.id);
              _updateWorkoutsCount();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Удалено'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSlotDialog(int dayIndex, int hour) {
    try {
      final viewModel = ref.read(scheduleViewModelProvider.notifier);
      final weekStart = ref.read(scheduleViewModelProvider).currentWeekStart;
      final selectedDate = weekStart.add(Duration(days: dayIndex));
      final clients = viewModel.getAllClientsForDropdown();
      String? selectedClientId;

      if (clients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет клиентов'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Добавить в расписание',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.grey, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_weekDays[dayIndex]} ${selectedDate.day}.${selectedDate.month} в $hour:00',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1115),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Выберите клиента',
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.person, color: Colors.green, size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          value: selectedClientId,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          dropdownColor: const Color(0xFF1A1D24),
                          items: clients.map((client) {
                            return DropdownMenuItem(
                              value: client['id'] as String,
                              child: Text(client['name'] as String, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) => selectedClientId = value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1115),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('Отмена', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (selectedClientId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Выберите клиента'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                final startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour);
                                final endTime = startTime.add(const Duration(hours: 1));
                                await viewModel.createSlot(
                                  clientId: selectedClientId!,
                                  startTime: startTime,
                                  endTime: endTime,
                                  isRegistered: true,
                                );
                                _updateWorkoutsCount();
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Добавлено'), backgroundColor: Colors.green),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: const Text('Добавить', textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Logger.error('Error', error: e);
    }
  }

  void _showClientWorkout(ScheduleSlot slot) {
    context.push('/client-program/${slot.clientId}', extra: slot.displayName);
  }

  void _openCalendar() {
    _updateWorkoutsCount();
    setState(() => _showCalendar = true);
  }

  Future<void> _selectDate(DateTime date) async {
    final weekStart = ref.read(scheduleViewModelProvider).currentWeekStart;
    final difference = date.difference(weekStart).inDays;
    
    if (difference >= 0 && difference < 7) {
      await _pageController.animateToPage(difference, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _selectedDate = date;
        _currentPageIndex = difference;
        _showCalendar = false;
      });
    } else {
      final viewModel = ref.read(scheduleViewModelProvider.notifier);
      final weeksToMove = (difference / 7).floor();
      for (int i = 0; i < weeksToMove.abs(); i++) {
        weeksToMove > 0 ? await viewModel.nextWeek() : await viewModel.previousWeek();
      }
      final newWeekStart = ref.read(scheduleViewModelProvider).currentWeekStart;
      final newDifference = date.difference(newWeekStart).inDays;
      await _pageController.animateToPage(newDifference, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _selectedDate = date;
        _currentPageIndex = newDifference;
        _showCalendar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleViewModelProvider);
    final weekStart = state.currentWeekStart;
    final viewModel = ref.read(scheduleViewModelProvider.notifier);

    if (state.isLoading && state.slots.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text('Расписание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today, color: Colors.green, size: 20), onPressed: _openCalendar),
          IconButton(icon: const Icon(Icons.today, color: Colors.green, size: 20), onPressed: () {
            viewModel.goToCurrentWeek();
            setState(() {
              _currentPageIndex = DateTime.now().weekday - 1;
              _pageController.jumpToPage(_currentPageIndex);
              _selectedDate = DateTime.now();
            });
          }),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            if (_showCalendar)
              Container(
                color: const Color(0xFF0F1115),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () => setState(() => _showCalendar = false)),
                    ]),
                    _buildCalendar(),
                  ],
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => viewModel.previousWeek(), child: const Icon(Icons.chevron_left, color: Colors.green, size: 24)),
                  Text(viewModel.getWeekRange(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  GestureDetector(onTap: () => viewModel.nextWeek(), child: const Icon(Icons.chevron_right, color: Colors.green, size: 24)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: List.generate(7, (index) {
                  final date = weekStart.add(Duration(days: index));
                  final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
                  final isSelected = _currentPageIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut),
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
                            Text(_weekDays[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isToday ? Colors.green : Colors.grey)),
                            const SizedBox(height: 2),
                            Text(date.day.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.green : (isToday ? Colors.green : Colors.white))),
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
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPageIndex = index),
                children: List.generate(7, (dayIndex) {
                  final date = weekStart.add(Duration(days: dayIndex));
                  final slotsForDay = viewModel.getSlotsForDay(date);
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _hours.length,
                    itemBuilder: (context, hourIndex) {
                      final hour = _hours[hourIndex];
                      final slots = slotsForDay.where((slot) => slot.startTime.hour == hour).toList();
                      
                      return GestureDetector(
                        onTap: () => _showAddSlotDialog(dayIndex, hour),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 45,
                                child: Text('$hour:00', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                              Expanded(
                                child: slots.isEmpty
                                    ? const SizedBox(height: 36)
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: slots.map((slot) => GestureDetector(
                                            onLongPress: () => _showDeleteConfirmation(context, slot),
                                            onTap: () => _showClientWorkout(slot),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                slot.displayName,
                                                style: const TextStyle(fontSize: 12, color: Colors.green),
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final Map<DateTime, List<Object>> events = {};
    _workoutsCount.forEach((date, count) {
      events[date] = [count.toString()];
    });
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, _) => _selectDate(selectedDay),
        eventLoader: (day) => events[day] ?? [],
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          markerDecoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          markersMaxCount: 1,
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