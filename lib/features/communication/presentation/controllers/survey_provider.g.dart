// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$surveyHash() => r'dc8bf4a463ccc3b9a54a41a30ee4c7c3600cc614';

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

/// See also [survey].
@ProviderFor(survey)
const surveyProvider = SurveyFamily();

/// See also [survey].
class SurveyFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [survey].
  const SurveyFamily();

  /// See also [survey].
  SurveyProvider call(String placeId) {
    return SurveyProvider(placeId);
  }

  @override
  SurveyProvider getProviderOverride(covariant SurveyProvider provider) {
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
  String? get name => r'surveyProvider';
}

/// See also [survey].
class SurveyProvider
    extends AutoDisposeStreamProvider<List<Map<String, dynamic>>> {
  /// See also [survey].
  SurveyProvider(String placeId)
    : this._internal(
        (ref) => survey(ref as SurveyRef, placeId),
        from: surveyProvider,
        name: r'surveyProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$surveyHash,
        dependencies: SurveyFamily._dependencies,
        allTransitiveDependencies: SurveyFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  SurveyProvider._internal(
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
    Stream<List<Map<String, dynamic>>> Function(SurveyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SurveyProvider._internal(
        (ref) => create(ref as SurveyRef),
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
  AutoDisposeStreamProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SurveyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SurveyProvider && other.placeId == placeId;
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
mixin SurveyRef on AutoDisposeStreamProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _SurveyProviderElement
    extends AutoDisposeStreamProviderElement<List<Map<String, dynamic>>>
    with SurveyRef {
  _SurveyProviderElement(super.provider);

  @override
  String get placeId => (origin as SurveyProvider).placeId;
}

String _$surveyFirestoreServiceHash() =>
    r'd2c3886638e08e18cfdd9afe214bf668671f99df';

/// See also [surveyFirestoreService].
@ProviderFor(surveyFirestoreService)
const surveyFirestoreServiceProvider = SurveyFirestoreServiceFamily();

/// See also [surveyFirestoreService].
class SurveyFirestoreServiceFamily extends Family<SurveyFirestoreService> {
  /// See also [surveyFirestoreService].
  const SurveyFirestoreServiceFamily();

  /// See also [surveyFirestoreService].
  SurveyFirestoreServiceProvider call(String placeId) {
    return SurveyFirestoreServiceProvider(placeId);
  }

  @override
  SurveyFirestoreServiceProvider getProviderOverride(
    covariant SurveyFirestoreServiceProvider provider,
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
  String? get name => r'surveyFirestoreServiceProvider';
}

/// See also [surveyFirestoreService].
class SurveyFirestoreServiceProvider
    extends AutoDisposeProvider<SurveyFirestoreService> {
  /// See also [surveyFirestoreService].
  SurveyFirestoreServiceProvider(String placeId)
    : this._internal(
        (ref) =>
            surveyFirestoreService(ref as SurveyFirestoreServiceRef, placeId),
        from: surveyFirestoreServiceProvider,
        name: r'surveyFirestoreServiceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$surveyFirestoreServiceHash,
        dependencies: SurveyFirestoreServiceFamily._dependencies,
        allTransitiveDependencies:
            SurveyFirestoreServiceFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  SurveyFirestoreServiceProvider._internal(
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
    SurveyFirestoreService Function(SurveyFirestoreServiceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SurveyFirestoreServiceProvider._internal(
        (ref) => create(ref as SurveyFirestoreServiceRef),
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
  AutoDisposeProviderElement<SurveyFirestoreService> createElement() {
    return _SurveyFirestoreServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SurveyFirestoreServiceProvider && other.placeId == placeId;
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
mixin SurveyFirestoreServiceRef
    on AutoDisposeProviderRef<SurveyFirestoreService> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _SurveyFirestoreServiceProviderElement
    extends AutoDisposeProviderElement<SurveyFirestoreService>
    with SurveyFirestoreServiceRef {
  _SurveyFirestoreServiceProviderElement(super.provider);

  @override
  String get placeId => (origin as SurveyFirestoreServiceProvider).placeId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
