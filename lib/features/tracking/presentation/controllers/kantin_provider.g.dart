// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kantin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$kantinHash() => r'71977f03697442e42959e984a72649f14f46f309';

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

/// See also [kantin].
@ProviderFor(kantin)
const kantinProvider = KantinFamily();

/// See also [kantin].
class KantinFamily extends Family<AsyncValue<Map<String, double>>> {
  /// See also [kantin].
  const KantinFamily();

  /// See also [kantin].
  KantinProvider call(String placeId) {
    return KantinProvider(placeId);
  }

  @override
  KantinProvider getProviderOverride(covariant KantinProvider provider) {
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
  String? get name => r'kantinProvider';
}

/// See also [kantin].
class KantinProvider extends AutoDisposeStreamProvider<Map<String, double>> {
  /// See also [kantin].
  KantinProvider(String placeId)
    : this._internal(
        (ref) => kantin(ref as KantinRef, placeId),
        from: kantinProvider,
        name: r'kantinProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$kantinHash,
        dependencies: KantinFamily._dependencies,
        allTransitiveDependencies: KantinFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  KantinProvider._internal(
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
    Stream<Map<String, double>> Function(KantinRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: KantinProvider._internal(
        (ref) => create(ref as KantinRef),
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
  AutoDisposeStreamProviderElement<Map<String, double>> createElement() {
    return _KantinProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is KantinProvider && other.placeId == placeId;
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
mixin KantinRef on AutoDisposeStreamProviderRef<Map<String, double>> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _KantinProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, double>>
    with KantinRef {
  _KantinProviderElement(super.provider);

  @override
  String get placeId => (origin as KantinProvider).placeId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
