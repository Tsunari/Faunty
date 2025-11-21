import '../app_notification.dart';

class CustomNotification extends AppNotification {
  final String _title;
  final String _body;
  final Map<String, dynamic>? _payload;
  final String? _imageUrl;
  final String? _launchUrl;

  CustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? imageUrl,
    String? launchUrl,
  })  : _title = title,
        _body = body,
        _payload = payload,
        _imageUrl = imageUrl,
        _launchUrl = launchUrl;

  @override
  String get title => _title;

  @override
  String get body => _body;

  @override
  Map<String, dynamic>? get payload => _payload;

  @override
  String? get imageUrl => _imageUrl;

  @override
  String? get launchUrl => _launchUrl;
}
