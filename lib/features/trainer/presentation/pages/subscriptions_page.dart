import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/features/trainer/domain/entities/subscription.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  final String? clientId;
  
  const SubscriptionsPage({super.key, this.clientId});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null) {
      ref.read(subscriptionsViewModelProvider.notifier).loadSubscriptions(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsViewModelProvider);
    
    final filteredSubscriptions = widget.clientId != null
        ? state.subscriptions.where((s) => s.clientId == widget.clientId).toList()
        : state.subscriptions;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Абонементы',
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
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () {
              context.push('/add-subscription');
            },
          ),
        ],
      ),
      body: PremiumBackground(
        child: state.isLoading && state.subscriptions.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : state.error != null
                ? ErrorView(
                    message: state.error!,
                    onRetry: _loadData,
                  )
                : filteredSubscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments,
                              size: 80,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Нет абонементов',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.clientId != null
                                  ? 'У клиента пока нет абонементов'
                                  : 'Создайте первый абонемент',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () {
                                context.push('/add-subscription');
                              },
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
                                  'Создать абонемент',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSubscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = filteredSubscriptions[index];
                          final isFirst = index == 0;
                          final isLast = index == filteredSubscriptions.length - 1;
                          
                          return FutureBuilder(
                            future: _getClientName(sub.clientId),
                            builder: (context, snapshot) {
                              final clientName = snapshot.data ?? 'Клиент';
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1A1D24),
                                      Color(0xFF22262F),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                    topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                    bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
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
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.only(
                                    topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                    topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                    bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _showSubscriptionDetails(sub, clientName);
                                    },
                                    borderRadius: BorderRadius.only(
                                      topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                      topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                      bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                      bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF1A1D24),
                                                  Color(0xFF22262F),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.withOpacity(0.3),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.payment,
                                              color: Colors.green,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sub.planName,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  clientName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: sub.isActive
                                                            ? Colors.green.withOpacity(0.15)
                                                            : Colors.red.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: sub.isActive ? Colors.green : Colors.red,
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        sub.isActive ? 'Активен' : 'Истёк',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: sub.isActive ? Colors.green : Colors.red,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${sub.price} ₽',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
  
  Future<String> _getClientName(String clientId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', clientId)
          .maybeSingle();
      
      return response?['full_name'] ?? 'Клиент';
    } catch (e) {
      return 'Клиент';
    }
  }
  
  void _showSubscriptionDetails(Subscription sub, String clientName) {
    final isActive = sub.isActive;
    final daysLeft = sub.daysLeft;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Text(
                  sub.planName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Активен' : 'Истёк',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildDetailRow('Клиент', clientName, Icons.person),
                _buildDetailRow('Стоимость', '${sub.price} ₽', Icons.attach_money),
                _buildDetailRow('Дата начала', Helpers.formatDate(sub.startDate), Icons.calendar_today),
                _buildDetailRow('Дата окончания', Helpers.formatDate(sub.endDate), Icons.calendar_today),
                if (isActive) _buildDetailRow('Осталось дней', daysLeft.toString(), Icons.timer),
                if (sub.notes != null) _buildDetailRow('Заметки', sub.notes!, Icons.note),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'Закрыть',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/edit-subscription/${sub.id}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                            'Редактировать',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}