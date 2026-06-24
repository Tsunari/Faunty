// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allUsersHash() => r'306d80579a4082fae8b7aea82a2ade5ca9c6a07e';

/// See also [allUsers].
@ProviderFor(allUsers)
final allUsersProvider = AutoDisposeStreamProvider<List<UserEntity>>.internal(
  allUsers,
  name: r'allUsersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllUsersRef = AutoDisposeStreamProviderRef<List<UserEntity>>;
String _$usersByCurrentPlaceHash() =>
    r'31bd28249690585abae8aba40eaedce824fdc719';

/// See also [usersByCurrentPlace].
@ProviderFor(usersByCurrentPlace)
final usersByCurrentPlaceProvider =
    AutoDisposeStreamProvider<List<UserEntity>>.internal(
      usersByCurrentPlace,
      name: r'usersByCurrentPlaceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$usersByCurrentPlaceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersByCurrentPlaceRef = AutoDisposeStreamProviderRef<List<UserEntity>>;
String _$usersByCurrentPlaceWithOptionsHash() =>
    r'ded07150690c75041014e950a5a4981f3c83d8d2';

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

/// See also [usersByCurrentPlaceWithOptions].
@ProviderFor(usersByCurrentPlaceWithOptions)
const usersByCurrentPlaceWithOptionsProvider =
    UsersByCurrentPlaceWithOptionsFamily();

/// See also [usersByCurrentPlaceWithOptions].
class UsersByCurrentPlaceWithOptionsFamily
    extends Family<AsyncValue<List<UserEntity>>> {
  /// See also [usersByCurrentPlaceWithOptions].
  const UsersByCurrentPlaceWithOptionsFamily();

  /// See also [usersByCurrentPlaceWithOptions].
  UsersByCurrentPlaceWithOptionsProvider call(UserSortOption? sort) {
    return UsersByCurrentPlaceWithOptionsProvider(sort);
  }

  @override
  UsersByCurrentPlaceWithOptionsProvider getProviderOverride(
    covariant UsersByCurrentPlaceWithOptionsProvider provider,
  ) {
    return call(provider.sort);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usersByCurrentPlaceWithOptionsProvider';
}

/// See also [usersByCurrentPlaceWithOptions].
class UsersByCurrentPlaceWithOptionsProvider
    extends AutoDisposeStreamProvider<List<UserEntity>> {
  /// See also [usersByCurrentPlaceWithOptions].
  UsersByCurrentPlaceWithOptionsProvider(UserSortOption? sort)
    : this._internal(
        (ref) => usersByCurrentPlaceWithOptions(
          ref as UsersByCurrentPlaceWithOptionsRef,
          sort,
        ),
        from: usersByCurrentPlaceWithOptionsProvider,
        name: r'usersByCurrentPlaceWithOptionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$usersByCurrentPlaceWithOptionsHash,
        dependencies: UsersByCurrentPlaceWithOptionsFamily._dependencies,
        allTransitiveDependencies:
            UsersByCurrentPlaceWithOptionsFamily._allTransitiveDependencies,
        sort: sort,
      );

  UsersByCurrentPlaceWithOptionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sort,
  }) : super.internal();

  final UserSortOption? sort;

  @override
  Override overrideWith(
    Stream<List<UserEntity>> Function(
      UsersByCurrentPlaceWithOptionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsersByCurrentPlaceWithOptionsProvider._internal(
        (ref) => create(ref as UsersByCurrentPlaceWithOptionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sort: sort,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserEntity>> createElement() {
    return _UsersByCurrentPlaceWithOptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByCurrentPlaceWithOptionsProvider &&
        other.sort == sort;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsersByCurrentPlaceWithOptionsRef
    on AutoDisposeStreamProviderRef<List<UserEntity>> {
  /// The parameter `sort` of this provider.
  UserSortOption? get sort;
}

class _UsersByCurrentPlaceWithOptionsProviderElement
    extends AutoDisposeStreamProviderElement<List<UserEntity>>
    with UsersByCurrentPlaceWithOptionsRef {
  _UsersByCurrentPlaceWithOptionsProviderElement(super.provider);

  @override
  UserSortOption? get sort =>
      (origin as UsersByCurrentPlaceWithOptionsProvider).sort;
}

String _$usersByRolesHash() => r'14d13c076cf12e0d58008ca72f2d27b811ca3695';

/// See also [usersByRoles].
@ProviderFor(usersByRoles)
const usersByRolesProvider = UsersByRolesFamily();

/// See also [usersByRoles].
class UsersByRolesFamily extends Family<AsyncValue<List<UserEntity>>> {
  /// See also [usersByRoles].
  const UsersByRolesFamily();

  /// See also [usersByRoles].
  UsersByRolesProvider call(String rolesKey) {
    return UsersByRolesProvider(rolesKey);
  }

  @override
  UsersByRolesProvider getProviderOverride(
    covariant UsersByRolesProvider provider,
  ) {
    return call(provider.rolesKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usersByRolesProvider';
}

/// See also [usersByRoles].
class UsersByRolesProvider extends AutoDisposeStreamProvider<List<UserEntity>> {
  /// See also [usersByRoles].
  UsersByRolesProvider(String rolesKey)
    : this._internal(
        (ref) => usersByRoles(ref as UsersByRolesRef, rolesKey),
        from: usersByRolesProvider,
        name: r'usersByRolesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$usersByRolesHash,
        dependencies: UsersByRolesFamily._dependencies,
        allTransitiveDependencies:
            UsersByRolesFamily._allTransitiveDependencies,
        rolesKey: rolesKey,
      );

  UsersByRolesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rolesKey,
  }) : super.internal();

  final String rolesKey;

  @override
  Override overrideWith(
    Stream<List<UserEntity>> Function(UsersByRolesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsersByRolesProvider._internal(
        (ref) => create(ref as UsersByRolesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rolesKey: rolesKey,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserEntity>> createElement() {
    return _UsersByRolesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByRolesProvider && other.rolesKey == rolesKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rolesKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsersByRolesRef on AutoDisposeStreamProviderRef<List<UserEntity>> {
  /// The parameter `rolesKey` of this provider.
  String get rolesKey;
}

class _UsersByRolesProviderElement
    extends AutoDisposeStreamProviderElement<List<UserEntity>>
    with UsersByRolesRef {
  _UsersByRolesProviderElement(super.provider);

  @override
  String get rolesKey => (origin as UsersByRolesProvider).rolesKey;
}

String _$usersByRolesWithOptionsHash() =>
    r'423231c43adaddb39a514c6fc629afb419baf9c7';

/// See also [usersByRolesWithOptions].
@ProviderFor(usersByRolesWithOptions)
const usersByRolesWithOptionsProvider = UsersByRolesWithOptionsFamily();

/// See also [usersByRolesWithOptions].
class UsersByRolesWithOptionsFamily
    extends Family<AsyncValue<List<UserEntity>>> {
  /// See also [usersByRolesWithOptions].
  const UsersByRolesWithOptionsFamily();

  /// See also [usersByRolesWithOptions].
  UsersByRolesWithOptionsProvider call(Map<String, dynamic> params) {
    return UsersByRolesWithOptionsProvider(params);
  }

  @override
  UsersByRolesWithOptionsProvider getProviderOverride(
    covariant UsersByRolesWithOptionsProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usersByRolesWithOptionsProvider';
}

/// See also [usersByRolesWithOptions].
class UsersByRolesWithOptionsProvider
    extends AutoDisposeStreamProvider<List<UserEntity>> {
  /// See also [usersByRolesWithOptions].
  UsersByRolesWithOptionsProvider(Map<String, dynamic> params)
    : this._internal(
        (ref) =>
            usersByRolesWithOptions(ref as UsersByRolesWithOptionsRef, params),
        from: usersByRolesWithOptionsProvider,
        name: r'usersByRolesWithOptionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$usersByRolesWithOptionsHash,
        dependencies: UsersByRolesWithOptionsFamily._dependencies,
        allTransitiveDependencies:
            UsersByRolesWithOptionsFamily._allTransitiveDependencies,
        params: params,
      );

  UsersByRolesWithOptionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final Map<String, dynamic> params;

  @override
  Override overrideWith(
    Stream<List<UserEntity>> Function(UsersByRolesWithOptionsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsersByRolesWithOptionsProvider._internal(
        (ref) => create(ref as UsersByRolesWithOptionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserEntity>> createElement() {
    return _UsersByRolesWithOptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByRolesWithOptionsProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsersByRolesWithOptionsRef
    on AutoDisposeStreamProviderRef<List<UserEntity>> {
  /// The parameter `params` of this provider.
  Map<String, dynamic> get params;
}

class _UsersByRolesWithOptionsProviderElement
    extends AutoDisposeStreamProviderElement<List<UserEntity>>
    with UsersByRolesWithOptionsRef {
  _UsersByRolesWithOptionsProviderElement(super.provider);

  @override
  Map<String, dynamic> get params =>
      (origin as UsersByRolesWithOptionsProvider).params;
}

String _$usersByRolesAndPlaceHash() =>
    r'4a2f442785720d319edb84c7942bb02d9b8e3062';

/// See also [usersByRolesAndPlace].
@ProviderFor(usersByRolesAndPlace)
const usersByRolesAndPlaceProvider = UsersByRolesAndPlaceFamily();

/// See also [usersByRolesAndPlace].
class UsersByRolesAndPlaceFamily extends Family<AsyncValue<List<UserEntity>>> {
  /// See also [usersByRolesAndPlace].
  const UsersByRolesAndPlaceFamily();

  /// See also [usersByRolesAndPlace].
  UsersByRolesAndPlaceProvider call(String rolesKey) {
    return UsersByRolesAndPlaceProvider(rolesKey);
  }

  @override
  UsersByRolesAndPlaceProvider getProviderOverride(
    covariant UsersByRolesAndPlaceProvider provider,
  ) {
    return call(provider.rolesKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usersByRolesAndPlaceProvider';
}

/// See also [usersByRolesAndPlace].
class UsersByRolesAndPlaceProvider
    extends AutoDisposeStreamProvider<List<UserEntity>> {
  /// See also [usersByRolesAndPlace].
  UsersByRolesAndPlaceProvider(String rolesKey)
    : this._internal(
        (ref) => usersByRolesAndPlace(ref as UsersByRolesAndPlaceRef, rolesKey),
        from: usersByRolesAndPlaceProvider,
        name: r'usersByRolesAndPlaceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$usersByRolesAndPlaceHash,
        dependencies: UsersByRolesAndPlaceFamily._dependencies,
        allTransitiveDependencies:
            UsersByRolesAndPlaceFamily._allTransitiveDependencies,
        rolesKey: rolesKey,
      );

  UsersByRolesAndPlaceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rolesKey,
  }) : super.internal();

  final String rolesKey;

  @override
  Override overrideWith(
    Stream<List<UserEntity>> Function(UsersByRolesAndPlaceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsersByRolesAndPlaceProvider._internal(
        (ref) => create(ref as UsersByRolesAndPlaceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rolesKey: rolesKey,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserEntity>> createElement() {
    return _UsersByRolesAndPlaceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByRolesAndPlaceProvider && other.rolesKey == rolesKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rolesKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsersByRolesAndPlaceRef
    on AutoDisposeStreamProviderRef<List<UserEntity>> {
  /// The parameter `rolesKey` of this provider.
  String get rolesKey;
}

class _UsersByRolesAndPlaceProviderElement
    extends AutoDisposeStreamProviderElement<List<UserEntity>>
    with UsersByRolesAndPlaceRef {
  _UsersByRolesAndPlaceProviderElement(super.provider);

  @override
  String get rolesKey => (origin as UsersByRolesAndPlaceProvider).rolesKey;
}

String _$usersByRolesAndPlaceWithOptionsHash() =>
    r'8af70a19841812db6e8597abf37467b98be20721';

/// See also [usersByRolesAndPlaceWithOptions].
@ProviderFor(usersByRolesAndPlaceWithOptions)
const usersByRolesAndPlaceWithOptionsProvider =
    UsersByRolesAndPlaceWithOptionsFamily();

/// See also [usersByRolesAndPlaceWithOptions].
class UsersByRolesAndPlaceWithOptionsFamily
    extends Family<AsyncValue<List<UserEntity>>> {
  /// See also [usersByRolesAndPlaceWithOptions].
  const UsersByRolesAndPlaceWithOptionsFamily();

  /// See also [usersByRolesAndPlaceWithOptions].
  UsersByRolesAndPlaceWithOptionsProvider call(Map<String, dynamic> params) {
    return UsersByRolesAndPlaceWithOptionsProvider(params);
  }

  @override
  UsersByRolesAndPlaceWithOptionsProvider getProviderOverride(
    covariant UsersByRolesAndPlaceWithOptionsProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'usersByRolesAndPlaceWithOptionsProvider';
}

/// See also [usersByRolesAndPlaceWithOptions].
class UsersByRolesAndPlaceWithOptionsProvider
    extends AutoDisposeStreamProvider<List<UserEntity>> {
  /// See also [usersByRolesAndPlaceWithOptions].
  UsersByRolesAndPlaceWithOptionsProvider(Map<String, dynamic> params)
    : this._internal(
        (ref) => usersByRolesAndPlaceWithOptions(
          ref as UsersByRolesAndPlaceWithOptionsRef,
          params,
        ),
        from: usersByRolesAndPlaceWithOptionsProvider,
        name: r'usersByRolesAndPlaceWithOptionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$usersByRolesAndPlaceWithOptionsHash,
        dependencies: UsersByRolesAndPlaceWithOptionsFamily._dependencies,
        allTransitiveDependencies:
            UsersByRolesAndPlaceWithOptionsFamily._allTransitiveDependencies,
        params: params,
      );

  UsersByRolesAndPlaceWithOptionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final Map<String, dynamic> params;

  @override
  Override overrideWith(
    Stream<List<UserEntity>> Function(
      UsersByRolesAndPlaceWithOptionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UsersByRolesAndPlaceWithOptionsProvider._internal(
        (ref) => create(ref as UsersByRolesAndPlaceWithOptionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<UserEntity>> createElement() {
    return _UsersByRolesAndPlaceWithOptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UsersByRolesAndPlaceWithOptionsProvider &&
        other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UsersByRolesAndPlaceWithOptionsRef
    on AutoDisposeStreamProviderRef<List<UserEntity>> {
  /// The parameter `params` of this provider.
  Map<String, dynamic> get params;
}

class _UsersByRolesAndPlaceWithOptionsProviderElement
    extends AutoDisposeStreamProviderElement<List<UserEntity>>
    with UsersByRolesAndPlaceWithOptionsRef {
  _UsersByRolesAndPlaceWithOptionsProviderElement(super.provider);

  @override
  Map<String, dynamic> get params =>
      (origin as UsersByRolesAndPlaceWithOptionsProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
