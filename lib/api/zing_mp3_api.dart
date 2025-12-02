import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

class ZingMp3Api {
  final String url;
  final String apiKey;
  final String secretKey;
  final String version;

  late final Dio _dio;
  late final CookieJar _cookieJar;

  ZingMp3Api({
    required this.url,
    required this.apiKey,
    required this.secretKey,
    required this.version,
  }) {
    _cookieJar = CookieJar();
    _dio = Dio(
      BaseOptions(
        baseUrl: url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
          'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7',
          'Referer': 'https://zingmp3.vn/',
          'Origin': 'https://zingmp3.vn',
        },
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // Hash signature
  String _getHash256(String str) {
    return sha256.convert(utf8.encode(str)).toString();
  }

  String _getHmac512(String str, String key) {
    final hmac = Hmac(sha512, utf8.encode(key));
    return hmac.convert(utf8.encode(str)).toString();
  }

  String _hashHasIdSignature(String apiPath, String id, String ctime) {
    return _getHmac512(
      apiPath + _getHash256('ctime=${ctime}id=${id}version=$version'),
      secretKey,
    );
  }

  String _hashNoIdSignature(String apiPath, String ctime) {
    return _getHmac512(
      apiPath + _getHash256('ctime=${ctime}version=$version'),
      secretKey,
    );
  }

  String _hashHomeRadioSignature(String apiPath, int count, String ctime) {
    return _getHmac512(
      apiPath +
          _getHash256('count=${count}ctime=${ctime}page=1version=$version'),
      secretKey,
    );
  }

  String _hashListGenreSignature(
    String apiPath,
    String id,
    int page,
    String ctime,
  ) {
    return _getHmac512(
      apiPath +
          _getHash256(
            'count=10ctime=${ctime}id=${id}page=${page}version=$version',
          ),
      secretKey,
    );
  }

  String _hashListMvSignature(
    String apiPath,
    int count,
    String id,
    String type,
    int page,
    String ctime,
  ) {
    return _getHmac512(
      apiPath +
          _getHash256(
            'count=${count}ctime=${ctime}id=${id}page=${page}type=${type}version=$version',
          ),
      secretKey,
    );
  }

  String _hashCategoryMvSignature(
    String apiPath,
    String id,
    String type,
    String ctime,
  ) {
    return _getHmac512(
      apiPath +
          _getHash256('ctime=${ctime}id=${id}type=${type}version=$version'),
      secretKey,
    );
  }

  String _hashSearchSignature(
    String apiPath,
    int count,
    int page,
    String type,
    String ctime,
  ) {
    return _getHmac512(
      apiPath +
          _getHash256(
            'count=${count}ctime=${ctime}page=${page}type=${type}version=$version',
          ),
      secretKey,
    );
  }

  // Lấy cookie trước khi gọi API
  Future<void> _initCookie() async {
    try {
      await _dio.get('/');
    } catch (e) {
      debugPrint('Error init cookie: $e');
    }
  }

  // Send Request
  Future<Map<String, dynamic>?> _sendRequest(
    String apiPath,
    Map<String, String> params, {
    required String ctime,
    bool isSuggestion = false,
  }) async {
    try {
      // Lấy cookie trước
      await _initCookie();

      final queryParams = {
        ...params,
        'ctime': ctime,
        'version': version,
        'apiKey': apiKey,
      };

      final baseUrl = isSuggestion ? 'https://ac.zingmp3.vn' : url;
      final requestUrl = '$baseUrl$apiPath';

      debugPrint('Request URL: $requestUrl');
      debugPrint('Params: $queryParams');

      final response = await _dio.get(requestUrl, queryParameters: queryParams);

      debugPrint('Response: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error sending request: $e');
      return null;
    }
  }

  // ==================== PUBLIC METHODS ====================

  Future<Map<String, dynamic>?> getHome() async {
    const apiPath = '/api/v2/page/get/home';
    const count = 30;
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'page': '1',
      'count': '$count',
      'segmentId': '-1',
      'sig': _hashHomeRadioSignature(apiPath, count, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getSong(String id) async {
    const apiPath = '/api/v2/song/get/streaming';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getSongInfo(String id) async {
    const apiPath = '/api/v2/song/get/info';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getSongLyric(String id) async {
    const apiPath = '/api/v2/lyric/get/lyric';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getHomeChart() async {
    const apiPath = '/api/v2/page/get/chart-home';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getNewReleaseChart() async {
    const apiPath = '/api/v2/page/get/newrelease-chart';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getWeekChart(
    String id, {
    int week = 0,
    int year = 0,
  }) async {
    const apiPath = '/api/v2/page/get/week-chart';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'week': '$week',
      'year': '$year',
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getRadio() async {
    const apiPath = '/api/v2/page/get/radio';
    const count = 10;
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'page': '1',
      'count': '$count',
      'sig': _hashHomeRadioSignature(apiPath, count, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getListByGenre(
    String id, {
    int page = 1,
  }) async {
    const apiPath = '/api/v2/feed/get/list-by-genre';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'page': '$page',
      'count': '10',
      'sig': _hashListGenreSignature(apiPath, id, page, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getArtist(String name) async {
    const apiPath = '/api/v2/page/get/artist';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'alias': name,
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getListArtistSong(
    String artistId,
    String page,
    String count,
  ) async {
    const apiPath = '/api/v2/song/get/list';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': artistId,
      'type': 'artist',
      'page': page,
      'count': count,
      'sort': 'new',
      'sectionId': 'aSong',
      'sig': _hashListMvSignature(
        apiPath,
        int.parse(count),
        artistId,
        'artist',
        int.parse(page),
        ctime,
      ),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getHubHome() async {
    const apiPath = '/api/v2/page/get/hub-home';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getHubDetail(String id) async {
    const apiPath = '/api/v2/page/get/hub-detail';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getTop100() async {
    const apiPath = '/api/v2/page/get/top-100';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getListMv(
    String id, {
    int page = 1,
    int count = 15,
    String sort = 'listen',
  }) async {
    const apiPath = '/api/v2/video/get/list';
    const type = 'genre';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'type': type,
      'page': '$page',
      'count': '$count',
      'sort': sort,
      'sig': _hashListMvSignature(apiPath, count, id, type, page, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getCategoryMv(String id) async {
    const apiPath = '/api/v2/genre/get/info';
    const type = 'video';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'type': type,
      'sig': _hashCategoryMvSignature(apiPath, id, type, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getMv(String id) async {
    const apiPath = '/api/v2/page/get/video';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getPlaylist(String id) async {
    const apiPath = '/api/v2/page/get/playlist';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getSuggestedPlaylists(String id) async {
    const apiPath = '/api/v2/playlist/get/section-bottom';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getEvents() async {
    const apiPath = '/api/v2/event/get/list-incoming';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getEventInfo(String id) async {
    const apiPath = '/api/v2/event/get/info';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'id': id,
      'sig': _hashHasIdSignature(apiPath, id, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> searchAll(String keyword) async {
    const apiPath = '/api/v2/search/multi';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'q': keyword,
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> searchByType(
    String keyword,
    String type, {
    int page = 1,
    int count = 18,
  }) async {
    const apiPath = '/api/v2/search';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'q': keyword,
      'type': type,
      'page': '$page',
      'count': '$count',
      'sig': _hashSearchSignature(apiPath, count, page, type, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getRecommendKeyword() async {
    const apiPath = '/api/v2/app/get/recommend-keyword';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(apiPath, {
      'sig': _hashNoIdSignature(apiPath, ctime),
    }, ctime: ctime);
  }

  Future<Map<String, dynamic>?> getSuggestionKeyword(String? keyword) async {
    const apiPath = '/v1/web/suggestion-keywords';
    final ctime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    return _sendRequest(
      apiPath,
      {
        'num': '10',
        'query': keyword ?? '',
        'language': 'vi',
        'sig': _hashNoIdSignature(apiPath, ctime),
      },
      ctime: ctime,
      isSuggestion: true,
    );
  }
}

// Instance mặc định
final zing = ZingMp3Api(
  url: 'https://zingmp3.vn',
  apiKey: '88265e23d4284f25963e6eedac8fbfa3',
  secretKey: '2aa2d1c561e809b267f3638c4a307aab',
  version: '1.6.40',
);
