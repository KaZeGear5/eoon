import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final Function(Map<String, dynamic>) onMessageReceived;

  WebSocketService({required this.onMessageReceived});

  void connect(String serverUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          onMessageReceived(data);
        },
        onError: (error) => print('Erreur WebSocket: $error'),
        onDone: () => print('Connexion WebSocket fermée'),
      );
    } catch (e) {
      print('Impossible de se connecter au WebSocket EooN: $e');
    }
  }

  /// Signale une nouvelle alerte au serveur
  void sendAlert(String alertType, double latitude, double longitude) {
    if (_channel != null) {
      final payload = json.encode({
        'type': 'NEW_ALERT',
        'data': {
          'alertType': alertType,
          'latitude': latitude,
          'longitude': longitude,
        }
      });
      _channel!.sink.add(payload);
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
