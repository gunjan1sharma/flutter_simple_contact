import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_simple_contact_platform_interface.dart';

/// An implementation of [FlutterSimpleContactPlatform] that uses method channels.
class MethodChannelFlutterSimpleContact extends FlutterSimpleContactPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_simple_contact');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
