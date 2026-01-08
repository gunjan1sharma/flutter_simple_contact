import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_simple_contact_method_channel.dart';

abstract class FlutterSimpleContactPlatform extends PlatformInterface {
  /// Constructs a FlutterSimpleContactPlatform.
  FlutterSimpleContactPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSimpleContactPlatform _instance =
      MethodChannelFlutterSimpleContact();

  /// The default instance of [FlutterSimpleContactPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSimpleContact].
  static FlutterSimpleContactPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSimpleContactPlatform] when
  /// they register themselves.
  static set instance(FlutterSimpleContactPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
