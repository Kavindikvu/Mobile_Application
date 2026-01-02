import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/discover/presentation/discover_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/activity/presentation/activity_dashboard.dart';
import '../../features/enhanced_discover/presentation/teacher_profile_screen.dart';
import '../../features/onboarding/presentation/student_onboarding_screen.dart';
import '../../features/onboarding/presentation/parent_linking_screen.dart';
import '../../features/classes/domain/student_class_summary.dart';
import '../../features/classes/presentation/class_detail_screen.dart';
import '../../features/classes/presentation/classes_screen.dart';
import '../../features/marketplace/presentation/marketplace_screen.dart';
import '../../features/assignments/presentation/assignments_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/messages/presentation/messages_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/child_context_bar.dart';
import '../widgets/child_switcher.dart' show RoleBasedNavigation;
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/student_activity/presentation/student_activity_screen.dart';
import '../theme/tokens.dart';
import '../../features/classes/application/my_classes_controller.dart';

final _key = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _key,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuthed = ref.read(isAuthenticatedProvider);
      final loggingIn = state.fullPath == '/login';
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Bottom navigation order: Home, Discover, Classes, Marketplace, Notifications, Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
              GoRoute(
                path: '/activity',
                name: 'activity',
                builder: (context, state) => const ActivityDashboard(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                name: 'discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
              GoRoute(
                path: '/teacher/:instructorId',
                name: 'teacher_profile',
                builder: (context, state) {
                  final id = state.pathParameters['instructorId']!;
                  return TeacherProfileScreen(instructorId: id);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classes',
                name: 'classes',
                builder: (context, state) => const ClassesScreen(),
                routes: [
                  GoRoute(
                    path: ':classId',
                    name: 'class_detail',
                    builder: (context, state) {
                      final classId = state.pathParameters['classId']!;
                      final extra = state.extra;
                      if (extra is StudentClassSummary) {
                        return ClassDetailScreen(summary: extra);
                      }
                      return _ClassDetailResolver(
                        classId: classId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/marketplace',
                name: 'marketplace',
                builder: (context, state) => const MarketplaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: '/notification-settings',
                name: 'notification_settings',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                name: 'menu',
                builder: (context, state) => const MenuScreen(),
              ),
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: '/assignments',
                name: 'assignments',
                builder: (context, state) => const AssignmentsScreen(),
              ),
              GoRoute(
                path: '/payments',
                name: 'payments',
                builder: (context, state) => const PaymentsScreen(),
              ),
              GoRoute(
                path: '/messages',
                name: 'messages',
                builder: (context, state) => const MessagesScreen(),
              ),
              GoRoute(
                path: '/onboarding/student',
                name: 'student_onboarding',
                builder: (context, state) => const StudentOnboardingScreen(),
              ),
              GoRoute(
                path: '/onboarding/parent-link',
                name: 'parent_link',
                builder: (context, state) => const ParentLinkingScreen(),
              ),
              GoRoute(
                path: '/student-activity/:studentId',
                name: 'student_activity',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  return StudentActivityScreen(studentId: studentId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int get _currentIndex => widget.navigationShell.currentIndex;

  void _onTap(int idx) {
    widget.navigationShell.goBranch(
      idx,
      initialLocation: idx == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedChild = authState.selectedChild;
    final hasSelectedChild = authState.hasSelectedChild;
    final isParent = authState.isParent;
    final theme = Theme.of(context);

    // Determine profile image to display
    final profileImageUrl = hasSelectedChild && selectedChild != null
        ? selectedChild.profileImageUrl
        : user?.profileImageUrl;
    final profileInitials = (hasSelectedChild && selectedChild != null
            ? selectedChild.initials
            : user?.initials) ??
        '?';

    // Get role-based destinations
    final destinations = RoleBasedNavigation.getDestinations(
      context: context,
      profileImageUrl: profileImageUrl,
      profileInitials: profileInitials,
    );

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Column(
        children: [
          if (isParent) const ChildContextBar(),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: _buildNavigationBarThemeData(context),
        child: NavigationBar(
          backgroundColor: theme.navigationBarTheme.backgroundColor ??
              theme.colorScheme.surface,
          indicatorColor: const Color(AppColors.brandTeal).withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTap,
          destinations: destinations,
        ),
      ),
    );
  }
}

class _ClassDetailResolver extends ConsumerWidget {
  const _ClassDetailResolver({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesState = ref.watch(myClassesControllerProvider);
    return classesState.when(
      data: (state) {
        final summary = state.classes.firstWhereOrNull(
          (classSummary) => classSummary.classId == classId,
        );
        if (summary != null) {
          return ClassDetailScreen(summary: summary);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Class details'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 40),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We couldn\'t locate that class in your enrollments.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => context.go('/classes'),
                    child: const Text('Back to My Classes'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Class details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Something went wrong while locating this class.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.go('/classes'),
                  child: const Text('Back to My Classes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

NavigationBarThemeData _buildNavigationBarThemeData(BuildContext context) {
  final theme = Theme.of(context);
  final baseLabelStyle = theme.textTheme.labelSmall ??
      const TextStyle(fontSize: 10, fontWeight: FontWeight.w500);
  const activeColor = Color(AppColors.brandBlue);
  final inactiveColor = theme.colorScheme.onSurfaceVariant;
  final indicatorColor = const Color(AppColors.brandTeal).withOpacity(0.18);
  final backgroundColor =
      theme.navigationBarTheme.backgroundColor ?? theme.colorScheme.surface;

  return NavigationBarThemeData(
    height: theme.navigationBarTheme.height,
    backgroundColor: backgroundColor,
    indicatorColor: indicatorColor,
    labelTextStyle: MaterialStateProperty.resolveWith((states) {
      final isSelected = states.contains(MaterialState.selected);
      return baseLabelStyle.copyWith(
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? activeColor : inactiveColor,
        overflow: TextOverflow.ellipsis,
      );
    }),
    iconTheme: MaterialStateProperty.resolveWith((states) {
      final isSelected = states.contains(MaterialState.selected);
      return IconThemeData(
        size: isSelected ? 28 : 26,
        color: isSelected ? activeColor : inactiveColor,
      );
    }),
  );
}
