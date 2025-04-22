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

      socket.listen(
        (bytes) {
          // handle incoming bytes
          if (bytes.length == 1) {
            print('Client: server response ${ResponseCode.values[bytes[0]]}');
          } else if (bytes[0] == ResponseCode.ok.index &&
              bytes.length == chunkSize + 1) {
            print("Client: Chunk $chunk OK");
            session.chunks[chunk] = bytes.sublist(1);
            status = true;
          } else {
            print("Client: Invalid response or chunk");
          }

          // once we've got what we need, complete()
          if (!completer.isCompleted) {
            completer.complete(status);
            socket.destroy();
          }
        },
        onDone: () {
          print('Client: Connection closed');
          if (!completer.isCompleted) completer.complete(status);
          socket.destroy();
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

  //   void onData(Uint8List data, int chunk, Socket socket) {
  //     if (data.length == 1) {
  //       print('Client: server response ${ResponseCode.values[data[0]]}');
  //       return;
  //     }
  //     if (data[0] == ResponseCode.ok.index) {
  //       if (data.length == chunkSize + 1) {
  //         print("Client: Chunk $chunk OK");
  //         session.chunks[chunk] = data.sublist(1);
  //         status = true;
  //         return;
  //       }
  //       print("Client: Invalid chunk");
  //       return;
  //     }
  //     print("Client: Invalid response code");
  //   }
}
