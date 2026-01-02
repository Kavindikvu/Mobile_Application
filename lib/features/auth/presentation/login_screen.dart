import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/components/info_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isParent = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.durationLong,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppMotion.curveStandard,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppMotion.curveDecelerate,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signInWithGoogle(isParent: _isParent);
    
    // Only navigate if authentication was successful
    if (mounted && ref.read(authProvider).isAuthenticated) {
      context.go('/home');
    }
  }

  void _handleRoleChange(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _isParent = value);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 480,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: mediaQuery.size.height * 0.06,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero Section with Logo/Branding
                            _HeroSection(
                              isParent: _isParent,
                              animation: _fadeAnimation,
                            ),
                            SizedBox(height: mediaQuery.size.height * 0.05),
                            
                            // Error Banner (if any)
                            if (authState.error != null) ...[
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: InfoBanner(
                                  type: InfoBannerType.error,
                                  title: 'Sign-in Failed',
                                  message: authState.error!,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            // Main Content Card
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.lg),
                                  side: BorderSide(
                                    color: colorScheme.outline.withOpacity(0.12),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Role Selection Section
                                      _RoleSelectionSection(
                                        isParent: _isParent,
                                        onRoleChanged: _handleRoleChange,
                                      ),
                                      const SizedBox(height: AppSpacing.xl),

                                      // Google Sign-In Button
                                      _GoogleSignInButton(
                                        isLoading: isLoading,
                                        onPressed: isLoading ? null : _handleGoogleSignIn,
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // Secondary Actions
                                      _SecondaryActions(isParent: _isParent),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSpacing.xl + AppSpacing.sm),

                            // Terms and Privacy
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _TermsAndPrivacy(theme: theme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Hero Section with Welcome Message
class _HeroSection extends StatelessWidget {
  final bool isParent;
  final Animation<double> animation;

  const _HeroSection({
    required this.isParent,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: AppMotion.curveEmphasized,
        ),
      ),
      child: Column(
        children: [
          // App Logo with Enhanced Shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppColors.brandTeal).withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(AppColors.brandBlue).withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              'assets/app_icon/skillora_icon.png',
              width: 104,
              height: 104,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to gradient if asset is missing
                return Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(AppColors.brandTeal),
                        const Color(AppColors.brandBlue),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Text(
            'Welcome to Skillora',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
              height: 1.25,
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: AppMotion.durationMedium,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              isParent
                  ? 'Connect with your child\'s learning journey'
                  : 'Start your learning adventure',
              key: ValueKey(isParent),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.85),
                height: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Role Selection Section
class _RoleSelectionSection extends StatelessWidget {
  final bool isParent;
  final ValueChanged<bool> onRoleChanged;

  const _RoleSelectionSection({
    required this.isParent,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 0.1,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedContainer(
          duration: AppMotion.durationMedium,
          curve: AppMotion.curveStandard,
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: const Text(
                  'Parent',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                icon: const Icon(Icons.family_restroom, size: 22),
              ),
              ButtonSegment(
                value: false,
                label: const Text(
                  'Student',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                icon: const Icon(Icons.school_outlined, size: 22),
              ),
            ],
            selected: {isParent},
            onSelectionChanged: (Set<bool> selection) {
              onRoleChanged(selection.first);
            },
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md + 2,
              ),
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.4),
              selectedBackgroundColor: const Color(AppColors.brandTeal).withOpacity(0.2),
              selectedForegroundColor: const Color(AppColors.brandBlue),
              foregroundColor: colorScheme.onSurfaceVariant.withOpacity(0.75),
              side: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// Google Sign-In Button
class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppMotion.durationShort,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.97).animate(
          CurvedAnimation(
            parent: _scaleController,
            curve: AppMotion.curveStandard,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.04 : 0.08),
                blurRadius: _isPressed ? 4 : 12,
                offset: Offset(0, _isPressed ? 1 : 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: widget.onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                side: BorderSide(
                  color: colorScheme.outline.withOpacity(0.25),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  else ...[
                    _GoogleLogo(),
                    const SizedBox(width: AppSpacing.md + 2),
                  ],
                  Flexible(
                    child: Text(
                      widget.isLoading ? 'Signing in...' : 'Continue with Google',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.25,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Secondary Actions (Onboarding Links)
class _SecondaryActions extends StatelessWidget {
  final bool isParent;

  const _SecondaryActions({required this.isParent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          if (isParent) {
            context.go('/onboarding/parent-link');
          } else {
            context.go('/onboarding/student');
          }
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 44),
        ),
        child: Text(
          isParent
              ? 'Link your child later'
              : 'Use school email to onboard',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            letterSpacing: 0.1,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// Terms and Privacy Policy
class _TermsAndPrivacy extends StatelessWidget {
  final ThemeData theme;

  const _TermsAndPrivacy({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text.rich(
        TextSpan(
          text: 'By continuing, you agree to our ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontSize: 12,
            height: 1.5,
            letterSpacing: 0.1,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (context) => const _LegalDialog(title: 'Terms of Service'),
                  );
                },
                child: Text(
                  'Terms of Service',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: ' and ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (context) => const _LegalDialog(title: 'Privacy Policy'),
                  );
                },
                child: Text(
                  'Privacy Policy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: '.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Legal Dialog
class _LegalDialog extends StatelessWidget {
  final String title;

  const _LegalDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: const SingleChildScrollView(
        child: Text('Content coming soon.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Google Logo Widget
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 22,
      height: 22,
      errorBuilder: (context, error, stackTrace) {
        // Fallback icon if asset missing
        return const Icon(
          Icons.g_mobiledata,
          size: 22,
          color: Colors.redAccent,
        );
      },
    );
  }
}
