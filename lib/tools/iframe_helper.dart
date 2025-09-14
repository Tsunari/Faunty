// Web implementation using webview_flutter's WebViewWidget
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildIFrame(String url, String viewId) {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(url));

  return SizedBox(
    height: 480,
    child: WebViewWidget(controller: controller),
  );
}
