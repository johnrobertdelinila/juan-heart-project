import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Mock implementation of Connectivity for testing purposes.
///
/// Provides controllable connectivity state for unit and integration tests.
/// Eliminates MissingPluginException errors in test environments.
class MockConnectivity implements Connectivity {
  final _controller = StreamController<ConnectivityResult>.broadcast();
  ConnectivityResult _currentResult = ConnectivityResult.wifi;

  @override
  Future<ConnectivityResult> checkConnectivity() async => _currentResult;

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  /// Set specific connectivity result
  void setConnectivity(ConnectivityResult result) {
    _currentResult = result;
    _controller.add(_currentResult);
  }

  /// Helper: Simulate offline state
  void goOffline() => setConnectivity(ConnectivityResult.none);

  /// Helper: Simulate WiFi connection
  void goOnline() => setConnectivity(ConnectivityResult.wifi);

  /// Helper: Simulate mobile data connection
  void goMobile() => setConnectivity(ConnectivityResult.mobile);

  /// Helper: Simulate ethernet connection
  void goEthernet() => setConnectivity(ConnectivityResult.ethernet);

  /// Cleanup resources
  void dispose() {
    _controller.close();
  }
}
