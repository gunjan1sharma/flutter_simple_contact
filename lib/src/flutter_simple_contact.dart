import 'dart:convert';
import 'package:flutter/services.dart';

import 'models.dart';

class FlutterSimpleContact {
  static const MethodChannel _channel = MethodChannel(
    'flutter_simple_contact/methods',
  );

  /// Fetch contacts from native layers.
  /// Native side will: (optional) handle permission, fetch unified/raw, apply basic filters/sort.
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

  /// Utility: return in multiple formats
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
