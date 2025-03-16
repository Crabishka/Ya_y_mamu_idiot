import 'dart:isolate';
import 'isolate_message.dart';
import 'isolate_setup.dart';
import 'message_type.dart';

void isolateWorker(IsolateSetup setup) {
  final receivePort = ReceivePort();
  setup.receivePort.send(receivePort.sendPort);
  
  Map<int, SendPort> neighborPorts = {};

  receivePort.listen((message) async {
    if (message is Map<int, SendPort>) {
      // Инициализация портов соседей
      neighborPorts = message;
    } else if (message is List && message.length == 3 && message[0] is IsolateMessage) {
      final IsolateMessage isolateMessage = message[0];
      final SendPort replyTo = message[1];
      final String messageId = message[2];

      if (isolateMessage.toId != setup.nodeId) {
        print('Узел ${setup.nodeId}: Получено сообщение для другого узла (${isolateMessage.toId})');
        return;
      }

      switch (isolateMessage.type) {
        case MessageType.hello:
          print('Узел ${setup.nodeId} получил приветственное сообщение от ${isolateMessage.fromId}: ${isolateMessage.content}');
          
          // Отправляем подтверждение отправителю
          replyTo.send([
            isolateMessage.copyWith(
              delivered: true,
              deliveredAt: DateTime.now(),
              content: 'Узел ${setup.nodeId} получил приветствие',
              type: MessageType.response,
            ),
            messageId
          ]);

          // Отправляем сообщения всем соседям
          for (final neighborId in setup.neighbors.keys) {
            if (neighborPorts.containsKey(neighborId)) {
              final delay = setup.neighbors[neighborId]!;
              print('Узел ${setup.nodeId} отправляет приветствие узлу $neighborId (задержка: ${delay.inMilliseconds}ms)');
              Future.delayed(delay).then((value) {
                final newMessageId = '$messageId-$neighborId';
                neighborPorts[neighborId]!.send([
                  IsolateMessage(
                    fromId: setup.nodeId,
                    toId: neighborId,
                    content: 'Привет от узла ${setup.nodeId}',
                    sentAt: DateTime.now(),
                    type: MessageType.regular,
                  ),
                  replyTo,
                  newMessageId
                ]);
              },);
              

            }
          }
          break;

        case MessageType.regular:
          print('Узел ${setup.nodeId} получил обычное сообщение от ${isolateMessage.fromId}: ${isolateMessage.content}');
          
          replyTo.send([
            isolateMessage.copyWith(
              delivered: true,
              deliveredAt: DateTime.now(),
              content: 'Узел ${setup.nodeId} получил сообщение',
              type: MessageType.response,
            ),
            messageId
          ]);
          break;

        case MessageType.response:
          print('Узел ${setup.nodeId} получил ответ от ${isolateMessage.fromId}: ${isolateMessage.content}');
          replyTo.send([isolateMessage, messageId]);
          break;
      }
    }
  });
} 