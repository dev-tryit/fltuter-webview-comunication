import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum ToJavascriptEvent {
 ALERT
}

enum FromJavascriptEvent {
 PRINT
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const javascriptChannel = "MyHomePageChannel";
  final _controller = WebViewController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        javascriptChannel,
        onMessageReceived: fromJavascript,
      )
      ..loadFlutterAsset('assets/www/index.html');
    // ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text('Webview')),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_upward),
        onPressed: () {
          toJavascript(ToJavascriptEvent.ALERT, ["a"]);
        },
      ),
    );
  }

  void fromJavascript(JavaScriptMessage javaScriptMessage) {
    String messageStr = javaScriptMessage.message;
    print("fromJavascript messageStr:$messageStr");
    Map<String,dynamic> message = jsonDecode(messageStr) as Map<String,dynamic>;

    String? type = message["type"];
    Map<String,dynamic>? result = message["result"];
    if(type == "${FromJavascriptEvent.PRINT}") {
      print(result);
    }
  }

  void toJavascript(ToJavascriptEvent event, List<dynamic> param) {
    if(event == ToJavascriptEvent.ALERT) {
      _controller.runJavaScript("alert('${param.join(",")}')");
    }
  }

}
