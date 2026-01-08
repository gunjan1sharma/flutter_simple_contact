import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_simple_contact/flutter_simple_contact.dart';
import 'package:flutter_simple_contact/flutter_simple_contact_platform_interface.dart';
import 'package:flutter_simple_contact/flutter_simple_contact_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSimpleContactPlatform
    with MockPlatformInterfaceMixin
    implements FlutterSimpleContactPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterSimpleContactPlatform initialPlatform = FlutterSimpleContactPlatform.instance;

  test('$MethodChannelFlutterSimpleContact is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterSimpleContact>());
  });

  test('getPlatformVersion', () async {
    FlutterSimpleContact flutterSimpleContactPlugin = FlutterSimpleContact();
    MockFlutterSimpleContactPlatform fakePlatform = MockFlutterSimpleContactPlatform();
    FlutterSimpleContactPlatform.instance = fakePlatform;

    expect(await flutterSimpleContactPlugin.getPlatformVersion(), '42');
  });
}
