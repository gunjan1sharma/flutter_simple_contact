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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: GestureDetector(
            onTap: () async {
              final res = await FlutterSimpleContact.fetchContacts(
                options: SimpleFetchOptions(
                  handlePermission: true,
                  mode: SimpleContactMode.unified,
                  sort: SimpleSort.alphabetical,
                  filters: const SimpleFetchFilters(onlyWithPhone: true),
                ),
              );

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
                    "enableProgressEvents": true,
                    "includeNotes":
                        false, // iOS notes entitlement required; keep false by default [web:77]
                  },
                },
              );

              final contacts = (raw["contacts"] as List? ?? const []);
              print('Raw contacts: ${contacts}');

              debugPrint(
                "ok=${res.ok} status=${res.status} err=${res.errorMessage}",
              );
              debugPrint("contacts=${res.contacts.length}");
              debugPrint("contacts=${res.contacts.asMap().toString()}");
            },
            child: Text('Running on: $_platformVersion\n'),
          ),
        ),
      ),
    );
  }
}
