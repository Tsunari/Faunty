import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:faunty/firestore/firestore_quota_service.dart';

final firestoreQuotaProvider = Provider<FirestoreQuotaService>((ref) {
  final svc = FirestoreQuotaService(flushThreshold: 100, samplingMultiplier: 2.5, enabled: false);
  // Initialize asynchronously but don't await here
  svc.init();
  ref.onDispose(() {
    svc.dispose();
  });
  return svc;
});
