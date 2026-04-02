import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trainapp/config/di/providers.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';
import 'add_client_dialog.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadClients();
  }
  
  Future<void> _loadClients() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null) {
      ref.read(clientsViewModelProvider.notifier).loadClients(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientsViewModelProvider);
    
    final filteredClients = state.clients.where((client) {
      if (_searchQuery.isEmpty) return true;
      return client.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             client.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Мои клиенты',
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
            icon: const Icon(Icons.person_add, color: Colors.green),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AddClientDialog(),
              );
            },
          ),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1D24),
                      Color(0xFF22262F),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Поиск клиентов...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: state.isLoading && state.clients.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : state.error != null
                      ? ErrorView(
                          message: state.error!,
                          onRetry: _loadClients,
                        )
                      : filteredClients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 80,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'У вас пока нет клиентов'
                                        : 'Клиенты не найдены',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_searchQuery.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Добавьте первого клиента',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredClients.length,
                              itemBuilder: (context, index) {
                                final client = filteredClients[index];
                                final isFirst = index == 0;
                                final isLast = index == filteredClients.length - 1;
                                
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
                                        context.push('/client/${client.id}');
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
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.grey.shade800,
                                              backgroundImage: client.avatarUrl != null
                                                  ? NetworkImage(client.avatarUrl!)
                                                  : null,
                                              child: client.avatarUrl == null
                                                  ? Text(
                                                      client.fullName[0].toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    client.fullName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (client.email.isNotEmpty)
                                                    Text(
                                                      client.email,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 4,
                                                    children: [
                                                      if (client.hasActiveSubscription)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withAlpha(26),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: const Text(
                                                            'Абонемент',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      if (client.workoutsCompleted > 0)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.withAlpha(26),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            '${client.workoutsCompleted} тренировок',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.blue,
                                                              fontWeight: FontWeight.w500,
                                                            ),
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
                            ),
            ),
          ],
        ),
      ),
    );
  }
}