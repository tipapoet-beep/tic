import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/progress/presentation/pages/add_measurement_page.dart';
import '../../features/progress/presentation/pages/add_progress_photo_page.dart';
import '../../features/progress/domain/entities/body_measurement.dart';
import '../../features/trainer/presentation/pages/trainer_home_page.dart';
import '../../features/trainer/presentation/pages/clients_page.dart';
import '../../features/trainer/presentation/pages/client_detail_page.dart';
import '../../features/trainer/presentation/pages/program_builder_page.dart';
import '../../features/trainer/presentation/pages/programs_list_page.dart';
import '../../features/trainer/presentation/pages/subscriptions_page.dart';
import '../../features/trainer/presentation/pages/add_subscription_page.dart';
import '../../features/trainer/presentation/pages/assign_program_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/trainer/presentation/pages/client_program_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/client/presentation/pages/client_home_page.dart';
import '../../features/client/presentation/pages/client_workout_page.dart';
import '../../features/client/presentation/pages/client_subscription_page.dart';
import '../../features/client/presentation/pages/client_schedule_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../core/utils/logger.dart' as app_logger;

class AppRouter {
  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginPage = state.matchedLocation == '/login';
      final isRegisterPage = state.matchedLocation == '/register';
      
      if (!isLoggedIn && !isLoginPage && !isRegisterPage) {
        return '/login';
      }
      
      if (isLoggedIn && (isLoginPage || isRegisterPage)) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final user = session!.user;
          app_logger.Logger.log('User ID: ${user.id}');
          
          Map<String, dynamic>? response;
          int attempts = 0;
          
          while (attempts < 3 && response == null) {
            response = await Supabase.instance.client
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .maybeSingle();
            
            if (response == null) {
              attempts++;
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
          
          app_logger.Logger.log('Profile response: $response');
          
          if (response != null && response['role'] != null) {
            final role = response['role'] as String;
            app_logger.Logger.log('User role: $role');
            
            // Все пользователи попадают на ленту
            return '/feed';
          } else {
            app_logger.Logger.log('Profile not found, creating...');
            await Supabase.instance.client.from('profiles').insert({
              'id': user.id,
              'email': user.email,
              'full_name': user.userMetadata?['full_name'] ?? 'User',
              'role': 'client',
              'has_agreed_to_terms': true,
            });
            return '/feed';
          }
        } catch (e) {
          app_logger.Logger.error('Error checking role', error: e);
          return '/feed';
        }
      }
      
      return null;
    },
    refreshListenable: GoRouterRefreshStream(),
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterPage(),
        ),
      ),
      
      // Feed (лента) - главная для всех
      GoRoute(
        path: '/feed',
        name: 'feed',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const FeedPage(),
        ),
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),
      
      // Client Home (для клиента, через FeedPage)
      GoRoute(
        path: '/client-home',
        name: 'clientHome',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientHomePage(),
        ),
      ),
      
      // Client Workout
      GoRoute(
        path: '/client-workout',
        name: 'clientWorkout',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientWorkoutPage(),
        ),
      ),
      
      // Client Subscription
      GoRoute(
        path: '/client-subscription',
        name: 'clientSubscription',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientSubscriptionPage(),
        ),
      ),
      
      // Client Schedule
      GoRoute(
        path: '/client-schedule',
        name: 'clientSchedule',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientSchedulePage(),
        ),
      ),
      
      // Trainer (кабинет тренера)
      GoRoute(
        path: '/trainer',
        name: 'trainer',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TrainerHomePage(),
        ),
      ),
    
      
      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfilePage(),
        ),
      ),
      
      // Progress
      GoRoute(
        path: '/progress',
        name: 'progress',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProgressPage(),
        ),
      ),
      GoRoute(
        path: '/add-measurement',
        name: 'addMeasurement',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddMeasurementPage(),
        ),
      ),
      GoRoute(
        path: '/edit-measurement/:id',
        name: 'editMeasurement',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AddMeasurementPage(
            measurement: state.extra != null ? state.extra as BodyMeasurement? : null,
          ),
        ),
      ),
      GoRoute(
        path: '/add-progress-photo',
        name: 'addProgressPhoto',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddProgressPhotoPage(),
        ),
      ),
      
      // Client Progress (для тренера)
      GoRoute(
        path: '/client-progress/:clientId',
        name: 'clientProgress',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ProgressPage(
            clientId: state.pathParameters['clientId'],
            clientName: state.extra as String?,
            isTrainerView: true,
          ),
        ),
      ),
      
      // Trainer pages
      GoRoute(
        path: '/clients',
        name: 'clients',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ClientsPage(),
        ),
      ),
      GoRoute(
        path: '/client/:id',
        name: 'clientDetail',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ClientDetailPage(
            clientId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/create-template',
        name: 'createTemplate',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProgramBuilderPage(),
        ),
      ),
      GoRoute(
        path: '/edit-template/:id',
        name: 'editTemplate',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ProgramBuilderPage(
            templateId: state.pathParameters['id'],
          ),
        ),
      ),
      GoRoute(
        path: '/view-template/:id',
        name: 'viewTemplate',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ProgramBuilderPage(
            templateId: state.pathParameters['id'],
            readOnly: true,
          ),
        ),
      ),
      GoRoute(
        path: '/programs-list',
        name: 'programsList',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProgramsListPage(),
        ),
      ),
      GoRoute(
        path: '/subscriptions',
        name: 'subscriptions',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: SubscriptionsPage(
            clientId: state.uri.queryParameters['client'],
          ),
        ),
      ),
      GoRoute(
        path: '/add-subscription',
        name: 'addSubscription',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AddSubscriptionPage(
            clientId: state.uri.queryParameters['client'],
          ),
        ),
      ),
      GoRoute(
        path: '/assign-program/:clientId',
        name: 'assignProgram',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: AssignProgramPage(
            clientId: state.pathParameters['clientId']!,
          ),
        ),
      ),
      
      // Chat
      GoRoute(
        path: '/chat/:userId',
        name: 'chat',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ChatPage(
            otherUser: state.extra as dynamic,
          ),
        ),
      ),
      GoRoute(
        path: '/chat-list',
        name: 'chatList',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ChatListPage(),
        ),
      ),
      
      // Calendar
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CalendarPage(),
        ),
      ),
      
      // Schedule (тренер)
      GoRoute(
        path: '/schedule',
        name: 'schedule',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SchedulePage(),
        ),
      ),
      
      // Client Program
      GoRoute(
        path: '/client-program/:clientId',
        name: 'clientProgram',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ClientProgramPage(
            clientId: state.pathParameters['clientId']!,
            clientName: state.extra as String? ?? 'Клиент',
          ),
        ),
      ),
    ],
  );

  GoRouter get config => _router;
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final Stream<AuthState> _stream;

  GoRouterRefreshStream() {
    _stream = Supabase.instance.client.auth.onAuthStateChange;
    _stream.listen((_) => notifyListeners());
  }
}