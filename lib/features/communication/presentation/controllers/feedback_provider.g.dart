// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedbackReportsHash() => r'd9919c1fc79b8ada4bfaba4118edbb2accee1a82';

/// See also [feedbackReports].
@ProviderFor(feedbackReports)
final feedbackReportsProvider =
    AutoDisposeStreamProvider<List<FeedbackReport>>.internal(
      feedbackReports,
      name: r'feedbackReportsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackReportsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedbackReportsRef = AutoDisposeStreamProviderRef<List<FeedbackReport>>;
String _$filteredFeedbackReportsHash() =>
    r'05c7b55c4d47068726611e58cec2e329eb950640';

/// See also [filteredFeedbackReports].
@ProviderFor(filteredFeedbackReports)
final filteredFeedbackReportsProvider =
    AutoDisposeProvider<List<FeedbackReport>>.internal(
      filteredFeedbackReports,
      name: r'filteredFeedbackReportsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredFeedbackReportsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredFeedbackReportsRef =
    AutoDisposeProviderRef<List<FeedbackReport>>;
String _$feedbackCommentsHash() => r'150ea620d72914b71809bd5616382de19de8fdd8';

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

/// See also [feedbackComments].
@ProviderFor(feedbackComments)
const feedbackCommentsProvider = FeedbackCommentsFamily();

/// See also [feedbackComments].
class FeedbackCommentsFamily extends Family<AsyncValue<List<FeedbackComment>>> {
  /// See also [feedbackComments].
  const FeedbackCommentsFamily();

  /// See also [feedbackComments].
  FeedbackCommentsProvider call(String reportId) {
    return FeedbackCommentsProvider(reportId);
  }

  @override
  FeedbackCommentsProvider getProviderOverride(
    covariant FeedbackCommentsProvider provider,
  ) {
    return call(provider.reportId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'feedbackCommentsProvider';
}

/// See also [feedbackComments].
class FeedbackCommentsProvider
    extends AutoDisposeStreamProvider<List<FeedbackComment>> {
  /// See also [feedbackComments].
  FeedbackCommentsProvider(String reportId)
    : this._internal(
        (ref) => feedbackComments(ref as FeedbackCommentsRef, reportId),
        from: feedbackCommentsProvider,
        name: r'feedbackCommentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$feedbackCommentsHash,
        dependencies: FeedbackCommentsFamily._dependencies,
        allTransitiveDependencies:
            FeedbackCommentsFamily._allTransitiveDependencies,
        reportId: reportId,
      );

  FeedbackCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reportId,
  }) : super.internal();

  final String reportId;

  @override
  Override overrideWith(
    Stream<List<FeedbackComment>> Function(FeedbackCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FeedbackCommentsProvider._internal(
        (ref) => create(ref as FeedbackCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reportId: reportId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<FeedbackComment>> createElement() {
    return _FeedbackCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackCommentsProvider && other.reportId == reportId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reportId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FeedbackCommentsRef
    on AutoDisposeStreamProviderRef<List<FeedbackComment>> {
  /// The parameter `reportId` of this provider.
  String get reportId;
}

class _FeedbackCommentsProviderElement
    extends AutoDisposeStreamProviderElement<List<FeedbackComment>>
    with FeedbackCommentsRef {
  _FeedbackCommentsProviderElement(super.provider);

  @override
  String get reportId => (origin as FeedbackCommentsProvider).reportId;
}

String _$feedbackActionsHash() => r'57ebdf4984adc25266978adad0f01b3fadb254fa';

/// See also [feedbackActions].
@ProviderFor(feedbackActions)
final feedbackActionsProvider = AutoDisposeProvider<FeedbackActions>.internal(
  feedbackActions,
  name: r'feedbackActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedbackActionsRef = AutoDisposeProviderRef<FeedbackActions>;
String _$feedbackViewModeStateHash() =>
    r'190c861e7e52912ce22963a84431945c4101df8e';

/// See also [FeedbackViewModeState].
@ProviderFor(FeedbackViewModeState)
final feedbackViewModeStateProvider =
    AutoDisposeNotifierProvider<
      FeedbackViewModeState,
      FeedbackViewMode
    >.internal(
      FeedbackViewModeState.new,
      name: r'feedbackViewModeStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackViewModeStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedbackViewModeState = AutoDisposeNotifier<FeedbackViewMode>;
String _$feedbackSearchStateHash() =>
    r'59ab9f38d086d0f90a8223d2cefdd75a12e6569e';

/// See also [FeedbackSearchState].
@ProviderFor(FeedbackSearchState)
final feedbackSearchStateProvider =
    AutoDisposeNotifierProvider<FeedbackSearchState, String>.internal(
      FeedbackSearchState.new,
      name: r'feedbackSearchStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackSearchStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedbackSearchState = AutoDisposeNotifier<String>;
String _$feedbackTypeFilterStateHash() =>
    r'209c60338be2e641331493003c29e9c6cd0e7962';

/// See also [FeedbackTypeFilterState].
@ProviderFor(FeedbackTypeFilterState)
final feedbackTypeFilterStateProvider =
    AutoDisposeNotifierProvider<
      FeedbackTypeFilterState,
      FeedbackType?
    >.internal(
      FeedbackTypeFilterState.new,
      name: r'feedbackTypeFilterStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackTypeFilterStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedbackTypeFilterState = AutoDisposeNotifier<FeedbackType?>;
String _$feedbackStatusFilterStateHash() =>
    r'11280e531ad291a4811996b1b41b9134eb9f9781';

/// See also [FeedbackStatusFilterState].
@ProviderFor(FeedbackStatusFilterState)
final feedbackStatusFilterStateProvider =
    AutoDisposeNotifierProvider<
      FeedbackStatusFilterState,
      FeedbackStatus?
    >.internal(
      FeedbackStatusFilterState.new,
      name: r'feedbackStatusFilterStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackStatusFilterStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedbackStatusFilterState = AutoDisposeNotifier<FeedbackStatus?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
