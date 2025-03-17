import 'dart:async';
import 'dart:isolate';
import 'package:xleb/config/models/isolate_worker.dart';
import 'package:xleb/config/network_config.dart';
import 'package:xleb/config/node_model.dart';
import 'isolate_message.dart';
import 'isolate_setup.dart';

typedef MessageHandler = void Function(IsolateMessage message);

class IsolateNode {
  final Node config;
  final NetworkConfig networkConfig;
  late final Isolate isolate;
  SendPort? _sendPort;
  final ReceivePort receivePort = ReceivePort();
  final MessageHandler? onMessageReceived;
  final Map<String, Completer<IsolateMessage>> _pendingResponses = {};
  int _messageCounter = 0;

  SendPort get sendPort {
    if (_sendPort == null) {
      throw StateError('SendPort не инициализирован');
    }
    return _sendPort!;
  }

  IsolateNode._(this.config, this.networkConfig, {this.onMessageReceived});

  static Future<IsolateNode> create(
    Node config,
    NetworkConfig networkConfig, {
    MessageHandler? onMessageReceived,
  }) async {
    final node = IsolateNode._(config, networkConfig, onMessageReceived: onMessageReceived);
    await node._initialize();
    return node;
  }

  Future<void> _initialize() async {
    final completer = Completer<void>();

    isolate = await Isolate.spawn(
      isolateWorker,
      IsolateSetup(
        nodeId: config.id,
        receivePort: receivePort.sendPort,
        neighbors: config.neighbors,
        // onMessageReceived: onMessageReceived,
      ),
    );

    /// слушатель для общения вне
    receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        completer.complete();
      } else if (message is List) {
        final IsolateMessage isolateMessage = message[0];
        final String messageId = message[1];
        onMessageReceived!(isolateMessage);
        final responseCompleter = _pendingResponses[messageId];
        if (responseCompleter != null) {
          responseCompleter.complete(isolateMessage);
          _pendingResponses.remove(messageId);
        } else {}
      }
    });

    // Ждем получения SendPort от изолята
    await completer.future;
  }

  Future<void> initializeNeighbors(Map<int, SendPort> neighborPorts) async {
    sendPort.send(neighborPorts);
  }

  Future<void> sendMessage(IsolateMessage message) async {
    final completer = Completer<IsolateMessage>();
    final messageId = '${config.id}-${_messageCounter++}';
    _pendingResponses[messageId] = completer;

    final responsePort = ReceivePort();
    sendPort.send([message, responsePort.sendPort, messageId]);
  }

  Future<void> dispose() async {
    for (final completer in _pendingResponses.values) {
      if (!completer.isCompleted) {
        completer.completeError('Node disposed');
      }
    }
    _pendingResponses.clear();
    receivePort.close();
    isolate.kill();
  }
}
