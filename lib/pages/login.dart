import 'package:faunty/helper/logging.dart';
import 'package:faunty/models/place_model.dart';
import 'package:faunty/firestore/place_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore/user_firestore_service.dart';
import '../models/user_entity.dart';
import '../models/user_roles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/tools/translation_helper.dart';
import 'package:faunty/components/language_dropdown.dart';
import 'package:faunty/components/custom_snackbar.dart';
import '../state_management/user_provider.dart';
import '../state_management/firestore_quota_provider.dart';

Future<(User?, String?)> registerWithEmail(BuildContext context, String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    return (credential.user, null);
  } on FirebaseAuthException catch (e) {
    printError('Registration error: $e');
    if (!context.mounted) return (null, translation('Registration failed. Please try again.'));
    switch (e.code) {
      case 'email-already-in-use':
        return (null, translation(context: context, 'This email is already registered.'));
      case 'weak-password':
        return (null, translation(context: context, 'Password is too weak. Please use at least 6 characters.'));
      case 'invalid-email':
        return (null, translation(context: context, 'Please enter a valid email address.'));
      case 'operation-not-allowed':
        return (null, translation(context: context, 'Registration is currently disabled.'));
      case 'network-request-failed':
        return (null, translation(context: context, 'No internet connection. Please check your network and try again.'));
      default:
        return (null, "${translation(context: context, 'Registration failed.')}\n${e.message ?? ''}");
    }
  } catch (e) {
    printError('Registration error: $e');
    if (!context.mounted) return (null, translation('Registration failed. Please try again.'));
    if (e.toString().contains('SocketException')) {
      return (null, translation(context: context, 'No internet connection. Please check your network and try again.'));
    }
    return (null, translation(context: context, 'Registration failed. Please try again.'));
  }
}

