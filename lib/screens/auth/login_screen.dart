import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildAuthCard(),
                  const SizedBox(height: 28),
                  Text(
                    'Melbet Shift Manager v1.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            size: 44,
            color: Colors.white,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(),
        const SizedBox(height: 16),
        Text(
          'MELBET',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                letterSpacing: 8,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
              ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: 6),
        Text(
          'Shift Report Manager',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 2,
              ),
        ).animate().fadeIn(delay: 350.ms),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState:
            _isSignUp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: _SignInForm(
          onSwitchToSignUp: () => setState(() => _isSignUp = true),
        ),
        secondChild: _SignUpForm(
          onSwitchToSignIn: () => setState(() => _isSignUp = false),
        ),
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign In Form
// ─────────────────────────────────────────────────────────────────────────────

class _SignInForm extends StatefulWidget {
  final VoidCallback onSwitchToSignUp;
  const _SignInForm({required this.onSwitchToSignUp});

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      if (auth.isPrivileged) {
        context.go('/admin');
      } else {
        context.go('/employee');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your credentials to continue',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 26),

            // Username
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Username is required' : null,
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 8),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.push('/forgot-password'),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Sign In Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Switch to Sign Up
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: widget.onSwitchToSignUp,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create New Account (Sign Up)',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About Developer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code_rounded,
                          color: AppTheme.accent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'About developer',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          color: AppTheme.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'name: kidoo Trove',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded,
                          color: AppTheme.success, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'phone +251900413372',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign Up Form  (with Role selector: Employee | Manager)
// ─────────────────────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  final VoidCallback onSwitchToSignIn;
  const _SignUpForm({required this.onSwitchToSignIn});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String _selectedRole = 'employee'; // 'employee' | 'manager'
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  List<String> _availableTeams = ['Team 1', 'Team 2', 'Team 3'];
  String _selectedTeam = 'Team 1';
  final Set<String> _selectedManagerTeams = {'Team 1'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.loadTeams();
      if (mounted && auth.teams.isNotEmpty) {
        setState(() {
          _availableTeams = List.from(auth.teams);
          if (!_availableTeams.contains(_selectedTeam)) {
            _selectedTeam = _availableTeams.first;
          }
          if (_selectedManagerTeams.isEmpty ||
              !_selectedManagerTeams.any((t) => _availableTeams.contains(t))) {
            _selectedManagerTeams.clear();
            _selectedManagerTeams.add(_availableTeams.first);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == 'manager' && _selectedManagerTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one team to manage'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final chosenTeam = _selectedRole == 'manager'
        ? _selectedManagerTeams.first
        : _selectedTeam;
    final chosenTeams = _selectedRole == 'manager'
        ? _selectedManagerTeams.toList()
        : [_selectedTeam];

    final error = await auth.register(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _selectedRole,
      teamName: chosenTeam,
      teams: chosenTeams,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      final roleLabel =
          _selectedRole == 'manager' ? 'Manager' : 'Employee';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$roleLabel account registered successfully! An administrator must approve your account before you can sign in.',
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      _nameCtrl.clear();
      _usernameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() {
        _selectedRole = 'employee';
        _selectedTeam = _availableTeams.isNotEmpty ? _availableTeams.first : 'Team 1';
        _selectedManagerTeams.clear();
        if (_availableTeams.isNotEmpty) {
          _selectedManagerTeams.add(_availableTeams.first);
        }
      });
      widget.onSwitchToSignIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details below to register',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // ── Role Selector ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Role',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _RoleOption(
                      value: 'employee',
                      groupValue: _selectedRole,
                      label: 'Employee',
                      icon: Icons.badge_outlined,
                      description: 'Submit shift reports',
                      onTap: () => setState(() => _selectedRole = 'employee'),
                    ),
                    const SizedBox(width: 10),
                    _RoleOption(
                      value: 'manager',
                      groupValue: _selectedRole,
                      label: 'Manager',
                      icon: Icons.manage_accounts_outlined,
                      description: 'View & manage reports',
                      onTap: () => setState(() => _selectedRole = 'manager'),
                    ),
                  ],
                ),
                if (_selectedRole == 'manager')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13, color: AppTheme.accent),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Manager accounts require admin approval before sign-in.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppTheme.accent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Full name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: 12),

            // Username
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Team Selection (Dynamic: single for employee, multi-select for manager)
            if (_selectedRole == 'employee') ...[
              DropdownButtonFormField<String>(
                value: _availableTeams.contains(_selectedTeam)
                    ? _selectedTeam
                    : (_availableTeams.isNotEmpty ? _availableTeams.first : null),
                decoration: const InputDecoration(
                  labelText: 'Select Team',
                  prefixIcon: Icon(Icons.groups_outlined),
                  helperText: 'Your assigned shift team',
                ),
                dropdownColor: AppTheme.bgCard,
                items: _availableTeams
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTeam = val);
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select a team' : null,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedManagerTeams.isEmpty
                        ? AppTheme.error
                        : AppTheme.bgBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined,
                            size: 18, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select Teams to Manage (Multi-select):',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTeams.map((team) {
                        final isSelected = _selectedManagerTeams.contains(team);
                        return FilterChip(
                          avatar: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                          label: Text(team),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: AppTheme.bgSurface,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primary : AppTheme.bgBorder,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedManagerTeams.add(team);
                              } else {
                                if (_selectedManagerTeams.length > 1) {
                                  _selectedManagerTeams.remove(team);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Manager must select at least one team'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selected: ${_selectedManagerTeams.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.accent,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                final emailRegex = RegExp(
                  r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$',
                  caseSensitive: false,
                );
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePw,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePw ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignUp(),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Sign Up Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Back to Sign In
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: widget.onSwitchToSignIn,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role option card widget
// ─────────────────────────────────────────────────────────────────────────────

class _RoleOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _RoleOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.12)
                : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.bgBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppTheme.primary : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
