import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Generic models exported for consumers
class Assignment {
  final String left;
  final String right;
  final List<String> extras;
  Assignment({required this.left, required this.right, this.extras = const []});
}

class Subsection {
  final String title;
  final List<Assignment> rows;
  Subsection({required this.title, required this.rows});
}

class TableWidget extends ConsumerStatefulWidget {
  final List<dynamic> items; // can be Assignment or Subsection in any order
  final bool showColumnHeaders;
  final String? leftHeader;
  final String? rightHeader;
  final Future<void> Function(int index, bool left, String newValue)? onSave;
  final bool editMode;
  final Future<void> Function(int index)? onDeleteAssignment;
  final Future<void> Function(int subsectionIndex)? onDeleteSubsection;
  final Future<void> Function(int subsectionIndex, String newTitle)?
  onSaveSubsection;
  final VoidCallback? onAddAssignment;
  final VoidCallback? onAddSubsection;
  final Future<void> Function(int oldIndex, int newIndex)?
  onReorder; // For future drag-and-drop

  const TableWidget({
    super.key,
    required this.items,
    this.showColumnHeaders = true,
    this.leftHeader,
    this.rightHeader,
    this.onSave,
    this.editMode = false,
    this.onDeleteAssignment,
    this.onDeleteSubsection,
    this.onSaveSubsection,
    this.onAddAssignment,
    this.onAddSubsection,
    this.onReorder,
  });

  @override
  ConsumerState<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends ConsumerState<TableWidget> {
  int? editingRowIndex;
  int? editingSubsectionItemIndex;
  bool editingLeft = true;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _subsectionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _subsectionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _subsectionFocusNode.addListener(_onSubsectionFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _subsectionFocusNode.removeListener(_onSubsectionFocusChanged);
    _focusNode.dispose();
    _subsectionFocusNode.dispose();
    _controller.dispose();
    _subsectionController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && editingRowIndex != null) {
      // Save when focus is lost
      _saveEdit(editingRowIndex!, editingLeft, _controller.text);
    }
  }

  void _onSubsectionFocusChanged() {
    if (!_subsectionFocusNode.hasFocus && editingSubsectionItemIndex != null) {
      // Save when focus is lost
      _saveSubsectionTitle(
        editingSubsectionItemIndex!,
        _subsectionController.text,
      );
    }
  }

  @override
  void didUpdateWidget(TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If edit mode is turned off, save and close any open edits
    if (oldWidget.editMode && !widget.editMode) {
      _saveAndCloseAllEdits();
    }
  }

