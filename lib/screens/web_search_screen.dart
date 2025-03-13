import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_book_marker/bookmark_manager.dart';
import 'package:url_book_marker/common/tags.dart';
import 'package:url_book_marker/model/url_marker.dart';
import 'package:uuid/uuid.dart';

class WebSearchScreen extends ConsumerStatefulWidget {
  const WebSearchScreen({Key? key}) : super(key: key);

  @override
  _WebSearchScreenState createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends ConsumerState<WebSearchScreen> {
  late WebViewController _controller;
  String _currentUrl = 'https://www.google.com';
  bool _isLoading = true;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.google.com');

  @override
  void initState() {
    super.initState();
    _setupWebViewController();
  }

  void _setupWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print("LOGEE  onPageStarted URL: $url");
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print("LOGEE  onPageFinished URL: $url");
            setState(() {
              _isLoading = false;
              _currentUrl = url;
              _urlController.text = url;
            });
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      title: Text('웹페이지 검색', style: TextStyle(color: Colors.white)),
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(Icons.bookmark_add, color: Colors.white),
          onPressed: _saveCurrentPageAsBookmark,
          tooltip: '현재 페이지 북마크 추가',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildUrlBar(),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrlBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: '주소 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (url) {
                _loadUrl(url);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              _loadUrl(_urlController.text);
            },
          ),
        ],
      ),
    );
  }

  void _loadUrl(String url) {
    if (url.isEmpty) return;

    // http:// 또는 https:// 추가
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    _controller.loadRequest(Uri.parse(url));
  }

  void _saveCurrentPageAsBookmark() async {
    // 현재 페이지의 제목 가져오기
    final title = await _controller.getTitle();

    // 북마크 생성
    final bookmark = UrlBookmark(
      id: const Uuid().v4(),
      url: _currentUrl,
      customTitle: title,
      tags: generateTags(_currentUrl),
      isFavorite: false,
    );

    // 북마크 저장
    await ref.read(urlBookmarkProvider.notifier).addUrlBookmark(bookmark);

    // 북마크 목록 화면으로 돌아가기
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}