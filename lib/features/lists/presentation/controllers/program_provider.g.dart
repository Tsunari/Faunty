// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$programFirestoreServiceHash() =>
    r'6493542ef8d2e2ede6fc3e585a82682e87e08efe';

/// See also [programFirestoreService].
@ProviderFor(programFirestoreService)
final programFirestoreServiceProvider =
    AutoDisposeProvider<ProgramFirestoreService>.internal(
      programFirestoreService,
      name: r'programFirestoreServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$programFirestoreServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProgramFirestoreServiceRef =
    AutoDisposeProviderRef<ProgramFirestoreService>;
String _$weekProgramHash() => r'65612bf50f269b58c414b75c194a6af3214ec94c';

/// See also [weekProgram].
@ProviderFor(weekProgram)
final weekProgramProvider =
    AutoDisposeStreamProvider<Map<String, List<Map<String, String>>>>.internal(
      weekProgram,
      name: r'weekProgramProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$weekProgramHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WeekProgramRef =
    AutoDisposeStreamProviderRef<Map<String, List<Map<String, String>>>>;
String _$programTemplatesHash() => r'6c0722f16ee7e3e92b21a1b597bc83b0673312d4';

/// See also [programTemplates].
@ProviderFor(programTemplates)
final programTemplatesProvider =
    AutoDisposeFutureProvider<
      Map<String, Map<String, List<Map<String, String>>>>
    >.internal(
      programTemplates,
      name: r'programTemplatesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$programTemplatesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProgramTemplatesRef =
    AutoDisposeFutureProviderRef<
      Map<String, Map<String, List<Map<String, String>>>>
    >;
String _$saveProgramTemplateHash() =>
    r'72b9125fdadf85fca892dfd68b715bf34dd107d3';

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

/// See also [saveProgramTemplate].
@ProviderFor(saveProgramTemplate)
const saveProgramTemplateProvider = SaveProgramTemplateFamily();

/// See also [saveProgramTemplate].
class SaveProgramTemplateFamily extends Family<AsyncValue<void>> {
  /// See also [saveProgramTemplate].
  const SaveProgramTemplateFamily();

  /// See also [saveProgramTemplate].
  SaveProgramTemplateProvider call(
    MapEntry<String, Map<String, List<Map<String, String>>>> entry,
  ) {
    return SaveProgramTemplateProvider(entry);
  }

  @override
  SaveProgramTemplateProvider getProviderOverride(
    covariant SaveProgramTemplateProvider provider,
  ) {
    return call(provider.entry);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'saveProgramTemplateProvider';
}

/// See also [saveProgramTemplate].
class SaveProgramTemplateProvider extends AutoDisposeFutureProvider<void> {
  /// See also [saveProgramTemplate].
  SaveProgramTemplateProvider(
    MapEntry<String, Map<String, List<Map<String, String>>>> entry,
  ) : this._internal(
        (ref) => saveProgramTemplate(ref as SaveProgramTemplateRef, entry),
        from: saveProgramTemplateProvider,
        name: r'saveProgramTemplateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$saveProgramTemplateHash,
        dependencies: SaveProgramTemplateFamily._dependencies,
        allTransitiveDependencies:
            SaveProgramTemplateFamily._allTransitiveDependencies,
        entry: entry,
      );

  SaveProgramTemplateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entry,
  }) : super.internal();

  final MapEntry<String, Map<String, List<Map<String, String>>>> entry;

  @override
  Override overrideWith(
    FutureOr<void> Function(SaveProgramTemplateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SaveProgramTemplateProvider._internal(
        (ref) => create(ref as SaveProgramTemplateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entry: entry,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SaveProgramTemplateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveProgramTemplateProvider && other.entry == entry;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entry.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SaveProgramTemplateRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `entry` of this provider.
  MapEntry<String, Map<String, List<Map<String, String>>>> get entry;
}

class _SaveProgramTemplateProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with SaveProgramTemplateRef {
  _SaveProgramTemplateProviderElement(super.provider);

  @override
  MapEntry<String, Map<String, List<Map<String, String>>>> get entry =>
      (origin as SaveProgramTemplateProvider).entry;
}

String _$deleteProgramTemplateHash() =>
    r'7483379b451fd0aada8227ea8d37e78ffce4e1d4';

/// See also [deleteProgramTemplate].
@ProviderFor(deleteProgramTemplate)
const deleteProgramTemplateProvider = DeleteProgramTemplateFamily();

/// See also [deleteProgramTemplate].
class DeleteProgramTemplateFamily extends Family<AsyncValue<void>> {
  /// See also [deleteProgramTemplate].
  const DeleteProgramTemplateFamily();

  /// See also [deleteProgramTemplate].
  DeleteProgramTemplateProvider call(String templateName) {
    return DeleteProgramTemplateProvider(templateName);
  }

  @override
  DeleteProgramTemplateProvider getProviderOverride(
    covariant DeleteProgramTemplateProvider provider,
  ) {
    return call(provider.templateName);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deleteProgramTemplateProvider';
}

/// See also [deleteProgramTemplate].
class DeleteProgramTemplateProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deleteProgramTemplate].
  DeleteProgramTemplateProvider(String templateName)
    : this._internal(
        (ref) => deleteProgramTemplate(
          ref as DeleteProgramTemplateRef,
          templateName,
        ),
        from: deleteProgramTemplateProvider,
        name: r'deleteProgramTemplateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$deleteProgramTemplateHash,
        dependencies: DeleteProgramTemplateFamily._dependencies,
        allTransitiveDependencies:
            DeleteProgramTemplateFamily._allTransitiveDependencies,
        templateName: templateName,
      );

  DeleteProgramTemplateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.templateName,
  }) : super.internal();

  final String templateName;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteProgramTemplateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteProgramTemplateProvider._internal(
        (ref) => create(ref as DeleteProgramTemplateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        templateName: templateName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteProgramTemplateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteProgramTemplateProvider &&
        other.templateName == templateName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, templateName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeleteProgramTemplateRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `templateName` of this provider.
  String get templateName;
}

class _DeleteProgramTemplateProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with DeleteProgramTemplateRef {
  _DeleteProgramTemplateProviderElement(super.provider);

  @override
  String get templateName =>
      (origin as DeleteProgramTemplateProvider).templateName;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