  void _saveAndCloseAllEdits() async {
    // Save row edit if active
    if (editingRowIndex != null) {
      try {
        await _saveEdit(editingRowIndex!, editingLeft, _controller.text);
      } catch (e) {
        // Ignore save errors when closing
      }
    }
    // Save subsection edit if active
    if (editingSubsectionItemIndex != null) {
      try {
        _saveSubsectionTitle(
          editingSubsectionItemIndex!,
          _subsectionController.text,
        );
      } catch (e) {
        // Ignore save errors when closing
      }
    }
    // Close all edits
    setState(() {
      editingRowIndex = null;
      editingSubsectionItemIndex = null;
      editingLeft = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final headerHeight = 36.0;

    final theme = Theme.of(context);
    final containerColor = theme.cardColor;
    final primary = theme.colorScheme.primary;

    // Check if items is empty and show empty state
    if (widget.items.isEmpty) {
      return Container(
        alignment: Alignment.topCenter,
        constraints: const BoxConstraints(minWidth: 400, minHeight: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No items yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get started by adding your first assignment or subsection',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (widget.editMode) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onAddAssignment != null) ...[
                      ElevatedButton.icon(
                        onPressed: widget.onAddAssignment,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Assignment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (widget.onAddSubsection != null)
                        const SizedBox(width: 12),
                    ],
                    if (widget.onAddSubsection != null) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onAddSubsection,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Subsection'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          foregroundColor: primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Build blocks: either Tables of assignments or subsection header + table
    final blocks = <Widget>[];
    final pending =
        <(Assignment, int)>[]; // Track assignment with its itemIndex
    int flatCounter = 0;

    void flushPending() {
      if (pending.isEmpty) return;
      final table = Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300),
          verticalInside: BorderSide(color: Colors.grey.shade200),
        ),
        children: pending
            .map(
              (tuple) => _buildRow(context, tuple.$1, flatCounter++, tuple.$2),
            )
            .toList(),
      );
      blocks.add(table);
      pending.clear();
    }

    for (int itemIndex = 0; itemIndex < widget.items.length; itemIndex++) {
      final item = widget.items[itemIndex];
      if (item is Assignment) {
        pending.add((item, itemIndex));
      } else if (item is Subsection) {
        // flush assignments before subsection
        flushPending();
        // subsection header: support inline editing when requested
        if (editingSubsectionItemIndex == itemIndex) {
          blocks.add(
            Container(
              height: headerHeight,
              color: primary.withOpacity(0.12),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {}, // Consume tap to prevent exit editing
                          child: TextField(
                            controller: _subsectionController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                            onSubmitted: (val) =>
                                _saveSubsectionTitle(itemIndex, val),
                            onEditingComplete: () => _saveSubsectionTitle(
                              itemIndex,
                              _subsectionController.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          blocks.add(
            GestureDetector(
              onTap: widget.editMode
                  ? () => _startEditingSubsection(itemIndex, item.title)
                  : null,
              child: Container(
                height: headerHeight,
                color: primary.withOpacity(0.12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Move up/down buttons for reordering
                    if (widget.editMode && widget.onReorder != null) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: itemIndex > 0 ? primary : Colors.grey.shade300,
                        ),
                        onPressed: itemIndex > 0
                            ? () => widget.onReorder!(itemIndex, itemIndex - 1)
                            : null,
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_downward,
                          size: 18,
                          color: itemIndex < widget.items.length - 1
                              ? primary
                              : Colors.grey.shade300,
                        ),
                        onPressed: itemIndex < widget.items.length - 1
                            ? () => widget.onReorder!(itemIndex, itemIndex + 1)
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item.title,
                      style: headerStyle?.copyWith(color: primary),
                    ),
                    if (widget.editMode &&
                        widget.onDeleteSubsection != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => widget.onDeleteSubsection!(itemIndex),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        // add subsection rows as a separate table
        final subTable = Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade300),
            verticalInside: BorderSide(color: Colors.grey.shade200),
          ),
          children: item.rows
              .map(
                (r) => _buildRow(context, r, flatCounter++, -1),
              ) // -1 indicates subsection row (can't reorder individual rows)
              .toList(),
        );
        blocks.add(subTable);
      }
    }
    flushPending();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.editMode
          ? () async {
              // Exit inline editing when tapped outside, but save changes first
              if (editingRowIndex != null) {
                await _saveEdit(
                  editingRowIndex!,
                  editingLeft,
                  _controller.text,
                );
                setState(() {
                  editingRowIndex = null;
                  editingLeft = true;
                });
              }
              if (editingSubsectionItemIndex != null) {
                _saveSubsectionTitle(
                  editingSubsectionItemIndex!,
                  _subsectionController.text,
                );
                setState(() {
                  editingSubsectionItemIndex = null;
                });
              }
            }
          : null,
      child: Container(
        alignment: Alignment.topCenter,
        constraints: const BoxConstraints(minWidth: 400), // Minimum width
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showColumnHeaders) ...[
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Text(
                            widget.leftHeader ?? 'Left',
                            style: headerStyle,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Text(
                            widget.rightHeader ?? 'Right',
                            style: headerStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // render blocks sequentially with separators between them so borders remain visible
              ..._interleaveWithSeparators(
                blocks,
                Theme.of(context).dividerColor,
              ),

              // Add buttons at the bottom when in edit mode
              if (widget.editMode &&
                  (widget.onAddAssignment != null ||
                      widget.onAddSubsection != null)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.onAddAssignment != null) ...[
                        ElevatedButton.icon(
                          onPressed: widget.onAddAssignment,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Assignment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        if (widget.onAddSubsection != null)
                          const SizedBox(width: 12),
                      ],
                      if (widget.onAddSubsection != null) ...[
                        OutlinedButton.icon(
                          onPressed: widget.onAddSubsection,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Subsection'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primary),
                            foregroundColor: primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _interleaveWithSeparators(List<Widget> blocks, Color sepColor) {
    final out = <Widget>[];
    for (int i = 0; i < blocks.length; i++) {
      out.add(blocks[i]);
      if (i < blocks.length - 1) {
        // use Divider with same color/thickness as table horizontalInside for identical appearance
        out.add(Divider(height: 1, thickness: 1, color: Colors.grey.shade300));
      }
    }
    return out;
  }

  TableRow _buildRow(
    BuildContext context,
    Assignment r,
    int index,
    int itemIndex,
  ) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final isEditing = editingRowIndex == index;
    final canReorder =
        widget.editMode && widget.onReorder != null && itemIndex >= 0;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    Widget leftCell;
    Widget rightCell;

    // Keep rows visually stable: fixed minimum height for both display and edit states
    const minRowHeight = 52.0; // Increased for better mobile experience

    if (isEditing && editingLeft) {
      leftCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GestureDetector(
            onTap: () {}, // Consume tap to prevent exit editing
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onSubmitted: (val) async => await _saveEdit(index, true, val),
              onEditingComplete: () async =>
                  await _saveEdit(index, true, _controller.text),
            ),
          ),
        ),
      );
    } else {
      leftCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(
          children: [
            // Reorder buttons for assignments
            if (canReorder) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: itemIndex > 0 ? primary : Colors.grey.shade300,
                    ),
                    onPressed: itemIndex > 0
                        ? () => widget.onReorder!(itemIndex, itemIndex - 1)
                        : null,
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: itemIndex < widget.items.length - 1
                          ? primary
                          : Colors.grey.shade300,
                    ),
                    onPressed: itemIndex < widget.items.length - 1
                        ? () => widget.onReorder!(itemIndex, itemIndex + 1)
                        : null,
                  ),
                ],
              ),
            ],
            Expanded(
              child: GestureDetector(
                onTap: widget.editMode
                    ? () async => await _onCellTap(index, true, r.left)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: () {
                    final parts = r.left
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (parts.isNotEmpty) {
                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: parts
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(t, style: textStyle),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Text(r.left, style: textStyle, softWrap: true);
                  }(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isEditing && !editingLeft) {
      rightCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GestureDetector(
            onTap: () {}, // Consume tap to prevent exit editing
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onSubmitted: (val) async => await _saveEdit(index, false, val),
              onEditingComplete: () async =>
                  await _saveEdit(index, false, _controller.text),
            ),
          ),
        ),
      );
    } else {
      rightCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.editMode
                    ? () async => await _onCellTap(index, false, r.right)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: () {
                    final parts = r.right
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (parts.isNotEmpty) {
                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: parts
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(t, style: textStyle),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Text(r.right, style: textStyle, softWrap: true);
                  }(),
                ),
              ),
            ),
            if (widget.editMode && widget.onDeleteAssignment != null) ...[
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => widget.onDeleteAssignment!(index),
              ),
            ],
          ],
        ),
      );
    }

    return TableRow(children: [leftCell, rightCell]);
  }

