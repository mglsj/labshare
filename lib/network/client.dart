import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

class TcpClient {
  Session session;
  late bool status;

  TcpClient(this.session);

  Future<bool> getChunk(String host, int port, int chunk) async {
    final completer = Completer<bool>();
    status = false;

    try {
      print("Client: trying connection");
      var socket = await Socket.connect(host, port);
      print("Client: Server connected");

      var data =
          Uint8List(5)
            ..buffer.asByteData().setUint8(0, requestGetCode)
            ..buffer.asByteData().setUint32(1, chunk, Endian.big);

      print("Client: sent request to server ${data}");
      socket.add(data);
      await socket.flush();

      final List<int> buffer = [];

      socket.listen(
        (bytes) {
          // handle incoming bytes
          buffer.addAll(bytes);
          const expectedLen = chunkSize + 1;
          if (buffer.length >= expectedLen) {
            final code = buffer[0];
            if (code == ResponseCode.ok.index) {
              // extract chunk payload
              final payload = buffer.sublist(1, expectedLen);
              session.chunks[chunk] = Uint8List.fromList(payload);
              status = true;
            } else {
              print('Client: server response ${ResponseCode.values[code]}');
            }
            // once we've got what we need, complete()
            if (!completer.isCompleted) {
              completer.complete(status);
              socket.destroy();
            }
          }
        },
        onDone: () {
          print('Client: Connection closed');
          if (!completer.isCompleted) {
            if (buffer.isNotEmpty) {
              final code = buffer[0];
              status = code == ResponseCode.ok.index;
            }
            completer.complete(status);
            socket.destroy();
          }
        },
        onError: (error) {
          print('Client: $error');
          if (!completer.isCompleted) completer.complete(false);
          socket.destroy();
        },
      );
    } catch (e) {
      print('Error: $e');
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }
}
