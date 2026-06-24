// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$placeListHash() => r'1c843a8cf5b63e9bcbd684415da4c2165e08d987';

/// See also [placeList].
@ProviderFor(placeList)
final placeListProvider = AutoDisposeFutureProvider<List<PlaceModel>>.internal(
  placeList,
  name: r'placeListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$placeListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaceListRef = AutoDisposeFutureProviderRef<List<PlaceModel>>;
String _$placeStreamHash() => r'6e2a9fc26772ae97600dcaec32f0ff6ddffc73f9';

/// See also [placeStream].
@ProviderFor(placeStream)
final placeStreamProvider =
    AutoDisposeStreamProvider<List<PlaceModel>>.internal(
      placeStream,
      name: r'placeStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$placeStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaceStreamRef = AutoDisposeStreamProviderRef<List<PlaceModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
