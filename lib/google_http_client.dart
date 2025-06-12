import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    return _client.head(url, headers: headers ?? _headers);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: headers ?? _headers);
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _client.post(
      url,
      headers: headers ?? _headers,
      body: body,
      encoding: encoding,
    );
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _client.put(
      url,
      headers: headers ?? _headers,
      body: body,
      encoding: encoding,
    );
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return _client.delete(
      url,
      headers: headers ?? _headers,
      body: body,
      encoding: encoding,
    );
  }
}
