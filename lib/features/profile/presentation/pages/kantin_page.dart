import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/tracking/data/repositories/kantin_firestore_service.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/tracking/presentation/controllers/kantin_provider.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:faunty/features/profile/data/repositories/globals_firestore_service.dart';
import 'package:faunty/features/profile/presentation/controllers/globals_provider.dart';
import 'package:faunty/core/widgets/custom_confirm_dialog.dart';

// Dummy-Produkte für die Chips
final List<Map<String, dynamic>> _dummyProducts = [
  {'name': 'Eis groß', 'price': 1.0},
  {'name': 'Eis klein', 'price': 0.5},
  {'name': 'Spezi', 'price': 1.0},
];

final pendingPaypalProvider = StateProvider<bool>((ref) => false);

class KantinPage extends ConsumerStatefulWidget {
  final bool isTab;
  const KantinPage({super.key, this.isTab = true});

  @override
  ConsumerState<KantinPage> createState() => _KantinPageState();
}

class _KantinPageState extends ConsumerState<KantinPage>
    with WidgetsBindingObserver {
  double _localDebt = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    final pendingPaypal = ref.read(pendingPaypalProvider);
    if (state == AppLifecycleState.resumed && pendingPaypal) {
      ref.read(pendingPaypalProvider.notifier).state = false;
      if (!mounted) return;
      final user = ref.read(userProvider);
      final placeId = user.value?.placeId ?? '';
      final userUid = user.value?.uid ?? '';
      final kantinAsync = ref.read(kantinProvider(placeId));
      final debts = kantinAsync.asData?.value ?? {};
      final currentDebt = debts[userUid] ?? 0.0;
      final controller = TextEditingController(
        text: currentDebt.toStringAsFixed(2).replaceAll('.', ','),
      );
      await showDialog(
        context: context,
        builder: (ctx) {
          bool showCustomAmount = false;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Center(
                child: Text(
                  translation(context: context, 'PayPal'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    translation(context: context, 'Did you pay ') +
                        currentDebt.toStringAsFixed(2).replaceAll('.', ',') +
                        translation(context: context, ' € via PayPal?'),
                  ),
                  if (showCustomAmount) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 180, // Reduced width
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Enter amount here',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(translation(context: context, 'Cancel')),
                ),
                TextButton(
                  onPressed: () => setDialogState(
                    () => showCustomAmount = !showCustomAmount,
                  ),
                  child: Text('Different amount'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    double paid = showCustomAmount
                        ? double.tryParse(
                                controller.text.replaceAll(',', '.'),
                              ) ??
                              currentDebt
                        : currentDebt;
                    double newDebt = currentDebt - paid;
                    if (!mounted) return;
                    setState(() => _isLoading = true);
                    await KantinFirestoreService(
                      placeId,
                    ).updateUserDebt(userUid, newDebt);
                    if (!mounted) return;
                    setState(() {
                      _localDebt = newDebt;
                      _isLoading = false;
                    });
                    showCustomSnackBar(
                      context,
                      newDebt == 0
                          ? 'Debt reset!'
                          : (newDebt < 0
                                ? 'You have credit!'
                                : 'Debt updated!'),
                    );
                  },
                  child: Text(translation(context: context, 'Yes')),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get current user and placeId from providers
    final user = ref.watch(userProvider);
    final placeId = user.value?.placeId ?? '';
    final userUid = user.value?.uid ?? '';
    final userRole = user.value?.role;
    final kantinAsync = ref.watch(kantinProvider(placeId));

    // Watch globals for custom PayPal link
    final globalsAsync = ref.watch(globalsProvider);

    // Get all debts (Map<String, double>)
    final debts = kantinAsync.asData?.value ?? {};
    final currentDebt = debts[userUid] ?? 0.0;

    // For local UI update before Firestore stream updates
    final displayDebt = _isLoading ? _localDebt : currentDebt;
    final isDark = theme.brightness == Brightness.dark;
    final Color balanceColor = displayDebt > 0
        ? Colors.red
        : (displayDebt < 0 ? Colors.green : theme.colorScheme.primary);

    if (widget.isTab) {
      final currentConfig = ref.read(tabAppBarConfigProvider('Kantin'));
      if (currentConfig == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(tabAppBarConfigProvider('Kantin').notifier)
              .state = TabAppBarConfig(
            actions: [
              KantinAppBarActions(placeId: placeId),
            ],
          );
        });
      }
    }

    Future<void> setDebt(double newDebt, String placeId, String userUid) async {
      if (newDebt > 999) {
        userRole == UserRole.hoca || userRole == UserRole.superuser
            ? showCustomSnackBar(
                context,
                translation(
                  context: context,
                  'I sincerely apologize but you can not have more debt',
                ),
              )
            : showCustomSnackBar(
                context,
                translation(context: context, 'Bro pay your debt first'),
              );
        return;
      }
      setState(() => _isLoading = true);
      await KantinFirestoreService(placeId).updateUserDebt(userUid, newDebt);
      if (!mounted) return;
      setState(() {
        _localDebt = newDebt;
        _isLoading = false;
      });
    }

    Future<void> payWithPayPal() async {
      final user = ref.read(userProvider).value;
      final placeId = user?.placeId ?? '';
      final userUid = user?.uid ?? '';
      final kantinAsync = ref.read(kantinProvider(placeId));
      final debts = kantinAsync.asData?.value ?? {};
      final currentDebt = debts[userUid] ?? 0.0;

      final globals = ref.read(globalsProvider).value;
      final paypalLinkValue = globals?.paypalLink ?? 'FatihKantin';

      if (userUid.isEmpty || currentDebt <= 0) return;

      final uri = buildPayPalUri(paypalLinkValue, currentDebt);
      debugPrint('[PayPal] Attempting to open: $uri');
      ref.read(pendingPaypalProvider.notifier).state = true;
      if (await canLaunchUrl(uri)) {
        debugPrint('[PayPal] Launching URL...');
        await launchUrl(uri);
        debugPrint('[PayPal] URL launched successfully.');
      } else {
        debugPrint('[PayPal] canLaunchUrl returned false for: $uri');
        ref.read(pendingPaypalProvider.notifier).state = false;
        if (mounted) {
          showCustomSnackBar(context, 'Could not open PayPal.');
        }
      }
    }

    return Scaffold(
      appBar: widget.isTab
          ? null
          : CustomAppBar(
              title: translation(context: context, 'Kantin'),
              actions: [
                KantinAppBarActions(
                  placeId: placeId,
                  onPayPalPressed: payWithPayPal,
                ),
              ],
            ),
      body: kantinAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 450;

                        final leftButtons = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  foregroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading || userUid.isEmpty
                                    ? null
                                    : () => setDebt(
                                        displayDebt - 1.0,
                                        placeId,
                                        userUid,
                                      ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '-1€',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 80,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  foregroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading || userUid.isEmpty
                                    ? null
                                    : () => setDebt(
                                        displayDebt - 0.5,
                                        placeId,
                                        userUid,
                                      ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '-0,5€',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );

                        final rightButtons = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading || userUid.isEmpty
                                    ? null
                                    : () => setDebt(
                                        displayDebt + 1.0,
                                        placeId,
                                        userUid,
                                      ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '+1€',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 80,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading || userUid.isEmpty
                                    ? null
                                    : () => setDebt(
                                        displayDebt + 0.5,
                                        placeId,
                                        userUid,
                                      ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '+0,5€',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );

                        final circularCard = Container(
                          width: isNarrow ? 160 : 180,
                          height: isNarrow ? 160 : 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: balanceColor.withOpacity(
                              isDark ? 0.12 : 0.08,
                            ),
                            border: Border.all(
                              color: balanceColor.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: balanceColor.withOpacity(0.06),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isLoading || userUid.isEmpty
                                  ? null
                                  : () async {
                                      final controller = TextEditingController(
                                        text: displayDebt
                                            .toStringAsFixed(2)
                                            .replaceAll('.', ','),
                                      );
                                      final result = await showDialog<double>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          title: Center(
                                            child: Text(
                                              translation(
                                                context: context,
                                                'Debt',
                                              ),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: translation(
                                                context: context,
                                                'Enter amount',
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onSubmitted: (value) {
                                              final parsed = double.tryParse(
                                                value.replaceAll(',', '.'),
                                              );
                                              if (parsed != null) {
                                                if (parsed > 999) {
                                                  userRole == UserRole.hoca ||
                                                          userRole ==
                                                              UserRole.superuser
                                                      ? showCustomSnackBar(
                                                          context,
                                                          translation(
                                                            context: context,
                                                            'I sincerely apologize but you can not have more debt',
                                                          ),
                                                        )
                                                      : showCustomSnackBar(
                                                          context,
                                                          translation(
                                                            context: context,
                                                            'Bro pay your debt first',
                                                          ),
                                                        );
                                                  Navigator.pop(context);
                                                  return;
                                                }
                                                Navigator.pop(context, parsed);
                                              } else {
                                                Navigator.pop(context);
                                              }
                                            },
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                translation(
                                                  context: context,
                                                  'Cancel',
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                final value = double.tryParse(
                                                  controller.text.replaceAll(
                                                    ',',
                                                    '.',
                                                  ),
                                                );
                                                if (value != null) {
                                                  if (value > 999) {
                                                    userRole == UserRole.hoca ||
                                                            userRole ==
                                                                UserRole
                                                                    .superuser
                                                        ? showCustomSnackBar(
                                                            context,
                                                            translation(
                                                              context: context,
                                                              'I sincerely apologize but you can not have more debt',
                                                            ),
                                                          )
                                                        : showCustomSnackBar(
                                                            context,
                                                            translation(
                                                              context: context,
                                                              'Bro pay your debt first',
                                                            ),
                                                          );
                                                    Navigator.pop(context);
                                                    return;
                                                  }
                                                  Navigator.pop(context, value);
                                                } else {
                                                  Navigator.pop(context);
                                                }
                                              },
                                              child: Text(
                                                translation(
                                                  context: context,
                                                  'Save',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result != null) {
                                        await setDebt(result, placeId, userUid);
                                      }
                                    },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    displayDebt >= 0
                                        ? translation(context: context, 'Debt')
                                        : translation(
                                            context: context,
                                            'Credit',
                                          ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: balanceColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                      ),
                                      child: Text(
                                        displayDebt
                                            .abs()
                                            .toStringAsFixed(2)
                                            .replaceAll('.', ','),
                                        style: TextStyle(
                                          fontSize: isNarrow ? 26 : 30,
                                          fontWeight: FontWeight.w900,
                                          color: balanceColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '€',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: balanceColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              circularCard,
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  leftButtons,
                                  const SizedBox(width: 40),
                                  rightButtons,
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            leftButtons,
                            const SizedBox(width: 24),
                            circularCard,
                            const SizedBox(width: 24),
                            rightButtons,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Product chips list
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final product in globalsAsync.value?.kantinProducts ?? _dummyProducts)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isLoading || userUid.isEmpty
                                  ? null
                                  : () => setDebt(
                                      displayDebt +
                                          (product['price'] as double),
                                      placeId,
                                      userUid,
                                    ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.18),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        product['name']
                                                .toString()
                                                .toLowerCase()
                                                .contains('eis')
                                            ? Icons.icecream_rounded
                                            : Icons.local_drink_rounded,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${product['price'].toString().replaceAll('.', ',')} €',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Other users' debts
                    Consumer(
                      builder: (context, ref, _) {
                        final usersAsync = ref.watch(
                          usersByCurrentPlaceProvider,
                        );
                        final users = usersAsync.asData?.value ?? [];
                        final otherUsers = users
                            .where(
                              (u) =>
                                  u.uid != userUid &&
                                  (u.role == UserRole.baskan ||
                                      u.role == UserRole.talebe),
                            )
                            .toList();
                        final jokes = [
                          "Buys snacks like they're stocks.",
                          "Thinks cola is a personality trait.",
                          "Has a PhD in impulse buying.",
                          "Can’t resist a good deal on water.",
                          "Eats ice cream for breakfast.",
                          "Believes Spezi is the drink of champions.",
                          "Always asks for extra napkins.",
                          "Thinks every day is treat day.",
                          "Has a secret stash of snacks.",
                          "Buys more than they can carry.",
                          "Knows the vending machine by heart.",
                          "Can’t say no to a bargain.",
                          "Thinks buying snacks is cardio.",
                          "Has a loyalty card for everything.",
                          "Snacks are their spirit animal.",
                          "Can turn any purchase into a story.",
                          "Thinks debt is just snack points.",
                          "Always finds a reason to celebrate with food.",
                          "Buys drinks for the squad.",
                          "Snack shopping: their superpower.",
                          "Buys snacks faster than WiFi.",
                          "Thinks every coin is for the Kantin.",
                          "Can spot a discount from a mile away.",
                          "Snack debt collector in training.",
                          "Has a sixth sense for fresh pastries.",
                          "Can turn pocket change into a feast.",
                          "Snack budget: unlimited.",
                          "Knows the snack lady by name.",
                          "Can negotiate snack prices in three languages.",
                          "Snack run champion.",
                          "Invented the snack break.",
                          "Can eat three ice creams in one sitting.",
                          "Thinks calories don’t count in Kantin.",
                          "Snack connoisseur since birth.",
                          "Can make a meal out of snacks.",
                          "Snack math expert.",
                          "Has a snack radar.",
                          "Snack enthusiast, debt specialist.",
                          "Snack queue VIP.",
                          "Snack whisperer.",
                        ];
                        randomJoke(int seed) =>
                            jokes[(DateTime.now().millisecondsSinceEpoch +
                                    seed) %
                                jokes.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translation(context: context, 'Other users'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (otherUsers.isEmpty)
                                Text(
                                  translation(
                                    context: context,
                                    'No other users found',
                                  ),
                                )
                              else
                                ...otherUsers.map(
                                  (user) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.12),
                                        child: Text(
                                          user.firstName.isNotEmpty
                                              ? user.firstName[0].toUpperCase()
                                              : user.uid
                                                    .substring(0, 2)
                                                    .toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        '${user.firstName} ${user.lastName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        randomJoke(user.uid.hashCode),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.55),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final otherDebt =
                                                  debts[user.uid] ?? 0.0;
                                              final otherDebtColor =
                                                  otherDebt > 0
                                                  ? const Color(
                                                      0xFFEF4444,
                                                    ) // Modern red
                                                  : (otherDebt < 0
                                                        ? const Color(
                                                            0xFF10B981,
                                                          )
                                                        : theme
                                                              .colorScheme
                                                              .primary);
                                              return Text(
                                                '${otherDebt.toStringAsFixed(2).replaceAll('.', ',')} €',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: otherDebtColor,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          // Edit button visible only to superusers
                                          if (userRole == UserRole.superuser)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_rounded,
                                                size: 20,
                                              ),
                                              tooltip: translation(
                                                context: context,
                                                'Edit debt',
                                              ),
                                              onPressed: () async {
                                                final controller =
                                                    TextEditingController(
                                                      text:
                                                          (debts[user.uid] ??
                                                                  0.0)
                                                              .toStringAsFixed(
                                                                2,
                                                              )
                                                              .replaceAll(
                                                                '.',
                                                                ',',
                                                              ),
                                                    );
                                                final result = await showDialog<double>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                    ),
                                                    title: Center(
                                                      child: Text(
                                                        translation(
                                                              context: context,
                                                              'Edit debt for',
                                                            ) +
                                                            ' ${user.firstName} ${user.lastName}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                    content: TextField(
                                                      controller: controller,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      decoration: InputDecoration(
                                                        labelText: translation(
                                                          context: context,
                                                          'Amount',
                                                        ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx),
                                                        child: Text(
                                                          translation(
                                                            context: context,
                                                            'Cancel',
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          final value =
                                                              double.tryParse(
                                                                controller.text
                                                                    .replaceAll(
                                                                      ',',
                                                                      '.',
                                                                    ),
                                                              );
                                                          if (value != null)
                                                            Navigator.pop(
                                                              ctx,
                                                              value,
                                                            );
                                                        },
                                                        child: Text(
                                                          translation(
                                                            context: context,
                                                            'Save',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (result != null) {
                                                  if (result > 999) {
                                                    if (context.mounted)
                                                      showCustomSnackBar(
                                                        context,
                                                        translation(
                                                          context: context,
                                                          'I sincerely apologize but you can not have more debt',
                                                        ),
                                                      );
                                                    return;
                                                  }
                                                  await KantinFirestoreService(
                                                    placeId,
                                                  ).updateUserDebt(
                                                    user.uid,
                                                    result,
                                                  );
                                                  if (context.mounted)
                                                    showCustomSnackBar(
                                                      context,
                                                      translation(
                                                        context: context,
                                                        'Debt updated!',
                                                      ),
                                                    );
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CantineWidget extends ConsumerWidget {
  final String placeId;
  final String userUid;
  final UserRole? userRole;
  const CantineWidget({
    super.key,
    required this.placeId,
    required this.userUid,
    this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final kantinAsync = ref.watch(kantinProvider(placeId));
    final globalsAsync = ref.watch(globalsProvider);
    final debts = kantinAsync.asData?.value ?? {};
    final currentDebt = debts[userUid] ?? 0.0;

    Future<void> setDebt(double newDebt) async {
      if (newDebt > 999) {
        userRole == UserRole.hoca || userRole == UserRole.superuser
            ? showCustomSnackBar(
                context,
                translation(
                  context: context,
                  'I sincerely apologize but you can not have more debt',
                ),
              )
            : showCustomSnackBar(
                context,
                translation(context: context, 'Bro pay your debt first'),
              );
        return;
      }
      await KantinFirestoreService(placeId).updateUserDebt(userUid, newDebt);
    }

    final balanceColor = currentDebt > 0
        ? Colors.redAccent
        : (currentDebt < 0 ? Colors.greenAccent : theme.colorScheme.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation(context: context, 'Cantine'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    translation(
                      context: context,
                      'Quick balance & product checkout',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Balance Display Card & Quick Adjust Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 350;

            // Balance Indicator Card
            final balanceCard = GestureDetector(
              onTap: userUid.isEmpty
                  ? null
                  : () async {
                      final controller = TextEditingController(
                        text: currentDebt
                            .toStringAsFixed(2)
                            .replaceAll('.', ','),
                      );
                      final result = await showDialog<double>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Center(
                            child: Text(
                              translation(context: context, 'Set Debt'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: translation(
                                context: context,
                                'Debt amount',
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                translation(context: context, 'Cancel'),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final value = double.tryParse(
                                  controller.text.replaceAll(',', '.'),
                                );
                                if (value != null) {
                                  Navigator.pop(context, value);
                                }
                              },
                              child: Text(translation(context: context, 'Set')),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        await setDebt(result);
                      }
                    },
              child: Container(
                width: isNarrow ? double.infinity : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: balanceColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: balanceColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentDebt >= 0
                          ? translation(context: context, 'Debt')
                          : translation(context: context, 'Credit'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${currentDebt.abs().toStringAsFixed(2).replaceAll('.', ',')} €',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: balanceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            // Quick Actions
            final quickActions = Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickAdjustButton(
                        label: '- 1,00 €',
                        onTap: userUid.isEmpty
                            ? null
                            : () => setDebt(currentDebt - 1.0),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickAdjustButton(
                        label: '- 0,50 €',
                        onTap: userUid.isEmpty
                            ? null
                            : () => setDebt(currentDebt - 0.5),
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAdjustButton(
                        label: '+ 0,50 €',
                        onTap: userUid.isEmpty
                            ? null
                            : () => setDebt(currentDebt + 0.5),
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QuickAdjustButton(
                        label: '+ 1,00 €',
                        onTap: userUid.isEmpty
                            ? null
                            : () => setDebt(currentDebt + 1.0),
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            );

            return isNarrow
                ? Column(
                    children: [
                      balanceCard,
                      const SizedBox(height: 12),
                      quickActions,
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: balanceCard),
                        const SizedBox(width: 12),
                        Expanded(child: quickActions),
                      ],
                    ),
                  );
          },
        ),
        const SizedBox(height: 16),
        // Product Quick Checkout Row
        Text(
          translation(context: context, 'Quick buy:'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final product in globalsAsync.value?.kantinProducts ?? _dummyProducts)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: userUid.isEmpty
                    ? null
                    : () => setDebt(currentDebt + (product['price'] as double)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product['name'].toString().toLowerCase().contains('eis')
                            ? Icons.icecream_rounded
                            : Icons.local_drink_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${product['name']} (${product['price'].toString().replaceAll('.', ',')} €)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Uri buildPayPalUri(String paypalInput, double amount) {
  final amountStr = amount.toStringAsFixed(2);
  String username = paypalInput.trim();
  if (username.startsWith('https://')) {
    username = username.substring('https://'.length);
  }
  if (username.startsWith('http://')) {
    username = username.substring('http://'.length);
  }
  if (username.startsWith('www.')) {
    username = username.substring('www.'.length);
  }
  if (username.startsWith('paypal.me/')) {
    username = username.substring('paypal.me/'.length);
  }
  while (username.endsWith('/')) {
    username = username.substring(0, username.length - 1);
  }
  if (username.isEmpty) username = 'FatihKantin';
  return Uri.parse('https://www.paypal.me/$username/$amountStr');
}

Future<void> _showPayPalSettingsDialog(
  BuildContext context,
  dynamic refOrContainer,
  String placeId,
) async {
  final GlobalsState? globals = refOrContainer is WidgetRef
      ? refOrContainer.read(globalsProvider).value
      : (refOrContainer as ProviderContainer).read(globalsProvider).value;
  final currentLink = globals?.paypalLink ?? 'FatihKantin';
  final controller = TextEditingController(text: currentLink);

  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Center(
        child: Text(
          translation(context: ctx, 'Set PayPal Link'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: translation(context: ctx, 'PayPal Username or Link'),
          hintText: 'e.g. FatihKantin or https://www.paypal.me/FatihKantin',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(translation(context: ctx, 'Cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(translation(context: ctx, 'Save')),
        ),
      ],
    ),
  );

  if (result != null) {
    final service = GlobalsFirestoreService(placeId);
    await service.setGlobalField('paypalLink', result);
    if (context.mounted) {
      showCustomSnackBar(
        context,
        translation(context: context, 'PayPal link updated!'),
      );
    }
  }
}

Future<void> _showManageProductsDialog(
  BuildContext context,
  dynamic refOrContainer,
  String placeId,
) async {
  final GlobalsState? globals = refOrContainer is WidgetRef
      ? refOrContainer.read(globalsProvider).value
      : (refOrContainer as ProviderContainer).read(globalsProvider).value;
  
  final currentProducts = List<Map<String, dynamic>>.from(
    globals?.kantinProducts ?? [
      {'name': 'Eis groß', 'price': 1.0},
      {'name': 'Eis klein', 'price': 0.5},
      {'name': 'Spezi', 'price': 1.0},
    ],
  );

  final updatedProducts = await showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (ctx) {
      final products = List<Map<String, dynamic>>.from(currentProducts);
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Center(
              child: Text(
                translation(context: context, 'Manage Canteen Products'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${(product['price'] as double).toStringAsFixed(2).replaceAll('.', ',')} €'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                products.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(translation(context: context, 'Add Product')),
                    onPressed: () async {
                      final nameController = TextEditingController();
                      final priceController = TextEditingController();
                      final newProduct = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (subCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: Center(
                            child: Text(
                              translation(context: subCtx, 'Add Product'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: translation(context: subCtx, 'Product Name'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: translation(context: subCtx, 'Price (€)'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(subCtx),
                              child: Text(translation(context: subCtx, 'Cancel')),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                                if (name.isNotEmpty && price != null) {
                                  Navigator.pop(subCtx, {'name': name, 'price': price});
                                }
                              },
                              child: Text(translation(context: subCtx, 'Add')),
                            ),
                          ],
                        ),
                      );
                      if (newProduct != null) {
                        setState(() {
                          products.add(newProduct);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translation(context: context, 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, products),
                child: Text(translation(context: context, 'Save')),
              ),
            ],
          );
        },
      );
    },
  );

  if (updatedProducts != null) {
    final service = GlobalsFirestoreService(placeId);
    await service.setGlobalField('kantinProducts', updatedProducts);
    if (context.mounted) {
      showCustomSnackBar(
        context,
        translation(context: context, 'Products updated!'),
      );
    }
  }
}

class _QuickAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _QuickAdjustButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KantinAppBarActions extends ConsumerWidget {
  final String placeId;
  final VoidCallback? onPayPalPressed;

  const KantinAppBarActions({
    super.key,
    required this.placeId,
    this.onPayPalPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider).value;
    final userUid = user?.uid ?? '';
    final userRole = user?.role;
    final isBaskanOrHigher = userRole == UserRole.baskan || userRole == UserRole.hoca || userRole == UserRole.superuser;

    final kantinAsync = ref.watch(kantinProvider(placeId));
    final debts = kantinAsync.asData?.value ?? {};
    final currentDebt = debts[userUid] ?? 0.0;

    final globalsAsync = ref.watch(globalsProvider);
    final paypalLinkValue = globalsAsync.value?.paypalLink ?? 'FatihKantin';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBaskanOrHigher) ...[
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: translation(context: context, 'Set PayPal link'),
            onPressed: () => _showPayPalSettingsDialog(context, ref, placeId),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu_rounded),
            tooltip: translation(context: context, 'Manage products'),
            onPressed: () => _showManageProductsDialog(context, ref, placeId),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showCustomSnackBar(
              context,
              translation(
                context: context,
                'A positive value means you owe money. A negative value means you have credit.',
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: translation(context: context, 'Reset debt'),
          onPressed: userUid.isEmpty || currentDebt == 0
              ? null
              : () async {
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: translation(context: context, 'Reset debt'),
                    content: Text(
                      translation(
                        context: context,
                        'Are you sure you want to reset your debt to 0?',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    cancelText: translation(context: context, 'Cancel'),
                    confirmText: translation(context: context, 'Confirm'),
                  );
                  if (confirmed == true) {
                    await KantinFirestoreService(placeId).updateUserDebt(userUid, 0.0);
                    if (context.mounted) {
                      showCustomSnackBar(
                        context,
                        translation(context: context, 'Debt reset!'),
                      );
                    }
                  }
                },
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          onPressed: userUid.isEmpty || currentDebt <= 0
              ? null
              : onPayPalPressed ?? () async {
                  // Fallback for standalone/no-state modes or directly launching
                  final uri = buildPayPalUri(paypalLinkValue, currentDebt);
                  debugPrint('[PayPal Actions Fallback] Attempting to open: $uri');
                  ref.read(pendingPaypalProvider.notifier).state = true;
                  if (await canLaunchUrl(uri)) {
                    debugPrint('[PayPal Actions Fallback] Launching URL...');
                    await launchUrl(uri);
                    debugPrint('[PayPal Actions Fallback] URL launched successfully.');
                  } else {
                    debugPrint('[PayPal Actions Fallback] canLaunchUrl returned false for: $uri');
                    ref.read(pendingPaypalProvider.notifier).state = false;
                    if (context.mounted) {
                      showCustomSnackBar(context, 'Could not open PayPal.');
                    }
                  }
                },
          tooltip: 'Pay with PayPal',
        ),
      ],
    );
  }
}

