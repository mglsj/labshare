import 'dart:math';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:labshare/network/client.dart';
import 'package:labshare/network/mdns.dart';
import 'package:labshare/network/server.dart';

enum Mode { teacher, student }

class Host {
  String hostname;
  int port;
  ServiceAttributes attributes;

  Host({required this.hostname, required this.port, required this.attributes});
}

class Session {
  bool found = false;
  late Mode mode;

  String? fileName;
  int? fileSize;
  Map<int, Uint8List> chunks = {};
  Set<int>? pending;

  bool completed = false;

  Map<String, Host> knowHosts = {};

  late Advertiser advertiser;
  late Scanner scanner;
  late TcpServer server;
  late TcpClient client;

  Session.teacher({required this.fileName, required Uint8List file}) {
    mode = Mode.teacher;
    advertiser = Advertiser();
    // scanner = Scanner(this);
    server = TcpServer(this);
    // client = TcpClient(this);
    fileToChunks(file);
  }

  void fileToChunks(Uint8List file) {
    fileSize = file.length;

    for (
      int chunk = 0, bytes = 0;
      bytes < fileSize!;
      bytes += chunkSize, chunk++
    ) {
      var chunkData = file.sublist(bytes, min(bytes + chunk, fileSize!));

      if (chunkData.length != chunkSize) {
        var paddedChunk = Uint8List(chunkSize);
        paddedChunk.setRange(0, chunkData.length, chunkData);
        chunkData = paddedChunk;
      }

      chunks[chunk] = chunkData;
    }
  }

  Session.student() {
    mode = Mode.student;
    advertiser = Advertiser();
    scanner = Scanner(this);
    server = TcpServer(this);
    client = TcpClient(this);
  }

  Future<void> start() async {
    await server.start();

    if (mode == Mode.student) {
      await scanner.init();
      scanner.start();
      while (!completed) {
        if (knowHosts.isNotEmpty) {
          if (!found) {
            var attr = knowHosts.values.first.attributes;
            fileName = attr.name;
            fileSize = attr.size;
            int numChunks = (fileSize! / chunkSize).ceil();
            pending = Set<int>.from(
              List<int>.generate(numChunks, (index) => index),
            );
            found = true;
          }

          for (var host in knowHosts.values) {
            var common = host.attributes.available.intersection(pending!);
            if (common.isNotEmpty &&
                await client.getChunk(host.hostname, host.port, common.first)) {
              pending!.remove(common.first);
              if (pending!.isEmpty) {
                completed = true;
              }
              continue;
            }
          }
        }
        await Future.delayed(Duration(milliseconds: 1));
      }
    } else {
      restartAdvertiser();
    }
  }

  Future<void> stop() async {
    await Future.wait([advertiser.stop(), scanner.stop(), server.stop()]);
  }

  Future<void> restartAdvertiser() async {
    await advertiser.init(
      ServiceAttributes(
        id: id,
        name: fileName!,
        size: fileSize!,
        available: chunks.keys.toSet(),
      ),
    );
    await advertiser.start();
  }

  void onScannerDiscovery(
    BonsoirDiscoveryEvent event,
    BonsoirDiscovery discovery,
  ) async {
    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceFound:
        event.service!.resolve(discovery.serviceResolver);
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        print('Service resolved : ${event.service?.toJson()["service.host"]}');

        try {
          var attributes = ServiceAttributes.fromMap(event.service!.attributes);
          if (attributes.id != id) {
            knowHosts[attributes.id] = Host(
              hostname: event.service!.toJson()["service.host"],
              port: event.service!.port,
              attributes: attributes,
            );
          }
        } catch (e) {
          // ignore
        }

      case BonsoirDiscoveryEventType.discoveryServiceLost:
        print('Service lost : ${event.service?.toJson()}');
        knowHosts.remove(event.service!.attributes["id"] ?? "");
      default:
    }
  }
}