Future<User?> loginWithEmail(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return credential.user;
  } on FirebaseAuthException catch (e) {
    printError('Login error: $e');
    switch (e.code) {
      case 'user-not-found':
        throw 'No account found for this email.';
      case 'invalid-credential':
        throw 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        throw 'Please enter a valid email address.';
      case 'user-disabled':
        throw 'This account has been disabled.';
      case 'network-request-failed':
        throw 'No internet connection. Please check your network and try again.';
      default:
        throw 'Login failed. ${e.message ?? ''}';
    }
  } catch (e) {
    printError('Login error: $e');
    if (e.toString().contains('SocketException')) {
      throw 'No internet connection. Please check your network and try again.';
    }
    throw 'Login failed. Please try again.';
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  static const double _formMaxWidth = 400;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isRegisterMode = false;
  PlaceModel? _selectedPlace;
  List<PlaceModel> _places = [];
  late AnimationController _animController;
  late Animation<double> _registerFieldsAnim;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _registerFieldsAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    // Ensure at least one place exists before fetching
    await PlaceFirestoreService.ensureAtLeastOnePlaceExists();
    try {
      final snapshot = await FirebaseFirestore.instance.collection('places').get();
      printInfo('Fetched places: ${snapshot.docs.length}');
      if (!mounted) return;
      setState(() {
        _places = snapshot.docs.map((doc) => PlaceModel.fromFirestore(doc)).where((p) => (p.displayName ?? '').isNotEmpty).toList();
        // If only one place, select it by default in register mode TODO
        if (_isRegisterMode && _places.length == 1) {
          _selectedPlace = _places.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      printError('Error fetching places: $e');
      setState(() {
        _places = [];
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      final user = await loginWithEmail(email, password);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (user != null) {
        // Fetch user document to determine role
    final doc = await FirebaseFirestore.instance.collection('user_list').doc(user.uid).get();
    try { ref.read(firestoreQuotaProvider).recordRead(); } catch (_) {}
        String? role;
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          role = data['role'] as String?;
        }
        // Invalidate userProvider to ensure fresh user state from StreamProvider
        ref.invalidate(userProvider);

        if (role == 'User') {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/user-welcome');
        } else {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (!mounted) return;
    if (email.isEmpty) {
      showCustomSnackBar(context, translation(context: context, 'Please enter your email address to reset your password.'));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showCustomSnackBar(context, translation(context: context, 'Password reset email sent. Please check your inbox.'));
    } on FirebaseAuthException catch (e) {
      printError('Password reset error: $e');
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = translation(context: context, 'No account found for this email.');
          break;
        case 'invalid-email':
          msg = translation(context: context, 'Please enter a valid email address.');
          break;
        case 'network-request-failed':
          msg = translation(context: context, 'No internet connection. Please check your network and try again.');
          break;
        default:
          msg = translation(context: context, 'Failed to send password reset email. Please try again.');
      }
      if (!mounted) return;
      showCustomSnackBar(context, msg);
    } catch (e) {
      printError('Password reset error: $e');
      if (!mounted) return;
      showCustomSnackBar(context, translation(context: context, 'Failed to send password reset email. Please try again.'));
    }
  }

  Future<void> _register() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Please fill in all fields.';
      });
      return;
    }
    if (!email.contains('@')) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Please enter a valid email address.';
      });
      return;
    }
    if (password != confirmPassword) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Passwords do not match.';
      });
      return;
    }
    if (_selectedPlace == null || _selectedPlace!.id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Please select a place.';
      });
      return;
    }

    // Check registrationMode for the selected place
    final regMode = await FirebaseFirestore.instance 
        .collection('places')
        .doc(_selectedPlace!.id)
        .get()
        .then((doc) => doc.data()?['registrationMode'] as bool? ?? false);
    if (!regMode) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Registration is currently disabled for this place. Please ask the Hooca of this place to enable registration.';
      });
      return;
    }
    if (!mounted) return;
    final (user, regError) = await registerWithEmail(context, email, password);
    if (user != null) {
      // Check if there's a placeholder user with this email in the selected place
      final placeholderQuery = await FirebaseFirestore.instance
        .collection('user_list')
        .where('email', isEqualTo: email)
        .where('placeId', isEqualTo: _selectedPlace!.id)
        .where('isPlaceholder', isEqualTo: true)
        .limit(1)
        .get();
      try { ref.read(firestoreQuotaProvider).recordRead(); } catch (_) {}

      if (placeholderQuery.docs.isNotEmpty) {
        // Link with existing placeholder user
        final placeholderDoc = placeholderQuery.docs.first;
        final placeholderData = placeholderDoc.data();
        // Instead of creating a new doc with auth uid, update the placeholder doc to
        // record the auth uid and link metadata while keeping the placeholder doc id.
        final placeholderRef = FirebaseFirestore.instance.collection('user_list').doc(placeholderDoc.id);
        await placeholderRef.update({
          'authUid': user.uid,
          'email': email,
          'firstName': placeholderData['firstName'] ?? firstName,
          'lastName': placeholderData['lastName'] ?? lastName,
          'role': placeholderData['role'] ?? UserRole.user.name,
          'linkedFromPlaceholder': true,
          'isPlaceholder': false,
          'originalPlaceholderId': placeholderDoc.id,
          'linkedAt': FieldValue.serverTimestamp(),
          'linkedBy': 'Mail Registration',
        });
        try { ref.read(firestoreQuotaProvider).recordWrite(); } catch (_) {}
      } else {
        // Normal registration - create new user
        final newUser = UserEntity(
          uid: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: UserRole.user,
          placeId: _selectedPlace!.id,
        );
        await UserFirestoreService().createUser(newUser);
        try { ref.read(firestoreQuotaProvider).recordWrite(); } catch (_) {}
      }

      // Invalidate userProvider to ensure fresh user state from StreamProvider
      ref.invalidate(userProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/user-welcome');

    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = regError ?? 'Registration failed. Please try again.';
      });
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleRegisterMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _error = null;
    });
        if (_isRegisterMode) {
          _animController.forward();
          // Remove focus from all fields when entering register mode
          FocusScope.of(context).unfocus();
        } else {
          _animController.reverse();
        }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    if (userAsync is AsyncData && userAsync.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name == '/login') {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: !_isRegisterMode
                        ? GestureDetector(
                          onDoubleTap: () {
                          if (kDebugMode) {
                            _emailController.text = 'admin@faunty.com';
                            _passwordController.text = 'fatih1453';
                            _login();
                          }
                          },
                          child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            Theme.of(context).brightness == Brightness.light
                            ? 'assets/Logo.png'
                            : 'assets/LogoInverse.png',
                            height: 145,
                            fit: BoxFit.contain,
                          ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isRegisterMode ? translation(context: context, 'Register') : translation(context: context, 'Login'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          AutofillGroup(
                            child: _LoginFormFields(
                              isRegisterMode: _isRegisterMode,
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController: _confirmPasswordController,
                              showPassword: _showPassword,
                              showConfirmPassword: _showConfirmPassword,
                              onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                              onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                              onLogin: _login,
                              onForgotPassword: () => _sendPasswordReset(_emailController.text.trim()),
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: _registerFieldsAnim,
                            axisAlignment: -1.0,
                            child: _RegisterExtraFields(
                              confirmPasswordController: _confirmPasswordController,
                              showConfirmPassword: _showConfirmPassword,
                              onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                              selectedPlace: _selectedPlace,
                              places: _places,
                              onPlaceChanged: (val) => setState(() => _selectedPlace = val),
                              onClearPlace: () => setState(() => _selectedPlace = null),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) ...[
                            // Error message container
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _isLoading
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(translation(context: context, 'Please wait...'), style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                                      child: ElevatedButton(
                                        onPressed: _isRegisterMode ? _register : _login,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(_isRegisterMode ? translation(context: context, 'Register') : translation(context: context, 'Login'),
                                          style: const TextStyle(fontSize: 18)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                                      child: TextButton(
                                        onPressed: _toggleRegisterMode,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 250),
                                          child: Text(
                                            _isRegisterMode
                                                ? translation(context: context, 'Already have an account? Login')
                                                : translation(context: context, 'Don\'t have an account? Register'),
                                            key: ValueKey(_isRegisterMode),
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Language selector at the bottom (only in login mode)
                                if (!_isRegisterMode)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: Center(
                                      child: LanguageDropdown(
                                        borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                        borderRadius: 20,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Modularized form fields widget
class _LoginFormFields extends StatelessWidget {
  final bool isRegisterMode;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onLogin;
  final VoidCallback? onForgotPassword;

  const _LoginFormFields({
    required this.isRegisterMode,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onLogin,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isRegisterMode) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
            child: TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: translation(context: context, 'First Name'),
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
            child: TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: translation(context: context, 'Last Name'),
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
          child: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: translation(context: context, 'Email'),
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: !isRegisterMode
                ? const [AutofillHints.username, AutofillHints.email]
                : null,
            autofocus: false,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              if (!isRegisterMode) {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  onLogin();
                } else {
                  FocusScope.of(context).nextFocus();
                }
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
            onSubmitted: (_) {
              if (!isRegisterMode) {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isNotEmpty && password.isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  onLogin();
                } else {
                  FocusScope.of(context).nextFocus();
                }
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        ),
        // Forgot password button (only in login mode)
        if (!isRegisterMode) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(translation(context: context, 'Forgot password?')),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
          child: TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: translation(context: context, 'Password'),
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: FocusScope(
                canRequestFocus: false,
                skipTraversal: true,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: IconButton(
                    icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: onTogglePassword,
                    tooltip: showPassword ? translation(context: context, 'Hide password') : translation(context: context, 'Show password'),
                  ),
                ),
              ),
            ),
            obscureText: !showPassword,
            autofillHints: !isRegisterMode
                ? const [AutofillHints.password]
                : null,
            textInputAction: isRegisterMode ? TextInputAction.next : TextInputAction.done,
            onEditingComplete: () {
              if (isRegisterMode) {
                FocusScope.of(context).nextFocus();
              } else {
                if (emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  onLogin();
                } else {
                  FocusScope.of(context).unfocus();
                }
              }
            },
            onSubmitted: (_) {
              if (isRegisterMode) {
                FocusScope.of(context).nextFocus();
              } else {
                if (emailController.text.trim().isNotEmpty && passwordController.text.trim().isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  onLogin();
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

// Modularized register extra fields (confirm password and place dropdown)
class _RegisterExtraFields extends StatelessWidget {
  final TextEditingController confirmPasswordController;
  final bool showConfirmPassword;
  final VoidCallback onToggleConfirmPassword;
  final PlaceModel? selectedPlace;
  final List<PlaceModel> places;
  final ValueChanged<PlaceModel?> onPlaceChanged;
  final VoidCallback onClearPlace;

  const _RegisterExtraFields({
    required this.confirmPasswordController,
    required this.showConfirmPassword,
    required this.onToggleConfirmPassword,
    required this.selectedPlace,
    required this.places,
    required this.onPlaceChanged,
    required this.onClearPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
          child: TextField(
            controller: confirmPasswordController,
            decoration: InputDecoration(
              labelText: translation(context: context, 'Confirm Password'),
              prefixIcon: Icon(Icons.lock_reset),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: FocusScope(
                canRequestFocus: false,
                skipTraversal: true,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: IconButton(
                    icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: onToggleConfirmPassword,
                    tooltip: showConfirmPassword ? translation(context: context, 'Hide password') : translation(context: context, 'Show password'),
                  ),
                ),
              ),
            ),
            obscureText: !showConfirmPassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _LoginPageState._formMaxWidth),
          child: DropdownButtonFormField<PlaceModel>(
            value: selectedPlace,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: places.map((place) => DropdownMenuItem<PlaceModel>(
              value: place,
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(place.displayName ?? '', style: const TextStyle(fontSize: 16)),
                ],
              ),
            )).toList(),
            onChanged: onPlaceChanged,
            decoration: InputDecoration(
              labelText: translation(context: context, 'Select Place'),
              prefixIcon: Icon(Icons.domain_outlined),
              suffixIcon: selectedPlace != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearPlace,
                      tooltip: translation(context: context, 'Clear selection'),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            menuMaxHeight: 300,
          ),
        ),
      ],
    );
  }
}

