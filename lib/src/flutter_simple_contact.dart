import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

class FlutterSimpleContact {
  static const MethodChannel _channel = MethodChannel(
    'flutter_simple_contact/methods',
  );
  static const EventChannel _events = EventChannel(
    'flutter_simple_contact/events',
  );

  static Stream<Map<dynamic, dynamic>> progressStreamRaw() =>
      _events.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();

  /// NEW: returns raw maps for full metadata without expanding Dart models.
  static Future<Map<String, dynamic>> fetchContactsRaw({
    required Map<String, dynamic> options,
  }) async {
    final raw = await _channel.invokeMethod<Map>('fetchContacts', options);
    return (raw ?? <dynamic, dynamic>{}).cast<String, dynamic>();
  }

  static Stream<SimpleProgressEvent> progressStream() {
    return _events.receiveBroadcastStream().map((e) {
      return SimpleProgressEvent.fromMap(e as Map);
    });
  }

  static Future<void> cancelFetch() async {
    await _channel.invokeMethod('cancelFetch');
  }

  static Future<SimpleFetchResult> fetchContacts({
    required SimpleFetchOptions options,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map>(
        'fetchContacts',
        options.toMap(),
      );
      final map = (raw ?? <dynamic, dynamic>{}).cast<String, dynamic>();

      final contactsRaw = (map['contacts'] as List?) ?? const [];
      final contacts = contactsRaw
          .map((e) => _parseContact((e as Map).cast<String, dynamic>()))
          .toList();

      return SimpleFetchResult(
        ok: map['ok'] == true,
        status: (map['status'] as String?) ?? 'error',
        errorCode: map['errorCode'] as String?,
        errorMessage: map['errorMessage'] as String?,
        contacts: contacts,
      );
    } catch (e) {
      return SimpleFetchResult(
        ok: false,
        status: 'error',
        errorCode: 'dart_exception',
        errorMessage: e.toString(),
        contacts: const [],
      );
    }
  }

  static String toJsonString(SimpleFetchResult result) =>
      jsonEncode(result.toMap());
  static List<Map<String, dynamic>> toListOfMaps(SimpleFetchResult result) =>
      result.contacts.map((c) => c.toMap()).toList();

  static SimpleContact _parseContact(Map<String, dynamic> m) {
    final phonesRaw = (m['phones'] as List?) ?? const [];
    return SimpleContact(
      id: (m['id'] as String?) ?? '',
      rawContactId: m['rawContactId'] as String?,
      displayName: (m['displayName'] as String?) ?? '',
      phones: phonesRaw
          .map((p) => (p as Map).cast<String, dynamic>())
          .map(
            (p) => SimplePhone(
              number: (p['number'] as String?) ?? '',
              label: p['label'] as String?,
              normalizedNumber: p['normalizedNumber'] as String?,
            ),
          )
          .toList(),
      lastModifiedMillis: m['lastModifiedMillis'] as int?,
      starred: m['starred'] as bool?,
      hasPhoto: m['hasPhoto'] as bool?,
    );
  }
}
