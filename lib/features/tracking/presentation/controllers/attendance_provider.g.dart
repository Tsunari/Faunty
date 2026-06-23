// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$attendanceHash() => r'6819fcc6e662fbb1cbe02c9948a0c35ebcab3f34';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [attendance].
@ProviderFor(attendance)
const attendanceProvider = AttendanceFamily();

/// See also [attendance].
class AttendanceFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [attendance].
  const AttendanceFamily();

  /// See also [attendance].
  AttendanceProvider call(String placeId) {
    return AttendanceProvider(placeId);
  }

  @override
  AttendanceProvider getProviderOverride(
    covariant AttendanceProvider provider,
  ) {
    return call(provider.placeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'attendanceProvider';
}

/// See also [attendance].
class AttendanceProvider
    extends AutoDisposeStreamProvider<Map<String, dynamic>> {
  /// See also [attendance].
  AttendanceProvider(String placeId)
    : this._internal(
        (ref) => attendance(ref as AttendanceRef, placeId),
        from: attendanceProvider,
        name: r'attendanceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$attendanceHash,
        dependencies: AttendanceFamily._dependencies,
        allTransitiveDependencies: AttendanceFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  AttendanceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.placeId,
  }) : super.internal();

  final String placeId;

  @override
  Override overrideWith(
    Stream<Map<String, dynamic>> Function(AttendanceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AttendanceProvider._internal(
        (ref) => create(ref as AttendanceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        placeId: placeId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<String, dynamic>> createElement() {
    return _AttendanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceProvider && other.placeId == placeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, placeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AttendanceRef on AutoDisposeStreamProviderRef<Map<String, dynamic>> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _AttendanceProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, dynamic>>
    with AttendanceRef {
  _AttendanceProviderElement(super.provider);

  @override
  String get placeId => (origin as AttendanceProvider).placeId;
}

String _$attendanceMetaHash() => r'76535f6c9115c15cdf8c6e76a2e05689812a2eaa';

/// See also [attendanceMeta].
@ProviderFor(attendanceMeta)
const attendanceMetaProvider = AttendanceMetaFamily();

/// See also [attendanceMeta].
class AttendanceMetaFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [attendanceMeta].
  const AttendanceMetaFamily();

  /// See also [attendanceMeta].
  AttendanceMetaProvider call(String placeId) {
    return AttendanceMetaProvider(placeId);
  }

  @override
  AttendanceMetaProvider getProviderOverride(
    covariant AttendanceMetaProvider provider,
  ) {
    return call(provider.placeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'attendanceMetaProvider';
}

/// See also [attendanceMeta].
class AttendanceMetaProvider
    extends AutoDisposeStreamProvider<Map<String, dynamic>> {
  /// See also [attendanceMeta].
  AttendanceMetaProvider(String placeId)
    : this._internal(
        (ref) => attendanceMeta(ref as AttendanceMetaRef, placeId),
        from: attendanceMetaProvider,
        name: r'attendanceMetaProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$attendanceMetaHash,
        dependencies: AttendanceMetaFamily._dependencies,
        allTransitiveDependencies:
            AttendanceMetaFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  AttendanceMetaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.placeId,
  }) : super.internal();

  final String placeId;

  @override
  Override overrideWith(
    Stream<Map<String, dynamic>> Function(AttendanceMetaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AttendanceMetaProvider._internal(
        (ref) => create(ref as AttendanceMetaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        placeId: placeId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<String, dynamic>> createElement() {
    return _AttendanceMetaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceMetaProvider && other.placeId == placeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, placeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AttendanceMetaRef on AutoDisposeStreamProviderRef<Map<String, dynamic>> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _AttendanceMetaProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, dynamic>>
    with AttendanceMetaRef {
  _AttendanceMetaProviderElement(super.provider);

  @override
  String get placeId => (origin as AttendanceMetaProvider).placeId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
