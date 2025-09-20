import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FirestoreQuotaService
///
/// - Buffers increments for reads/writes/deletes and persists the buffer to
///   SharedPreferences so counts survive app restarts.
/// - Flushes when any buffer reaches [flushThreshold] or periodically.
/// - Uses probabilistic sampling for reads: samplingProbability = 1 / samplingMultiplier
///   When flushing, read increments are multiplied by [samplingMultiplier].
/// - Caches `globals/config` locally via a snapshot listener so we avoid reading it per-op.
/// - When flushing, performs a transaction: reads today's counter and config, computes
///   the new total with the flushed increment, and if it exceeds the threshold it sets
///   `globals/config.disabledUntil` to the end of the day.
class FirestoreQuotaService {
  final FirebaseFirestore _db;
  final int flushThreshold;
  final double samplingMultiplier; // e.g. 2.5
  final Duration periodicFlushInterval;
  final bool enabled;

  static const _prefsKeyReads = 'quota_buffer_reads';
  static const _prefsKeyWrites = 'quota_buffer_writes';
  static const _prefsKeyDeletes = 'quota_buffer_deletes';

  int _bufferedReads = 0; // sampled counts
  int _bufferedWrites = 0;
  int _bufferedDeletes = 0;

  // cached config fields
  Map<String, dynamic>? _cachedConfig;

  Timer? _periodicFlushTimer;
  SharedPreferences? _prefs;
  final Random _random = Random();

