import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state_management/user_list_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../components/custom_snackbar.dart';
import '../../tools/translation_helper.dart';
import '../../tools/message_prefs.dart';
import 'notification_service.dart';

Widget _platformIcon(String platform) {
  switch (platform.toLowerCase()) {
    case 'android':
      return const Icon(Icons.android, color: Colors.green);
    case 'ios':
    case 'iphone':
      return const Icon(Icons.phone_iphone, color: Colors.blue);
    case 'web':
      return const Icon(Icons.language, color: Colors.orange);
    default:
      return const Icon(Icons.devices_other);
  }
}

String _formatTimestamp(Object ts) {
  try {
    if (ts is Timestamp) {
      final dt = ts.toDate().toLocal();
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (ts is DateTime) {
      final dt = ts.toLocal();
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  } catch (_) {
    return ts.toString();
  }
}

Future<void> showTokensDialog(BuildContext context, WidgetRef ref) async {
  final firestore = FirebaseFirestore.instance;

  Future<void> showEditMessageDialog(BuildContext parentCtx) async {
    final currentTitle = await getTestNotificationTitle();
    final currentBody = await getTestNotificationBody();
    final titleCtl = TextEditingController(text: currentTitle ?? 'Test notification');
    final bodyCtl = TextEditingController(text: currentBody ?? 'This is a test message.');
    await showDialog<void>(
      context: parentCtx.mounted ? parentCtx : context,
      builder: (c) => AlertDialog(
        title: Text(translation(context: parentCtx, 'Edit test notification message')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: InputDecoration(labelText: translation(context: parentCtx, 'Title')),
            ),
            TextField(
              controller: bodyCtl,
              decoration: InputDecoration(labelText: translation(context: parentCtx, 'Body')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(translation(context: parentCtx, 'Cancel'))),
          TextButton(onPressed: () async {
            try {
              await setTestNotificationTitle(titleCtl.text);
              await setTestNotificationBody(bodyCtl.text);
              if (parentCtx.mounted) showCustomSnackBar(parentCtx, translation(context: parentCtx, 'Saved'));
            } catch (e) {
              if (parentCtx.mounted) showCustomSnackBar(parentCtx, 'Save failed: $e');
            }
            if (context.mounted) Navigator.of(c).pop();
          }, child: Text(translation(context: parentCtx, 'Save'))),
        ],
      ),
    );
    titleCtl.dispose();
    bodyCtl.dispose();
  }

  // Query top-level fcm_tokens and group tokens by uid for display
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(translation(context: context, 'Saved FCM tokens'))),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: translation(context: context, 'Edit test notification message'),
            onPressed: () async {
              await showEditMessageDialog(ctx);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: translation(context: context, 'Check notification permission'),
            onPressed: () async {
              try {
                await NotificationService.checkAndRequestPermission(requestIfNot: true);
                if (context.mounted) {
                  showCustomSnackBar(context, translation(context: context, 'Notification permission checked'));
                }
              } catch (e) {
                if (context.mounted) {
                  showCustomSnackBar(context, 'Permission check failed: $e');
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: translation(context: context, 'Refresh tokens'),
            onPressed: () async {
              try {
                // Attempt to fetch token only when allowed (won't trigger browser prompt on web)
                final token = await NotificationService.fetchTokenIfAllowed();
                if (context.mounted) {
                  if (token != null) {
                    showCustomSnackBar(context, translation(context: context, 'Refreshed tokens'));
                  } else {
                    showCustomSnackBar(context, translation(context: context, 'No token fetched'));
                  }
                }
              } catch (e) {
                if (context.mounted) showCustomSnackBar(context, 'Refresh failed: $e');
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('fcm_tokens').orderBy('lastSeenAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            final tokenDocs = snapshot.data?.docs ?? [];
            if (tokenDocs.isEmpty) return Text(translation(context: context, 'No tokens found'));

            // Group tokens by uid
            final Map<String, List<QueryDocumentSnapshot>> byUser = {};
            for (final d in tokenDocs) {
              final data = d.data() as Map<String, dynamic>?;
              final uid = data?['uid'] ?? 'unknown';
              byUser.putIfAbsent(uid, () => []).add(d);
            }

            final entries = byUser.entries.toList();

            // Use cached provider data first, then batch-fetch only missing uids
            final allUsersAsync = ref.watch(allUsersProvider);
            final Map<String, String> providerNames = {};
            final usersList = allUsersAsync.asData?.value;
            if (usersList != null) {
              for (final u in usersList) {
                final full = '${u.firstName} ${u.lastName}'.trim();
                providerNames[u.uid] = full.isNotEmpty ? full : u.uid;
              }
            }

            final uids = entries.map((e) => e.key).where((u) => u != 'unknown').toList();
            final missing = uids.where((u) => !providerNames.containsKey(u)).toList();
            final Future<List<DocumentSnapshot>> usersFuture = missing.isEmpty
                ? Future.value([])
                : Future.wait(missing.map((u) => firestore.collection('user_list').doc(u).get()));

            return FutureBuilder<List<DocumentSnapshot>>(
              future: usersFuture,
              builder: (context, usersSnap) {
                final Map<String, String> displayNames = {...providerNames};
                if (usersSnap.hasData) {
                  for (final ds in usersSnap.data!) {
                    if (ds.exists) {
                      final d = ds.data() as Map<String, dynamic>?;
                      final name = (d?['firstName'] ?? '').toString().trim();
                      final last = (d?['lastName'] ?? '').toString().trim();
                      final full = [name, last].where((s) => s.isNotEmpty).join(' ');
                      displayNames[ds.id] = full.isNotEmpty ? full : ds.id;
                    }
                  }
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, idx) {
                    final uid = entries[idx].key;
                    final tokens = entries[idx].value;
                    final resolvedName = displayNames[uid] ?? (uid == 'unknown' ? uid : translation(context: context, 'Loading...'));
                    return ExpansionTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(resolvedName),
                      subtitle: uid == 'unknown' ? Text(uid, style: const TextStyle(fontSize: 12)) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_all),
                        tooltip: translation(context: context, 'Copy all tokens for user'),
                        onPressed: () async {
                          final all = tokens.map((t) => t.id).join('\n');
                          await Clipboard.setData(ClipboardData(text: all));
                          if (context.mounted) showCustomSnackBar(context, translation(context: context, 'All tokens copied'));
                        },
                      ),
                      children: tokens.map((t) {
                        final data = t.data() as Map<String, dynamic>;
                        final platform = data['platform'] ?? '?';
                        final lastSeen = data['lastSeenAt'];
                        String subtitle = 'platform: $platform';
                        if (lastSeen != null) subtitle += ' • lastSeen: ${_formatTimestamp(lastSeen)}';
                        return ListTile(
                          leading: _platformIcon(platform),
                          title: Text(t.id, overflow: TextOverflow.ellipsis),
                          subtitle: Text(subtitle),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: translation(context: context, 'Copy token'),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: t.id));
                                  if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Token copied'));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                tooltip: translation(context: context, 'Send test notification'),
                                onPressed: () async {
                                  try {
                                    if (t.id.trim().isEmpty) throw Exception('Token is empty');
                                    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                                    final callable = functions.httpsCallable('testNotification');
                                    final storedTitle = await getTestNotificationTitle();
                                    final storedBody = await getTestNotificationBody();
                                    final platform = (t.data() as Map<String, dynamic>)['platform'] ?? 'device';
                                    final safeTokenPreview = t.id.length > 20 ? '${t.id.substring(0, 20)}...' : t.id;
                                    final title = (storedTitle?.isNotEmpty ?? false) ? storedTitle! : 'Test notification — $platform';
                                    final body = (storedBody?.isNotEmpty ?? false) ? storedBody! : 'Token: $safeTokenPreview';
                                    final result = await callable.call(<String, dynamic>{'token': t.id, 'title': title, 'body': body});
                                    if (context.mounted && kDebugMode) showCustomSnackBar(context, '${translation(context: context, 'Test notification sent')}: ${result.data}');
                                  } catch (e) {
                                    if (context.mounted) showCustomSnackBar(context, 'Send failed: $e');
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: translation(context: context, 'Delete token'),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: Text(translation(context: context, 'Delete token?')),
                                      content: Text(translation(context: context, 'Are you sure you want to delete this FCM token?')),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(translation(context: context, 'Cancel'))),
                                        TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text(translation(context: context, 'Delete'))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await firestore.collection('fcm_tokens').doc(t.id).delete();
                                      if (context.mounted) showCustomSnackBar(context, translation(context: context, 'Token deleted'));
                                    } catch (e) {
                                      if (context.mounted) showCustomSnackBar(context, 'Delete failed: $e');
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(translation(context: context, 'Close'))),
      ],
    ),
  );
}
