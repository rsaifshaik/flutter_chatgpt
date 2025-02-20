import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint('Loading: $url'),
          onPageFinished: (url) => debugPrint('Loaded: $url'),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    if (Platform.isAndroid) {
      _enableAndroidFileUpload();
    }
  }

  void _enableAndroidFileUpload() {
    final controller = _controller.platform;
    if (controller is AndroidWebViewController) {
      controller.setOnShowFileSelector((params) async {
        final file = await _pickFile();
        if (file != null) {
          return [Uri.file(file.path).toString()];
        }
        return [];
      });
    }
  }

  Future<File?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, // ✅ Allows only selected file types
        allowedExtensions: ['pdf'], // ✅ Restricts to PDFs only
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint("File selection error: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
