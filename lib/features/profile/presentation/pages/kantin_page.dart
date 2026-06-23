import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/features/tracking/data/repositories/kantin_firestore_service.dart';
import 'package:faunty/core/widgets/custom_chip.dart';
import 'package:faunty/core/utils/translation_helper.dart';
import 'package:faunty/core/widgets/custom_snackbar.dart';
import 'package:faunty/features/tracking/presentation/controllers/kantin_provider.dart';
import 'package:faunty/features/auth/presentation/controllers/user_provider.dart';
import 'package:faunty/features/profile/presentation/controllers/user_list_provider.dart';
import 'package:faunty/features/auth/domain/entities/user_roles.dart';
import 'package:url_launcher/url_launcher.dart';

// Dummy-Produkte für die Chips
final List<Map<String, dynamic>> _dummyProducts = [
  {'name': 'Eis groß', 'price': 1.0},
  {'name': 'Eis klein', 'price': 0.5},
  {'name': 'Spezi', 'price': 1.0},
];

class KantinPage extends ConsumerStatefulWidget {
  const KantinPage({super.key});
  
    static PreferredSizeWidget appBar(
      BuildContext context,
      void Function() onPayPalPressed,
    ) {
      final ref = ProviderScope.containerOf(context);
      final user = ref.read(userProvider);
      final placeId = user.value?.placeId ?? '';
      final userUid = user.value?.uid ?? '';
      final kantinAsync = ref.read(kantinProvider(placeId));
      final debts = kantinAsync.asData?.value ?? {};
      final currentDebt = debts[userUid] ?? 0.0;

      return CustomAppBar(
        title: translation(context: context, 'Kantin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showCustomSnackBar(
                context,
                translation(context: context, 'A positive value means you owe money. A negative value means you have credit.'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: translation(context: context, 'Reset debt'),
            onPressed: userUid.isEmpty || currentDebt == 0
                ? null
                : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(translation(context: context, 'Reset debt')),
                  content: Text(translation(context: context, 'Are you sure you want to reset your debt to 0?')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(translation(context: context, 'Cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(translation(context: context, 'Confirm')),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await KantinFirestoreService(placeId).updateUserDebt(userUid, 0.0);
                showCustomSnackBar(context, translation(context: context, 'Debt reset!'));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: userUid.isEmpty || currentDebt <= 0
                ? null
                : onPayPalPressed,
            tooltip: 'Pay with PayPal',
          ),
        ],
      );
    }

  @override
  ConsumerState<KantinPage> createState() => _KantinPageState();
}


class _KantinPageState extends ConsumerState<KantinPage> with WidgetsBindingObserver {
  double _localDebt = 0.0;
  bool _isLoading = false;
  bool _pendingPaypal = false;

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
    if (state == AppLifecycleState.resumed && _pendingPaypal) {
      setState(() => _pendingPaypal = false);
      final user = ref.read(userProvider);
      final placeId = user.value?.placeId ?? '';
      final userUid = user.value?.uid ?? '';
      final kantinAsync = ref.read(kantinProvider(placeId));
      final debts = kantinAsync.asData?.value ?? {};
      final currentDebt = debts[userUid] ?? 0.0;
      final controller = TextEditingController(text: currentDebt.toStringAsFixed(2).replaceAll('.', ','));
      await showDialog(
        context: context,
        builder: (ctx) {
          bool showCustomAmount = false;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(translation(context: context, 'PayPal')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(translation(context: context, 'Did you pay ') + currentDebt.toStringAsFixed(2).replaceAll('.', ',') + translation(context: context, ' € via PayPal?')),
                  if (showCustomAmount) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        width: 180, // Reduced width
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
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
                  onPressed: () => setDialogState(() => showCustomAmount = !showCustomAmount),
                  child: Text('Different amount'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    double paid = showCustomAmount
                      ? double.tryParse(controller.text.replaceAll(',', '.')) ?? currentDebt
                      : currentDebt;
                    double newDebt = currentDebt - paid;
                    setState(() => _isLoading = true);
                    await KantinFirestoreService(placeId).updateUserDebt(userUid, newDebt);
                    setState(() {
                      _localDebt = newDebt;
                      _isLoading = false;
                    });
                    showCustomSnackBar(context, newDebt == 0 ? 'Debt reset!' : (newDebt < 0 ? 'You have credit!' : 'Debt updated!'));
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

    // Get all debts (Map<String, double>)
    final debts = kantinAsync.asData?.value ?? {};
    final currentDebt = debts[userUid] ?? 0.0;

    // For local UI update before Firestore stream updates
    final displayDebt = _isLoading ? _localDebt : currentDebt;

    Future<void> setDebt(double newDebt, String placeId, String userUid) async {
      if (newDebt > 999) {
        userRole == UserRole.hoca || userRole == UserRole.superuser
          ? showCustomSnackBar(context, translation(context: context, 'I sincerely apologize but you can not have more debt'))
          : showCustomSnackBar(context, translation(context: context, 'Bro pay your debt first'));
        return;
      }
      setState(() => _isLoading = true);
      await KantinFirestoreService(placeId).updateUserDebt(userUid, newDebt);
      setState(() {
        _localDebt = newDebt;
        _isLoading = false;
      });
    }

    return Scaffold(
      appBar: KantinPage.appBar(
        context,
        () async {
          final ref = ProviderScope.containerOf(context);
          final user = ref.read(userProvider);
          final placeId = user.value?.placeId ?? '';
          final userUid = user.value?.uid ?? '';
          final kantinAsync = ref.read(kantinProvider(placeId));
          final debts = kantinAsync.asData?.value ?? {};
          final currentDebt = debts[userUid] ?? 0.0;
          final url = Uri.parse('https://www.paypal.me/FatihKantin/${currentDebt.toStringAsFixed(2)}');
          debugPrint('[PayPal] Attempting to open: $url');
          setState(() => _pendingPaypal = true);
          final uri = Uri.parse(url.toString());
          if (await canLaunchUrl(uri)) {
            debugPrint('[PayPal] Launching URL...');
            await launchUrl(uri);
            debugPrint('[PayPal] URL launched successfully.');
          } else {
            debugPrint('[PayPal] canLaunchUrl returned false for: $url');
            showCustomSnackBar(context, 'Could not open PayPal.');
            setState(() => _pendingPaypal = false);
          }
        },
      ),
      body: kantinAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left buttons (abziehen)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading || userUid.isEmpty ? null : () => setDebt(displayDebt - 1.0, placeId, userUid),
                      child: const Text('-1', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading || userUid.isEmpty ? null : () => setDebt(displayDebt - 0.5, placeId, userUid),
                      child: const Text('-0,5', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Counter
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayDebt >= 0 ? translation(context: context, 'Debt') : translation(context: context, 'Credit'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, 
                        color: displayDebt > 0
                          ? Colors.red
                          : (displayDebt < 0 ? Colors.green : null),
                      ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isLoading || userUid.isEmpty
                        ? null
                        : () async {
                      final controller = TextEditingController(text: displayDebt.toStringAsFixed(2).replaceAll('.', ','));
                      final result = await showDialog<double>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(translation(context: context, 'Debt')),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: translation(context: context, 'Enter amount'),
                            ),
                            onSubmitted: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed != null) {
                                if (parsed > 999) {
                                    userRole == UserRole.hoca || userRole == UserRole.superuser
                                      ? showCustomSnackBar(context, translation(context: context, 'I sincerely apologize but you can not have more debt'))
                                      : showCustomSnackBar(context, translation(context: context, 'Bro pay your debt first'));
                                  Navigator.pop(context);
                                  return;
                                }
                                Navigator.pop(context, parsed);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            onTap: () {
                              controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(translation(context: context, 'Cancel')),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                                if (value != null) {
                                  if (value > 999) {
                                    userRole == UserRole.hoca || userRole == UserRole.superuser
                                      ? showCustomSnackBar(context, translation(context: context, 'I sincerely apologize but you can not have more debt'))
                                      : showCustomSnackBar(context, translation(context: context, 'Bro pay your debt first'));
                                    Navigator.pop(context);
                                    return;
                                  }
                                  Navigator.pop(context, value);
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(translation(context: context, 'Save')),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        await setDebt(result, placeId, userUid);
                      }
                    },
                    child: Text(
                        displayDebt.toStringAsFixed(2).replaceAll('.', ','),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Right buttons (hinzufügen)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading || userUid.isEmpty ? null : () => setDebt(displayDebt + 1.0, placeId, userUid),
                      child: const Text('+1', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading || userUid.isEmpty ? null : () => setDebt(displayDebt + 0.5, placeId, userUid),
                      child: const Text('+0,5', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Produktchips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final product in _dummyProducts)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoading || userUid.isEmpty ? null : () => setDebt(displayDebt + (product['price'] as double), placeId, userUid),
                  child: CustomContainerChip(
                    label: '${product['name']} ${product['price'].toString().replaceAll('.', ',')}',
                    // backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    // textColor: theme.colorScheme.primary,
                    fontSize: 12,
                    // fontWeight: FontWeight.w600,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    outlineColor: theme.colorScheme.primary.withAlpha(200),
                    // borderColor: theme.colorScheme.primary.withOpacity(0.5),
                    // borderWidth: 1.5,
                    // borderRadius: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          // Other users' debts
          Consumer(
            builder: (context, ref, _) {
              final usersAsync = ref.watch(usersByCurrentPlaceProvider);
              final users = usersAsync.asData?.value ?? [];
              final otherUsers = users.where((u) => u.uid != userUid && (u.role == UserRole.baskan || u.role == UserRole.talebe)).toList();
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
                "Snack whisperer."
              ];
              randomJoke(int seed) => jokes[(DateTime.now().millisecondsSinceEpoch + seed) % jokes.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation(context: context, 'Other users'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (otherUsers.isEmpty)
                      Text(translation(context: context, 'No other users found'))
                    else
                      ...otherUsers.map((user) => Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : user.uid.substring(0, 2).toUpperCase())),
                              title: Text('${user.firstName} ${user.lastName}'),
                              subtitle: Text(randomJoke(user.uid.hashCode)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${(debts[user.uid] ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')} €', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                                  const SizedBox(width: 8),
                                  // Edit button visible only to superusers
                                  if (userRole == UserRole.superuser)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip: translation(context: context, 'Edit debt'),
                                      onPressed: () async {
                                        final controller = TextEditingController(text: (debts[user.uid] ?? 0.0).toStringAsFixed(2).replaceAll('.', ','));
                                        final result = await showDialog<double>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(translation(context: context, 'Edit debt for') + ' ${user.firstName} ${user.lastName}'),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: InputDecoration(labelText: translation(context: context, 'Amount')),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(translation(context: context, 'Cancel'))),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final value = double.tryParse(controller.text.replaceAll(',', '.'));
                                                  if (value != null) Navigator.pop(ctx, value);
                                                },
                                                child: Text(translation(context: context, 'Save')),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (result != null) {
                                          if (result > 999) {
                                            if (context.mounted) showCustomSnackBar(context, translation(context: context, 'I sincerely apologize but you can not have more debt'));
                                            return;
                                          }
                                          await KantinFirestoreService(placeId).updateUserDebt(user.uid, result);
                                          if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Debt updated!'));
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ))
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
    final kantinAsync = ref.watch(kantinProvider(placeId));
    final debts = kantinAsync.asData?.value ?? {};
    final currentDebt = debts[userUid] ?? 0.0;

    Future<void> setDebt(double newDebt) async {
      if (newDebt > 999) {
        userRole == UserRole.hoca || userRole == UserRole.superuser
          ? showCustomSnackBar(context, translation(context: context, 'I sincerely apologize but you can not have more debt'))
          : showCustomSnackBar(context, translation(context: context, 'Bro pay your debt first'));
        return;
      }
      await KantinFirestoreService(placeId).updateUserDebt(userUid, newDebt);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: userUid.isEmpty ? null : () => setDebt(currentDebt - 1.0),
                borderRadius: BorderRadius.circular(8),
                child: CustomContainerChip(
                  label: "- 1", 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                onTap: userUid.isEmpty ? null : () => setDebt(currentDebt - 0.5),
                borderRadius: BorderRadius.circular(8),
                child: CustomContainerChip(
                  label: "- 0.5", 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              SizedBox(width: 16),
              GestureDetector(
                onTap: userUid.isEmpty
                    ? null
                    : () async {
                        final controller = TextEditingController(text: currentDebt.toStringAsFixed(2).replaceAll('.', ','));
                        final result = await showDialog<double>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(translation(context: context, 'Set Debt')),
                            content: TextField(
                              controller: controller,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: translation(context: context, 'Debt amount')),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(translation(context: context, 'Cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final value = double.tryParse(controller.text.replaceAll(',', '.'));
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
                child: Text(
                  currentDebt >= 0 
                  ? translation(context: context, 'Debt') + ': ' + currentDebt.toStringAsFixed(2).replaceAll('.', ',')
                  : translation(context: context, 'Credit') + ': ' + currentDebt.toStringAsFixed(2).replaceAll('.', ','),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: currentDebt > 0
                        ? Colors.red
                        : (currentDebt < 0 ? Colors.green : null),
                        // ? Colors.red
                        // : (currentDebt < 0 ? Colors.green : null),
                  ),
                ),
              ),
              SizedBox(width: 16),
              InkWell(
                onTap: userUid.isEmpty ? null : () => setDebt(currentDebt + 0.5),
                borderRadius: BorderRadius.circular(8),
                child: CustomContainerChip(
                  label: "+ 0,5", 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                onTap: userUid.isEmpty ? null : () => setDebt(currentDebt + 1.0),
                borderRadius: BorderRadius.circular(8),
                child: CustomContainerChip(
                  label: "+ 1", 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final product in _dummyProducts)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: userUid.isEmpty ? null : () => setDebt(currentDebt + (product['price'] as double)),
                  child: CustomContainerChip(
                    label: '${product['name']} ${product['price'].toString().replaceAll('.', ',')}',
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    outlineColor: theme.colorScheme.primary.withAlpha(180),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}