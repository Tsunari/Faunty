// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$customListServiceHash() => r'860c2d134e0c7aec836b631e4e2b1bef3513791e';

/// See also [customListService].
@ProviderFor(customListService)
final customListServiceProvider =
    AutoDisposeProvider<CustomListFirestoreService>.internal(
      customListService,
      name: r'customListServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$customListServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomListServiceRef =
    AutoDisposeProviderRef<CustomListFirestoreService>;
String _$customListsHash() => r'0c535f6f10ca397da764c4dac917d618e4989723';

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

/// See also [customLists].
@ProviderFor(customLists)
const customListsProvider = CustomListsFamily();

/// See also [customLists].
class CustomListsFamily extends Family<AsyncValue<List<CustomList>>> {
  /// See also [customLists].
  const CustomListsFamily();

  /// See also [customLists].
  CustomListsProvider call(String placeId) {
    return CustomListsProvider(placeId);
  }

  @override
  CustomListsProvider getProviderOverride(
    covariant CustomListsProvider provider,
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
  String? get name => r'customListsProvider';
}

/// See also [customLists].
class CustomListsProvider extends AutoDisposeStreamProvider<List<CustomList>> {
  /// See also [customLists].
  CustomListsProvider(String placeId)
    : this._internal(
        (ref) => customLists(ref as CustomListsRef, placeId),
        from: customListsProvider,
        name: r'customListsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$customListsHash,
        dependencies: CustomListsFamily._dependencies,
        allTransitiveDependencies: CustomListsFamily._allTransitiveDependencies,
        placeId: placeId,
      );

  CustomListsProvider._internal(
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
    Stream<List<CustomList>> Function(CustomListsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomListsProvider._internal(
        (ref) => create(ref as CustomListsRef),
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
  AutoDisposeStreamProviderElement<List<CustomList>> createElement() {
    return _CustomListsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomListsProvider && other.placeId == placeId;
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
mixin CustomListsRef on AutoDisposeStreamProviderRef<List<CustomList>> {
  /// The parameter `placeId` of this provider.
  String get placeId;
}

class _CustomListsProviderElement
    extends AutoDisposeStreamProviderElement<List<CustomList>>
    with CustomListsRef {
  _CustomListsProviderElement(super.provider);

  @override
  String get placeId => (origin as CustomListsProvider).placeId;
}

String _$customListItemsHash() => r'7c98b36d62045ac054130f0f473f9eaad1421f2b';

/// See also [customListItems].
@ProviderFor(customListItems)
const customListItemsProvider = CustomListItemsFamily();

/// See also [customListItems].
class CustomListItemsFamily extends Family<AsyncValue<List<ListItem>>> {
  /// See also [customListItems].
  const CustomListItemsFamily();

  /// See also [customListItems].
  CustomListItemsProvider call(ListKey key) {
    return CustomListItemsProvider(key);
  }

  @override
  CustomListItemsProvider getProviderOverride(
    covariant CustomListItemsProvider provider,
  ) {
    return call(provider.key);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'customListItemsProvider';
}

/// See also [customListItems].
class CustomListItemsProvider
    extends AutoDisposeStreamProvider<List<ListItem>> {
  /// See also [customListItems].
  CustomListItemsProvider(ListKey key)
    : this._internal(
        (ref) => customListItems(ref as CustomListItemsRef, key),
        from: customListItemsProvider,
        name: r'customListItemsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$customListItemsHash,
        dependencies: CustomListItemsFamily._dependencies,
        allTransitiveDependencies:
            CustomListItemsFamily._allTransitiveDependencies,
        key: key,
      );

  CustomListItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final ListKey key;

  @override
  Override overrideWith(
    Stream<List<ListItem>> Function(CustomListItemsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomListItemsProvider._internal(
        (ref) => create(ref as CustomListItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ListItem>> createElement() {
    return _CustomListItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomListItemsProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CustomListItemsRef on AutoDisposeStreamProviderRef<List<ListItem>> {
  /// The parameter `key` of this provider.
  ListKey get key;
}

class _CustomListItemsProviderElement
    extends AutoDisposeStreamProviderElement<List<ListItem>>
    with CustomListItemsRef {
  _CustomListItemsProviderElement(super.provider);

  @override
  ListKey get key => (origin as CustomListItemsProvider).key;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
