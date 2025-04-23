import 'dart:io';
import 'dart:typed_data';

import 'package:labshare/network/session.dart';
import 'package:labshare/protocol.dart';

// packet

class TcpServer {
  late ServerSocket server;
  bool isRunning = false;
  Session session;

  TcpServer(this.session);

  Future<void> start() async {
    if (isRunning) return;
    server = await ServerSocket.bind("0.0.0.0", port);
    print('Server: listening on ${server.address}:${server.port}');
    server.listen((socket) => handleConnection(socket));
  }

  Future<void> close() async {
    await server.close();
  }

  Future<void> flush() async {
    try {
      await close();
    } catch (e) {
      //
    }
  }

  void handleConnection(Socket socket) {
    print(
      'Server: Connection from'
      ' ${socket.remoteAddress.address}:${socket.remotePort}',
    );

    socket.listen(
      (Uint8List data) async {
        print("Server: data from client $data");
        if (data.length != 5) {
          print("Server: invalid packet length");
          socket.add([ResponseCode.invalid.index]);
          await socket.flush();
          socket.destroy();
          return;
        }

        if (data[0] != requestGetCode) {
          print("Server: invalid get code");
          socket.add([ResponseCode.invalid.index]);
          await socket.flush();
          socket.destroy();
          return;
        }

        // convert data 1-4 to 32 bit integer representation
        // data[1..4] is 4 bytes, so convert to int
        int requestedChunk = ByteData.sublistView(
          data,
          1,
          5,
        ).getUint32(0, Endian.big);

        print("Server: Chunk $requestedChunk requested");

        if (session.chunks.containsKey(requestedChunk)) {
          print("Server: sending chunk $requestedChunk");
          socket.add([
            ResponseCode.ok.index,
            ...(session.chunks[requestedChunk]!),
          ]);
          await socket.flush();
          socket.destroy();
          return;
        }

        print("Server: chunk not found $requestedChunk");
        socket.add([ResponseCode.notFound.index]);
        await socket.flush();
        socket.destroy();
      },

      // handle errors
      onError: (error) {
        print('Server: $error');
        socket.destroy();
      },

      onDone: () {
        print('Server: client left');
        socket.destroy();
      },
    );
  }
}

// void runServer() async {
//   var server = await ServerSocket.bind("0.0.0.0", 4040);
//   print('Echo server listening on ${server.address}:${server.port}');

//   server.listen((socket) => handleConnection(socket));
// }
