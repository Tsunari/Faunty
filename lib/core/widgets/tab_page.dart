import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faunty/core/widgets/custom_app_bar.dart';
import 'package:faunty/core/utils/pdf_generator/base_pdf_layout.dart';



class TabMeta {
  final String title;
  final Widget page;
  final IconData icon;
  const TabMeta(this.title, this.page, this.icon);
}

class TabPage extends ConsumerStatefulWidget {
  final List<TabMeta> tabs;
  final StateProvider<int?> tabIndexProvider;
  final String prefsKey;
  const TabPage({
    super.key,
    required this.tabs,
    required this.tabIndexProvider,
    required this.prefsKey,
  });

  @override
  ConsumerState<TabPage> createState() => _TabPageState();
}

class _TabPageState extends ConsumerState<TabPage> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isTabControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  @override
  void didUpdateWidget(covariant TabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If number of tabs changed, recreate controller to match new length
    if (_isTabControllerInitialized && widget.tabs.length != oldWidget.tabs.length) {
      if (_tabController != null) {
        _tabController!.removeListener(_handleTabChange);
        _tabController!.dispose();
      }
      _isTabControllerInitialized = false;
      _initTabController();
    }
  }

  Future<void> _initTabController() async {
    int initialIndex = ref.read(widget.tabIndexProvider) ?? 0;
    // If provider had no saved index, try reading persisted prefs.
    if (ref.read(widget.tabIndexProvider) == null) {
      final prefs = await SharedPreferences.getInstance();
      int? storedIndex = prefs.getInt(widget.prefsKey);
      if (storedIndex != null) {
        initialIndex = storedIndex;
      } else {
        initialIndex = 0;
      }
    }

    // Clamp the initialIndex to a valid range for the current tabs length.
    if (initialIndex < 0) initialIndex = 0;
    if (widget.tabs.isEmpty) {
      // No tabs to control. Mark initialized but leave controller null — build will show a fallback.
      _tabController = null;
      _isTabControllerInitialized = true;
      // Defer provider mutation until after build to avoid Riverpod lifecycle errors.
      Future(() {
        try {
          ref.read(widget.tabIndexProvider.notifier).state = null;
        } catch (_) {}
      });
      if (mounted) setState(() {});
      return;
    }
    if (initialIndex >= widget.tabs.length) initialIndex = widget.tabs.length - 1;

    // Defer the provider mutation to avoid modifying providers during widget lifecycle.
    Future(() {
      try {
        ref.read(widget.tabIndexProvider.notifier).state = initialIndex;
      } catch (_) {}
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.prefsKey, initialIndex);

    _tabController = TabController(length: widget.tabs.length, vsync: this, initialIndex: initialIndex);
    _tabController!.addListener(_handleTabChange);
    _isTabControllerInitialized = true;
    if (mounted) setState(() {});
  }

  void _handleTabChange() async {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final index = _tabController!.index;
    
    // Defer state updates to avoid mutating RenderLayoutBuilder during layout passes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(widget.tabIndexProvider.notifier).state = index;
      setState(() {});
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(widget.prefsKey, index);
  }

  @override
  void dispose() {
    if (_tabController != null) {
      _tabController!.removeListener(_handleTabChange);
      _tabController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTabControllerInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tabController == null) {
      // No tabs available — render a simple empty state instead of trying to build TabBar/TabBarView.
      return const Scaffold(
        body: Center(child: Text('No tabs')),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeIndex = ref.watch(widget.tabIndexProvider) ?? 0;
    // Clamp index to ensure we don't index out of bounds in race conditions
    final clampedIndex = activeIndex.clamp(0, widget.tabs.length - 1);
    final activeTab = widget.tabs[clampedIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: activeTab.title,
        tabId: activeTab.title,
        titleWidget: SizedBox(
          height: 38,
          child: TabBar(
            controller: _tabController,
            splashBorderRadius: BorderRadius.circular(16),
            tabs: [
              for (int i = 0; i < widget.tabs.length; i++)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.tabs[i].icon, size: 18),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: clampedIndex == i
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.tabs[i].title,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                )
            ],
            isScrollable: true,
            dividerColor: Colors.transparent, // remove standard Material 3 tab divider
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14.0),
            tabAlignment: TabAlignment.center,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [for (final tab in widget.tabs) tab.page],
      ),
    );
  }
}
