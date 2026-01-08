import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_simple_contact/flutter_simple_contact.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _flutterSimpleContactPlugin = FlutterSimpleContact();

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchMobileAndNameOnly() async {
    try {
      final raw = await FlutterSimpleContact.fetchContactsRaw(
        options: {
          "handlePermission": true,
          "mode": "unified",
          "sort": "alphabetical",
          "filters": {
            "onlyWithPhone": true, // ✅ Only contacts with phone numbers
            "onlyStarred": false,
            "onlyWithPhoto": false,
          },
          "minimizeData": true, // ✅ Skip extra metadata queries
          "advanced": {"enableProgressEvents": false, "includeNotes": false},
        },
      );

      // Extract only name + phones
      final contacts = (raw["contacts"] as List? ?? []).map((c) {
        return {
          "name": c["displayName"] ?? "Unknown",
          "phones": c["phones"] ?? [],
        };
      }).toList();

      debugPrint("Simple contacts: $contacts");
    } catch (e) {
      throw Exception('Failed to fetch contacts: $e');
    }
  }

  Future<void> fetchRawDetailedContact() async {
    final raw = await FlutterSimpleContact.fetchContactsRaw(
      options: {
        "handlePermission": true,
        "mode": "unified",
        "sort": "alphabetical",
        "filters": {
          "onlyWithPhone": false,
          "onlyStarred": false,
          "onlyWithPhoto": false,
        },
        "minimizeData": false,
        "advanced": {
          "enableProgressEvents": false,
          "includeNotes":
              false, // iOS notes entitlement required; keep false by default [web:77]
        },
      },
    );

    final contacts = (raw["contacts"] as List? ?? const []);
    print('Raw contacts: ${contacts}');
  }

  Future<void> fetchMinContactTyped() async {
    final res = await FlutterSimpleContact.fetchContacts(
      options: SimpleFetchOptions(
        handlePermission: true,
        mode: SimpleContactMode.unified,
        sort: SimpleSort.alphabetical,
        filters: const SimpleFetchFilters(onlyWithPhone: true),
      ),
    );

    debugPrint("ok=${res.ok} status=${res.status} err=${res.errorMessage}");
    debugPrint("contacts=${res.contacts.length}");
    debugPrint("contacts=${res.contacts.asMap().toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: GestureDetector(
            onTap: () async {
              await fetchMinContactTyped();
            },
            child: Text('Running on: $_platformVersion\n'),
          ),
        ),
      ),
    );
  }
}
