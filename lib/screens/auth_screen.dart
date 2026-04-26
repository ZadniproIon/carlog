import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/spark_top_bar.dart';

enum _AuthStep { welcome, login, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.onEnterGuest,
    this.onGoogleSignIn,
    this.onForgotPassword,
    this.firebaseEnabled = false,
  });

  final Future<String?> Function(String email, String password) onLogin;
  final Future<String?> Function(String name, String email, String password)
  onSignUp;
  final VoidCallback onEnterGuest;
  final Future<String?> Function()? onGoogleSignIn;
  final Future<String?> Function(String email)? onForgotPassword;
  final bool firebaseEnabled;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  _AuthStep _step = _AuthStep.welcome;
  bool _isLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _signUpPasswordController.addListener(_onSignUpPasswordChanged);
  }

  @override
  void dispose() {
    _signUpPasswordController.removeListener(_onSignUpPasswordChanged);
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _AuthStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_step != _AuthStep.welcome) {
          setState(() => _step = _AuthStep.welcome);
        }
      },
      child: Scaffold(
        appBar: _buildTopBar(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_step) {
            _AuthStep.welcome => _buildWelcomeStep(),
            _AuthStep.login => _buildLoginStep(),
            _AuthStep.signUp => _buildSignUpStep(),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildTopBar() {
    if (_step == _AuthStep.welcome) {
      return null;
    }

    final title = _step == _AuthStep.login ? 'Sign in' : 'Create account';
    return SparkTopBar(
      title: Text(title),
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: _isLoading
            ? null
            : () {
                setState(() => _step = _AuthStep.welcome);
              },
        icon: const Icon(LucideIcons.arrowLeft),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return SafeArea(
      child: LayoutBuilder(
        key: const ValueKey<String>('welcome-step'),
        builder: (context, constraints) {
          final width = constraints.maxWidth > 520
              ? 520.0
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'app_logo_svg.svg',
                              height: 96,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'CarLog',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track your vehicle expenses smarter.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _step = _AuthStep.login),
                      icon: const Icon(LucideIcons.logIn),
                      label: const Text('Sign in'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _step = _AuthStep.signUp),
                      icon: const Icon(LucideIcons.userPlus),
                      label: const Text('Create account'),
                    ),
                    const SizedBox(height: 10),
                    _buildSocialAndGuestActions(
                      includeGoogle: true,
                      includeGuest: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginStep() {
    return _buildCenteredStep(
      key: const ValueKey<String>('login-step'),
      subtitle: null,
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(LucideIcons.mail),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                  icon: Icon(
                    _obscureLoginPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submitLogin(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _submitForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitLogin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.logIn),
              label: const Text('Sign in'),
            ),
            const SizedBox(height: 10),
            _buildSocialAndGuestActions(
              includeGoogle: true,
              includeGuest: false,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No account yet?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _step = _AuthStep.signUp),
                  child: const Text('Create one'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpStep() {
    return _buildCenteredStep(
      key: const ValueKey<String>('signup-step'),
      subtitle: null,
      child: Form(
        key: _signUpFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _signUpNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(LucideIcons.user),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(LucideIcons.mail),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _obscureSignUpPassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureSignUpPassword = !_obscureSignUpPassword;
                    });
                  },
                  icon: Icon(
                    _obscureSignUpPassword
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _buildPasswordHints(_signUpPasswordController.text),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: _obscureSignUpConfirmPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureSignUpConfirmPassword =
                          !_obscureSignUpConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureSignUpConfirmPassword
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                  ),
                ),
              ),
              validator: (value) {
                if (value != _signUpPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submitSignUp(),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submitSignUp,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.userPlus),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _step = _AuthStep.login),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredStep({
    required Key key,
    required String? subtitle,
    required Widget child,
  }) {
    return SafeArea(
      key: key,
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 520
              ? 520.0
              : constraints.maxWidth;
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                      ],
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialAndGuestActions({
    required bool includeGoogle,
    required bool includeGuest,
  }) {
    final children = <Widget>[];

    if (includeGoogle && _googleSignInAvailable()) {
      children.add(
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _submitGoogleSignIn,
          icon: const Icon(LucideIcons.chrome),
          label: const Text('Continue with Google'),
        ),
      );
    }
    if (includeGoogle && includeGuest && _googleSignInAvailable()) {
      children.add(const SizedBox(height: 8));
    }

    if (includeGuest) {
      children.add(
        OutlinedButton.icon(
          onPressed: _isLoading ? null : widget.onEnterGuest,
          icon: const Icon(LucideIcons.userX),
          label: const Text('Continue as guest'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildPasswordHints(String password) {
    final hasMinLength = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    final score = [
      hasMinLength,
      hasUpper,
      hasLower,
      hasDigit,
      hasSpecial,
    ].where((rule) => rule).length;

    final (strengthLabel, strengthColor) = switch (score) {
      <= 2 => ('Weak', Theme.of(context).colorScheme.error),
      3 || 4 => ('Medium', Theme.of(context).colorScheme.primary),
      _ => ('Strong', const Color(0xFF2E7D32)),
    };

    Widget ruleRow(String label, bool passed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              passed ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 15,
              color: passed
                  ? const Color(0xFF2E7D32)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password strength: ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                strengthLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: strengthColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ruleRow('At least 8 characters', hasMinLength),
          ruleRow('One uppercase letter', hasUpper),
          ruleRow('One lowercase letter', hasLower),
          ruleRow('One number', hasDigit),
          ruleRow('One special character', hasSpecial),
        ],
      ),
    );
  }

  bool _googleSignInAvailable() {
    if (!widget.firebaseEnabled || widget.onGoogleSignIn == null) {
      return false;
    }

    if (kIsWeb) {
      return true;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final error = await widget.onLogin(
      _loginEmailController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _submitSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final error = await widget.onSignUp(
      _signUpNameController.text.trim(),
      _signUpEmailController.text.trim(),
      _signUpPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (!widget.firebaseEnabled && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created. Signed in.')));
    }
  }

  Future<void> _submitForgotPassword() async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email first.')),
      );
      return;
    }

    if (widget.onForgotPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset is not available.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await widget.onForgotPassword!.call(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reset email sent. Check your inbox.')));
  }

  Future<void> _submitGoogleSignIn() async {
    if (widget.onGoogleSignIn == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await widget.onGoogleSignIn!.call();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
