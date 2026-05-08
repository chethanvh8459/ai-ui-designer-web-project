import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:stac/stac.dart';

class CodeViewerScreen extends StatefulWidget {
  final String projectName;
  final String code;

  const CodeViewerScreen({
    super.key,
    required this.projectName,
    required this.code,
  });

  @override
  State<CodeViewerScreen> createState() => _CodeViewerScreenState();
}

class _CodeViewerScreenState extends State<CodeViewerScreen> {
  late WebViewController _webViewController;
  bool isHtml = false;
  final Color primaryColor = const Color(0xFF6366F1);
  final Color secondaryColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    isHtml = widget.code.trim().startsWith('<!DOCTYPE') ||
             widget.code.trim().startsWith('<html') ||
             widget.code.trim().startsWith('<body');

    _webViewController = WebViewController();

    // 🔥 BOTH mobile-only commands are now safely inside this check!
    if (!kIsWeb) {
      _webViewController
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF8FAFC));
    }

    // This stays outside so the HTML content loads on all platforms (Web + Mobile)
    _webViewController.loadHtmlString(_wrapHtmlContent(widget.code));
  }

  String _wrapHtmlContent(String code) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            padding: 20px;
            background: #F8FAFC;
            color: #1E293B;
          }
        </style>
      </head>
      <body>
        $code
      </body>
      </html>
    ''';
  }

  void _showCodeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.code, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Source Code",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    widget.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.greenAccent,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade800)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Code copied!")),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy Code"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ); 
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? uiJson;
    
    if (!isHtml) {
      try {
        uiJson = jsonDecode(widget.code);
      } catch (e) {
        debugPrint("Failed to parse JSON: $e");
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.projectName,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.code, color: Colors.white, size: 20),
              ),
              onPressed: _showCodeSheet,
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isHtml
              ? WebViewWidget(controller: _webViewController)
              : (uiJson != null
                  ? Stac.fromJson(uiJson, context) ?? const Center(child: Text("Unable to render this design"))
                  : const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.code_off, size: 64, color: Colors.grey), SizedBox(height: 16), Text("Invalid format")],
                    ))),
        ),
      ),
    );
  }
}