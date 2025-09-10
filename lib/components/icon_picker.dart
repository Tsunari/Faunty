import 'package:flutter/material.dart';
import 'package:faunty/models/custom_list.dart';
import 'package:faunty/helper/icon_registry.dart';

/// A modern, searchable Material icon picker.
/// Tap the preview to open a modal picker containing a searchable grid of icons.
class IconPicker extends StatefulWidget {
  final IconSpec? selected;
  final ValueChanged<IconSpec> onSelected;
  const IconPicker({super.key, this.selected, required this.onSelected});

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  // A curated list of Material icons with human-readable names used for searching.
  static final List<MapEntry<String, IconData>> _icons = [
    MapEntry('post_add_outlined', Icons.post_add_outlined),
    MapEntry('list_alt', Icons.list_alt),
    MapEntry('event', Icons.event),
    MapEntry('check_circle_outline', Icons.check_circle_outline),
    MapEntry('person', Icons.person),
    MapEntry('schedule', Icons.schedule),
    MapEntry('star_border', Icons.star_border),
    MapEntry('add', Icons.add),
    MapEntry('add_box', Icons.add_box),
    MapEntry('create', Icons.create),
    MapEntry('edit', Icons.edit),
    MapEntry('delete', Icons.delete),
    MapEntry('delete_outline', Icons.delete_outline),
    MapEntry('calendar_today', Icons.calendar_today),
    MapEntry('alarm', Icons.alarm),
    MapEntry('assignment', Icons.assignment),
    MapEntry('work', Icons.work),
    MapEntry('shopping_cart', Icons.shopping_cart),
    MapEntry('home', Icons.home),
    MapEntry('school', Icons.school),
    MapEntry('group', Icons.group),
    MapEntry('chat', Icons.chat),
    MapEntry('message', Icons.message),
    MapEntry('mail', Icons.mail),
    MapEntry('settings', Icons.settings),
    MapEntry('tune', Icons.tune),
    MapEntry('info', Icons.info),
    MapEntry('help', Icons.help),
    MapEntry('search', Icons.search),
    MapEntry('favorite', Icons.favorite),
    MapEntry('favorite_border', Icons.favorite_border),
    MapEntry('bookmark', Icons.bookmark),
    MapEntry('bookmarks', Icons.bookmarks),
    MapEntry('visibility', Icons.visibility),
    MapEntry('visibility_off', Icons.visibility_off),
    MapEntry('cloud', Icons.cloud),
    MapEntry('cloud_upload', Icons.cloud_upload),
    MapEntry('cloud_download', Icons.cloud_download),
    MapEntry('upload', Icons.upload),
    MapEntry('download', Icons.download),
    MapEntry('link', Icons.link),
    MapEntry('attach_file', Icons.attach_file),
    MapEntry('image', Icons.image),
    MapEntry('photo', Icons.photo),
    MapEntry('camera_alt', Icons.camera_alt),
    MapEntry('map', Icons.map),
    MapEntry('location_on', Icons.location_on),
    MapEntry('place', Icons.place),
    MapEntry('room', Icons.room),
    MapEntry('videocam', Icons.videocam),
    MapEntry('phone', Icons.phone),
    MapEntry('call', Icons.call),
    MapEntry('contact_mail', Icons.contact_mail),
    MapEntry('contacts', Icons.contacts),
    MapEntry('timer', Icons.timer),
    MapEntry('timer_off', Icons.timer_off),
    MapEntry('play_arrow', Icons.play_arrow),
    MapEntry('pause', Icons.pause),
    MapEntry('stop', Icons.stop),
    MapEntry('fast_forward', Icons.fast_forward),
    MapEntry('fast_rewind', Icons.fast_rewind),
    MapEntry('refresh', Icons.refresh),
    MapEntry('sync', Icons.sync),
    MapEntry('done', Icons.done),
    MapEntry('done_all', Icons.done_all),
    MapEntry('notification_important', Icons.notification_important),
    MapEntry('notifications', Icons.notifications),
    MapEntry('build', Icons.build),
    MapEntry('code', Icons.code),
    MapEntry('bug_report', Icons.bug_report),
    MapEntry('security', Icons.security),
    MapEntry('lock', Icons.lock),
    MapEntry('unlock', Icons.lock_open),
    MapEntry('shopping_bag', Icons.shopping_bag),
    MapEntry('monetization_on', Icons.monetization_on),
    MapEntry('attach_money', Icons.attach_money),
    MapEntry('trending_up', Icons.trending_up),
    MapEntry('trending_down', Icons.trending_down),
    MapEntry('pie_chart', Icons.pie_chart_outline),
    MapEntry('bar_chart', Icons.bar_chart),
    MapEntry('insert_chart', Icons.insert_chart),
    MapEntry('lightbulb', Icons.lightbulb),
    MapEntry('battery_std', Icons.battery_std),
    MapEntry('wifi', Icons.wifi),
    MapEntry('bluetooth', Icons.bluetooth),
    MapEntry('extension', Icons.extension),
    MapEntry('folder', Icons.folder),
    MapEntry('folder_open', Icons.folder_open),
    MapEntry('more_vert', Icons.more_vert),
    MapEntry('more_horiz', Icons.more_horiz),
    MapEntry('menu', Icons.menu),
    MapEntry('dashboard', Icons.dashboard),
    MapEntry('list', Icons.list),
    MapEntry('grid_view', Icons.grid_view),
    MapEntry('view_list', Icons.view_list),
  ];

  String _query = '';

  void _openPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateSB) {
          final q = _query.toLowerCase();
          final filtered = _icons.where((e) => e.key.contains(q) || e.key.replaceAll('_', ' ').contains(q)).toList();
          return SafeArea(
            child: Padding(
              padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.all(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 40,
                    child: TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search icons', border: OutlineInputBorder()),
                      onChanged: (v) {
                        setStateSB(() => _query = v);
                        // also update parent state so next opening has the same query
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    height: 360,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final entry = filtered[idx];
                        final icon = entry.value;
                        final codePoint = icon.codePoint;
                        final isSelected = widget.selected?.kind == 'material' && widget.selected?.codePoint == codePoint;
                        return Material(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              widget.onSelected(IconSpec.material(codePoint, fontFamily: icon.fontFamily));
                              Navigator.of(ctx).pop();
                            },
                            child: Center(child: Icon(icon, size: 22)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  final display = widget.selected != null && widget.selected!.kind == 'material'
    ? Icon(iconFromSpec(widget.selected))
    : const Icon(Icons.post_add_outlined);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openPicker,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor)),
            child: display,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(onPressed: _openPicker, icon: const Icon(Icons.expand_more), label: const Text('Choose')),
      ],
    );
  }
}