  FirestoreQuotaService({
    FirebaseFirestore? firestore,
    this.flushThreshold = 100,
    this.samplingMultiplier = 2.5,
    this.periodicFlushInterval = const Duration(seconds: 30),
    this.enabled = true,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  /// Convenience disabled constructor
  FirestoreQuotaService.disabled({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        flushThreshold = 100,
        samplingMultiplier = 2.5,
        periodicFlushInterval = const Duration(seconds: 30),
        enabled = false;

  /// Must be called once at app startup to initialize prefs and start listeners.
  Future<void> init() async {
    if (!enabled) return;
    _prefs = await SharedPreferences.getInstance();
    _bufferedReads = _prefs?.getInt(_prefsKeyReads) ?? 0;
    _bufferedWrites = _prefs?.getInt(_prefsKeyWrites) ?? 0;
    _bufferedDeletes = _prefs?.getInt(_prefsKeyDeletes) ?? 0;

    // start listening to globals/config so we have a local cached copy
    _db.doc('globals/config').snapshots().listen((snap) {
      _cachedConfig = snap.exists ? snap.data() : null;
    });

  // NOTE: periodic flush timer disabled for now. Flushing will be triggered
  // by buffer thresholds or explicit calls to `flushNow()`.
  // _periodicFlushTimer?.cancel();
  // _periodicFlushTimer = Timer.periodic(periodicFlushInterval, (_) async {
  //   try {
  //     await flushIfNeeded(force: false);
  //   } catch (_) {
  //     // ignore flush failures silently; will retry on next timer or on app activity
  //   }
  // });
  }

  void dispose() {
    _periodicFlushTimer?.cancel();
  }

  String _todayId() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns whether the Firestore usage has been disabled for the day
  /// according to the cached config. If the config isn't loaded yet, returns false.
  bool isDisabled() {
    if (!enabled) return true;
    if (_cachedConfig == null) return false;
    final disabled = _cachedConfig!['disabledUntil'];
    if (disabled == null) return false;
    if (disabled is Timestamp) {
      return disabled.toDate().isAfter(DateTime.now());
    }
    if (disabled is DateTime) {
      return disabled.isAfter(DateTime.now());
    }
    return false;
  }

  /// Record a read operation. Uses probabilistic sampling to reduce write volume.
  /// For multiplier=2.5, sampling probability = 1/2.5 = 0.4.
  Future<void> recordRead() async {
    if (!enabled || isDisabled()) return; // do not record when disabled

    final p = 1.0 / samplingMultiplier;
    if (_random.nextDouble() < p) {
      _bufferedReads++;
      await _persistBuffers();
      if (_bufferedReads >= flushThreshold) await _flushBuffer();
    }
  }

  Future<void> recordWrite() async {
    if (!enabled || isDisabled()) return;
    _bufferedWrites++;
    await _persistBuffers();
    if (_bufferedWrites >= flushThreshold) await _flushBuffer();
  }

  Future<void> recordDelete() async {
    if (!enabled || isDisabled()) return;
    _bufferedDeletes++;
    await _persistBuffers();
    if (_bufferedDeletes >= flushThreshold) await _flushBuffer();
  }

  Future<void> _persistBuffers() async {
    if (_prefs == null) return;
    await _prefs!.setInt(_prefsKeyReads, _bufferedReads);
    await _prefs!.setInt(_prefsKeyWrites, _bufferedWrites);
    await _prefs!.setInt(_prefsKeyDeletes, _bufferedDeletes);
  }

  /// Flush if any buffer reached threshold, or if force==true.
  Future<void> flushIfNeeded({bool force = false}) async {
    if (!enabled || isDisabled()) return;
    if (!force && _bufferedReads < flushThreshold && _bufferedWrites < flushThreshold && _bufferedDeletes < flushThreshold) return;
    await _flushBuffer();
  }

  Future<void> flushNow() async => _flushBuffer();

  Future<void> _flushBuffer() async {
    if (!enabled) return;
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();

    final int toFlushReads = _bufferedReads;
    final int toFlushWrites = _bufferedWrites;
    final int toFlushDeletes = _bufferedDeletes;

    if (toFlushReads == 0 && toFlushWrites == 0 && toFlushDeletes == 0) return;

  // Use a valid document path: collection/doc (2 segments). Avoid 'globals/dates/{date}'
  // which would point to a collection/document/collection and is invalid as a document ref.
  final String dateDocPath = 'globals_dates/${_todayId()}';
    final String configDocPath = 'globals/config';

    // Basic validation of document paths to avoid invalid-argument errors
    String _validateDocPath(String p) {
      if (p.isEmpty) throw ArgumentError('Document path is empty');
      if (p.startsWith('/') || p.endsWith('/')) throw ArgumentError('Document path must not start or end with "/": "$p"');
      final parts = p.split('/');
      if (parts.length % 2 != 0) {
        // A valid document path has even number of segments: collection/doc/collection/doc
        throw ArgumentError('Invalid document path (must point to a document): "$p"');
      }
      return p;
    }

    final String validDatePath = _validateDocPath(dateDocPath);
    final String validConfigPath = _validateDocPath(configDocPath);

    final dateRef = _db.doc(validDatePath);
    final configRef = _db.doc(validConfigPath);

    // convert sampled reads to estimated real reads
    final int estimatedReads = (toFlushReads * samplingMultiplier).round();

    final Map<String, dynamic> increments = {};
    if (estimatedReads > 0) increments['reads'] = estimatedReads;
    if (toFlushWrites > 0) increments['writes'] = toFlushWrites;
    if (toFlushDeletes > 0) increments['deletes'] = toFlushDeletes;

    try {
      await _db.runTransaction((tx) async {
        final cfgSnap = await tx.get(configRef);
        final dateSnap = await tx.get(dateRef);

        final thresholds = cfgSnap.exists && cfgSnap.data() != null && cfgSnap.data()!.containsKey('thresholds')
            ? Map<String, dynamic>.from(cfgSnap.get('thresholds'))
            : <String, dynamic>{'reads': 1 << 60, 'writes': 1 << 60, 'deletes': 1 << 60};

        // Helper to read counter safely
        int current(String key) {
          if (!dateSnap.exists) return 0;
          final d = dateSnap.data();
          if (d == null) return 0;
          final v = d[key];
          if (v is int) return v;
          if (v is num) return v.toInt();
          return 0;
        }

        // Check for disabled
        final disabled = cfgSnap.exists && cfgSnap.data() != null ? cfgSnap.get('disabledUntil') : null;
        if (disabled != null) {
          DateTime disabledDate;
          if (disabled is Timestamp) disabledDate = disabled.toDate();
          else if (disabled is DateTime) disabledDate = disabled;
          else disabledDate = DateTime.fromMillisecondsSinceEpoch(0);
          if (disabledDate.isAfter(DateTime.now())) {
            throw Exception('quota_disabled');
          }
        }

        // Compute projected totals and compare to thresholds. If any exceed, set disabledUntil for end of day.
        final projected = <String, int>{};
        increments.forEach((k, v) {
          projected[k] = current(k) + (v as int);
        });

        bool exceeded = false;
        increments.forEach((k, v) {
          final limit = thresholds.containsKey(k) ? (thresholds[k] as num).toInt() : 1 << 60;
          if (projected[k]! > limit) exceeded = true;
        });

        if (exceeded) {
          final now = DateTime.now();
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          tx.set(configRef, {'disabledUntil': Timestamp.fromDate(endOfDay)}, SetOptions(merge: true));
        }

        // Apply increments
        final Map<String, dynamic> incrementMap = {};
        increments.forEach((k, v) {
          incrementMap[k] = FieldValue.increment(v as int);
        });
        incrementMap['updatedAt'] = FieldValue.serverTimestamp();
        tx.set(dateRef, incrementMap, SetOptions(merge: true));
      });

      // Success: clear buffers and persist
      _bufferedReads = 0;
      _bufferedWrites = 0;
      _bufferedDeletes = 0;
      await _persistBuffers();
    } catch (e) {
      // Provide a clearer error message for invalid document paths or transaction failures
      if (e is ArgumentError) {
        throw ArgumentError('Quota flush failed due to invalid document path. dateDocPath="$dateDocPath", configDocPath="$configDocPath". Original: ${e.message}');
      }
      if (e.toString().contains('quota_disabled')) {
        _bufferedReads = 0;
        _bufferedWrites = 0;
        _bufferedDeletes = 0;
        await _persistBuffers();
      }
      rethrow;
    }
  }
}

// Usage example (not part of the class):
// final quota = FirestoreQuotaService();
// await quota.init();
// // On a read operation:
// await quota.recordRead();
// // On a write:
// await quota.recordWrite();
// // Explicit flush (for example on app pause):
// await quota.flushNow();