  // User dropdown functionality removed - to be implemented in a different way

  Future<void> _onCellTap(int index, bool left, String currentValue) async {
    // Save and close any active subsection edit
    if (editingSubsectionItemIndex != null) {
      try {
        _saveSubsectionTitle(
          editingSubsectionItemIndex!,
          _subsectionController.text,
        );
      } catch (_) {
        // ignore save errors here
      }
      editingSubsectionItemIndex = null;
    }
    // if there is an active edit in a different cell, persist it first so we don't lose typed text
    if (editingRowIndex != null &&
        (editingRowIndex != index || editingLeft != left)) {
      try {
        final prevStored = _getStoredValueAt(editingRowIndex!, editingLeft);
        final currentText = _controller.text.trim();
        if (currentText != prevStored.trim()) {
          await _saveEdit(editingRowIndex!, editingLeft, _controller.text);
        }
      } catch (_) {
        // ignore save errors here; UI will still switch to new cell
      }
    }
    setState(() {
      editingRowIndex = index;
      editingLeft = left;
      // populate controller once when beginning to edit so caret/selection is stable
      // currentValue is already stored/display names (comma-separated)
      final parts = currentValue
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _controller.text = parts.join(', ');
    });
  }

  String _getStoredValueAt(int index, bool left) {
    int counter = 0;
    for (final item in widget.items) {
      if (item is Assignment) {
        if (counter == index) return left ? item.left : item.right;
        counter++;
      } else if (item is Subsection) {
        for (final row in item.rows) {
          if (counter == index) return left ? row.left : row.right;
          counter++;
        }
      }
    }
    return '';
  }

  Future<void> _saveEdit(
    int index,
    bool left,
    String newValue, {
    bool keepEditing = false,
  }) async {
    if (widget.onSave != null) {
      await widget.onSave!(index, left, newValue);
    }

    if (!mounted) return;
    setState(() {
      editingRowIndex = keepEditing ? index : null;
      editingLeft = keepEditing ? left : true;
    });

    if (keepEditing) {
      final tokens = newValue
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _controller.text = tokens.join(', ');
    }
  }

  void _startEditingSubsection(int itemIndex, String currentTitle) {
    // Save and close any active cell edit
    if (editingRowIndex != null) {
      try {
        final prevStored = _getStoredValueAt(editingRowIndex!, editingLeft);
        final currentText = _controller.text.trim();
        if (currentText != prevStored.trim()) {
          _saveEdit(editingRowIndex!, editingLeft, _controller.text);
        }
      } catch (_) {
        // ignore save errors here
      }
      editingRowIndex = null;
      editingLeft = true;
    }
    setState(() {
      editingSubsectionItemIndex = itemIndex;
      _subsectionController.text = currentTitle;
    });
  }

  void _saveSubsectionTitle(int itemIndex, String newTitle) {
    if (widget.onSaveSubsection != null) {
      widget.onSaveSubsection!(itemIndex, newTitle);
    }
    if (!mounted) return;
    setState(() {
      editingSubsectionItemIndex = null;
    });
  }
}
