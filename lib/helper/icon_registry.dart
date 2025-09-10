import 'package:flutter/material.dart';
import 'package:faunty/models/custom_list.dart';

/// Curated registry of material icons used by the app.
/// Keep this small so tree-shaken builds stay small.
const Map<String, IconData> materialIconRegistry = {
  'post_add_outlined': Icons.post_add_outlined,
  'list_alt': Icons.list_alt,
  'event': Icons.event,
  'check_circle_outline': Icons.check_circle_outline,
  'person': Icons.person,
  'schedule': Icons.schedule,
  'star_border': Icons.star_border,
  'add': Icons.add,
  'add_box': Icons.add_box,
  'create': Icons.create,
  'edit': Icons.edit,
  'delete': Icons.delete,
  'delete_outline': Icons.delete_outline,
  'calendar_today': Icons.calendar_today,
  'alarm': Icons.alarm,
  'assignment': Icons.assignment,
  'work': Icons.work,
  'shopping_cart': Icons.shopping_cart,
  'home': Icons.home,
  'school': Icons.school,
  'group': Icons.group,
  'chat': Icons.chat,
  'message': Icons.message,
  'mail': Icons.mail,
  'settings': Icons.settings,
  'tune': Icons.tune,
  'info': Icons.info,
  'help': Icons.help,
  'search': Icons.search,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'bookmark': Icons.bookmark,
  'bookmarks': Icons.bookmarks,
  'visibility': Icons.visibility,
  'visibility_off': Icons.visibility_off,
  'cloud': Icons.cloud,
  'cloud_upload': Icons.cloud_upload,
  'cloud_download': Icons.cloud_download,
  'upload': Icons.upload,
  'download': Icons.download,
  'link': Icons.link,
  'attach_file': Icons.attach_file,
  'image': Icons.image,
  'photo': Icons.photo,
  'camera_alt': Icons.camera_alt,
  'map': Icons.map,
  'location_on': Icons.location_on,
  'place': Icons.place,
  'room': Icons.room,
  'videocam': Icons.videocam,
  'phone': Icons.phone,
  'call': Icons.call,
  'contact_mail': Icons.contact_mail,
  'contacts': Icons.contacts,
  'timer': Icons.timer,
  'timer_off': Icons.timer_off,
  'play_arrow': Icons.play_arrow,
  'pause': Icons.pause,
  'stop': Icons.stop,
  'fast_forward': Icons.fast_forward,
  'fast_rewind': Icons.fast_rewind,
  'refresh': Icons.refresh,
  'sync': Icons.sync,
  'done': Icons.done,
  'done_all': Icons.done_all,
  'notification_important': Icons.notification_important,
  'notifications': Icons.notifications,
  'build': Icons.build,
  'code': Icons.code,
  'bug_report': Icons.bug_report,
  'security': Icons.security,
  'lock': Icons.lock,
  'unlock': Icons.lock_open,
  'shopping_bag': Icons.shopping_bag,
  'monetization_on': Icons.monetization_on,
  'attach_money': Icons.attach_money,
  'trending_up': Icons.trending_up,
  'trending_down': Icons.trending_down,
  'pie_chart': Icons.pie_chart,
  'bar_chart': Icons.bar_chart,
  'insert_chart': Icons.insert_chart,
  'lightbulb': Icons.lightbulb,
  'battery_std': Icons.battery_std,
  'wifi': Icons.wifi,
  'bluetooth': Icons.bluetooth,
  'extension': Icons.extension,
  'folder': Icons.folder,
  'folder_open': Icons.folder_open,
  'more_vert': Icons.more_vert,
  'more_horiz': Icons.more_horiz,
  'menu': Icons.menu,
  'dashboard': Icons.dashboard,
  'list': Icons.list,
  'grid_view': Icons.grid_view,
  'view_list': Icons.view_list,
};

/// Return a Material [IconData] constant for the provided [IconSpec].
/// If the spec is null or not found in the curated registry, returns [Icons.list].
IconData iconFromSpec(IconSpec? spec) {
  if (spec == null) return Icons.list;
  if (spec.kind == 'material') {
    final cp = spec.codePoint;
    if (cp != null) {
      // look up by codePoint among the registry values
      try {
        return materialIconRegistry.values.firstWhere((i) => i.codePoint == cp);
      } catch (_) {
        // not found
      }
    }
  }
  return Icons.list;
}
