import 'dart:math';
import 'package:faunty/models/user_roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/user_list_provider.dart';
import '../models/user_entity.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _subsectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final headerStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final headerHeight = 36.0;

    final theme = Theme.of(context);
    final containerColor = theme.cardColor;
    final primary = theme.colorScheme.primary;

    // Build blocks: either Tables of assignments or subsection header + table
    final blocks = <Widget>[];
    final pending = <Assignment>[];
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
        children: pending.map((r) => _buildRow(context, r, flatCounter++)).toList(),
      );
      blocks.add(table);
      pending.clear();
    }

    for (int itemIndex = 0; itemIndex < widget.items.length; itemIndex++) {
      final item = widget.items[itemIndex];
      if (item is Assignment) {
        pending.add(item);
      } else if (item is Subsection) {
        // flush assignments before subsection
        flushPending();
        // subsection header: support inline editing when requested
        if (editingSubsectionItemIndex == itemIndex) {
          blocks.add(Container(
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
                      child: TextField(
                        controller: _subsectionController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
                        onSubmitted: (val) => _saveSubsectionTitle(itemIndex, val),
                      ),
                    ),
                  ),
                  if (widget.editMode && widget.onDeleteSubsection != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => widget.onDeleteSubsection!(itemIndex),
                    ),
                  ],
                ],
              ),
            ),
          ));
        } else {
          blocks.add(GestureDetector(
            onTap: () => _startEditingSubsection(itemIndex, item.title),
            child: Container(
              height: headerHeight,
              color: primary.withOpacity(0.12),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.title, style: headerStyle?.copyWith(color: primary)),
                  if (widget.editMode && widget.onDeleteSubsection != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => widget.onDeleteSubsection!(itemIndex),
                    ),
                  ],
                ],
              ),
            ),
          ));
        }

        // add subsection rows as a separate table
        final subTable = Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade300),
            verticalInside: BorderSide(color: Colors.grey.shade200),
          ),
          children: item.rows.map((r) => _buildRow(context, r, flatCounter++)).toList(),
        );
        blocks.add(subTable);
      }
    }
    flushPending();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: containerColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showColumnHeaders) ...[
            Table(
              columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
              children: [
                TableRow(children: [
                  Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), child: Text(widget.leftHeader ?? 'Left', style: headerStyle)),
                  Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), child: Text(widget.rightHeader ?? 'Right', style: headerStyle)),
                ]),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // render blocks sequentially with separators between them so borders remain visible
          ..._interleaveWithSeparators(blocks, Theme.of(context).dividerColor),
        ],
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

  TableRow _buildRow(BuildContext context, Assignment r, int index) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
  // watch users with roles hoca,baskan,talebe for the current place
  final rolesKey = [UserRole.talebe, UserRole.baskan, UserRole.hoca].map((r) => r.name).join(',');
  final usersAsync = ref.watch(usersByRolesAndPlaceProvider(rolesKey));
  final usersList = usersAsync.asData?.value ?? <UserEntity>[];
  final Map<String, UserEntity> usersByName = {for (var u in usersList) '${u.firstName} ${u.lastName}': u};
    final isEditing = editingRowIndex == index;
    Widget leftCell;
    Widget rightCell;

    // Keep rows visually stable: fixed minimum height for both display and edit states
    const minRowHeight = 44.0;
    const iconSize = 20.0;

    // Helper to build the trailing icon buttons (do nothing for now)
    List<Widget> buildTrailingButtons() {
      return [
        // IconButton opens a dropdown anchored to the button; use Builder to get button context
        Builder(builder: (btnCtx) {
    return IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.person,
              size: iconSize,
          color: (editingLeft ? r.left : r.right)
            .split(',')
            .map((s) => s.trim())
            .any((p) => usersByName.containsKey(p))
        ? Theme.of(context).colorScheme.primary
        : null,
            ),
            onPressed: () => _showUserDropdown(index, editingLeft, btnCtx, usersList, editingLeft ? r.left : r.right),
          );
        }),
        const SizedBox(width: 6),
        IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.calendar_today, size: iconSize), onPressed: () {}),
        const SizedBox(width: 6),
        editingLeft ? Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.access_time, size: iconSize), onPressed: () {}),
        ) : IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.access_time, size: iconSize), onPressed: () {}),
      ];
    }

    if (isEditing && editingLeft) {
      leftCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                  onSubmitted: (val) async => await _saveEdit(index, true, val),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ...buildTrailingButtons(),
          if (widget.editMode && widget.onDeleteAssignment != null) ...[
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
              onPressed: () => widget.onDeleteAssignment!(index),
            ),
          ],
        ]),
      );
    } else {
      leftCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
              onTap: () async => await _onCellTap(index, true, r.left),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: () {
                  final parts = r.left.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  if (parts.isNotEmpty) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: parts.map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: Text(t, style: textStyle))).toList(),
                    );
                  }
                  return Text(r.left, style: textStyle, softWrap: true);
                }(),
              ),
            ),
          ),
        ]),
      );
    }

    if (isEditing && !editingLeft) {
      rightCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onSubmitted: (val) async => await _saveEdit(index, false, val),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ...buildTrailingButtons(),
          if (widget.editMode && widget.onDeleteAssignment != null) ...[
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
              onPressed: () => widget.onDeleteAssignment!(index),
            ),
          ],
        ]),
      );
    } else {
      rightCell = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minRowHeight),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
              onTap: () async => await _onCellTap(index, false, r.right),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: () {
                  final parts = r.right.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  if (parts.isNotEmpty) {
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: parts.map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: Text(t, style: textStyle))).toList(),
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
              icon: Icon(Icons.delete, size: iconSize, color: Colors.red),
              onPressed: () => widget.onDeleteAssignment!(index),
            ),
          ],
        ]),
      );
    }

    return TableRow(children: [leftCell, rightCell]);
  }

  Future<void> _showUserDropdown(int index, bool editingLeft, BuildContext buttonContext, List<UserEntity> usersList, String currentValue) async {
    // currentValue now stores display names (comma separated)
    final currentNames = currentValue.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final selected = <String>{}..addAll(currentNames);

    final items = <PopupMenuEntry<int>>[];
    // use StatefulBuilder inside a custom menu to manage selection
    items.add(PopupMenuItem<int>(enabled: false, child: SizedBox(height: 300, width: 300, child: StatefulBuilder(builder: (ctx, setState) {
      return ListView.separated(
        shrinkWrap: true,
        itemCount: usersList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = usersList[i];
          final displayName = '${u.firstName} ${u.lastName}';
          final isSel = selected.contains(displayName);
          return CheckboxListTile(
            value: isSel,
            onChanged: (v) async {
              setState(() {
                if (v == true) selected.add(displayName); else selected.remove(displayName);
              });
              // persist selection immediately and keep editing
              await _saveEdit(index, editingLeft, selected.join(','), keepEditing: true);
            },
            title: Text(displayName),
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      );
    }))));

    // compute button position to anchor menu fully above or fully below the button
    final RenderBox btnBox = buttonContext.findRenderObject() as RenderBox;
    final btnPos = btnBox.localToGlobal(Offset.zero);
    final btnSize = btnBox.size;
    final screenSize = MediaQuery.of(buttonContext).size;
    const double menuWidth = 300.0;
    final double menuHeight = min(screenSize.height * 0.5, usersList.length * 56.0 + 16.0);
    const double margin = 6.0;

    // decide whether to show below or above based on available space
    final double spaceBelow = screenSize.height - (btnPos.dy + btnSize.height) - margin;
    final double spaceAbove = btnPos.dy - margin;
    final bool showBelow = spaceBelow >= menuHeight || spaceBelow >= spaceAbove;

    // compute horizontal left, clamp to screen
    double left = btnPos.dx;
    if (left + menuWidth + margin > screenSize.width) {
      left = max(margin, screenSize.width - menuWidth - margin);
    }

    double top, bottom;
    if (showBelow) {
      top = btnPos.dy + btnSize.height + margin;
      bottom = top + menuHeight;
      // ensure bottom doesn't exceed screen; if it does, nudge top up
      if (bottom + margin > screenSize.height) {
        bottom = screenSize.height - margin;
        top = bottom - menuHeight;
      }
    } else {
      bottom = btnPos.dy - margin;
      top = bottom - menuHeight;
      // if top goes off-screen, clamp
      if (top < margin) {
        top = margin;
        bottom = top + menuHeight;
      }
    }

    await showMenu<int>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(left, top, left + menuWidth, bottom),
      items: items,
    );
  }

  Future<void> _onCellTap(int index, bool left, String currentValue) async {
    // if there is an active edit in a different cell, persist it first so we don't lose typed text
    if (editingRowIndex != null && (editingRowIndex != index || editingLeft != left)) {
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
      final parts = currentValue.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
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

  Future<void> _saveEdit(int index, bool left, String newValue, {bool keepEditing = false}) async {
    // Find corresponding item and update it in-place
    int counter = 0;
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item is Assignment) {
        if (counter == index) {
          final updated = Assignment(left: left ? newValue : item.left, right: left ? item.right : newValue, extras: item.extras);
          setState(() {
            widget.items[i] = updated;
            editingRowIndex = keepEditing ? index : null;
          });
          // delegate persistence to optional callback
          if (widget.onSave != null) {
            await widget.onSave!(index, left, newValue);
          }
          if (keepEditing) {
            // controller should reflect the display names (we store names now)
            final tokens = newValue.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            _controller.text = tokens.join(', ');
          }
          return;
        }
        counter++;
      } else if (item is Subsection) {
        for (int j = 0; j < item.rows.length; j++) {
          if (counter == index) {
            final old = item.rows[j];
            final updated = Assignment(left: left ? newValue : old.left, right: left ? old.right : newValue, extras: old.extras);
            final newRows = List<Assignment>.from(item.rows);
            newRows[j] = updated;
            final newSub = Subsection(title: item.title, rows: newRows);
            setState(() {
              widget.items[i] = newSub;
              editingRowIndex = null;
            });
            if (widget.onSave != null) {
              await widget.onSave!(index, left, newValue);
            }
            return;
          }
          counter++;
        }
      }
    }
  }

  void _startEditingSubsection(int itemIndex, String currentTitle) {
    setState(() {
      editingSubsectionItemIndex = itemIndex;
      _subsectionController.text = currentTitle;
    });
  }

  void _saveSubsectionTitle(int itemIndex, String newTitle) {
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item is Subsection && i == itemIndex) {
        final updated = Subsection(title: newTitle, rows: item.rows);
        setState(() {
          widget.items[i] = updated;
          editingSubsectionItemIndex = null;
        });
        return;
      }
    }
  }
}
