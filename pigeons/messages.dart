import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/pigeon/messages.g.dart',
    swiftOut: 'macos/Runner/Messages.g.swift',
  ),
)
@HostApi()
abstract class PingApi {
  String ping(String message);
}
