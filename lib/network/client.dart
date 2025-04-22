import 'dart:io';
import 'dart:typed_data';

import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

class TcpClient {
  Session session;

  TcpClient(this.session);
  bool status = false;

  Future<bool> getChunk(String host, int port, int chunk) async {
    status = false;

    try {
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
        (data) => onData(data, chunk),
        onDone: () {
          print('Client: Connection closed');
          socket.destroy();
        },
        onError: (error) {
          print('Client: $error');
          socket.destroy();
        },
      );
    } catch (e) {
      print('Error: $e');
    }
    return status;
  }

  void onData(Uint8List data, int chunk) {
    if (data.length == 1) {
      print('Client: server response ${ResponseCode.values[data[0]]}');
      return;
    }
    if (data[0] == ResponseCode.ok.index) {
      if (data.length == chunkSize + 1) {
        print("Client: Chunk $chunk OK");
        session.chunks[chunk] = data.sublist(1);
        status = true;
        session.restartAdvertiser();
        return;
      }
      print("Client: Invalid chunk");
      return;
    }
    print("Client: Invalid response code");
  }
}
