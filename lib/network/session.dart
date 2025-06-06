import 'dart:math';
import 'dart:typed_data';

import 'package:bonsoir/bonsoir.dart';
import 'package:labshare/network/client.dart';
import 'package:labshare/network/mdns.dart';
import 'package:labshare/network/server.dart';
import 'package:labshare/protocol.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum Mode { teacher, student }

class Host {
  ServiceAttributes attributes;

  Host({required this.attributes});
}

class Session {
  bool found = false;
  late Mode mode;

  late String id;
  final info = NetworkInfo();

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
    print("size: $fileSize");

    for (
      int chunk = 0, bytes = 0;
      bytes < fileSize!;
      bytes += chunkSize, chunk++
    ) {
      int end = min(bytes + chunkSize, fileSize!);
      var chunkData = file.sublist(bytes, end);

      if (chunkData.length != chunkSize) {
        var paddedChunk = Uint8List(chunkSize);
        paddedChunk.setRange(0, chunkData.length, chunkData);
        chunkData = paddedChunk;
      }

      chunks[chunk] = chunkData;
    }

    // print(chunks);
  }

  Uint8List chunkToFile() {
    // print(chunks);

    var file = Uint8List(fileSize!);

    int numChunks = (fileSize! / chunkSize).ceil();
    for (int chunk = 0; chunk < numChunks; chunk++) {
      var chunkData = chunks[chunk]!;
      int start = chunk * chunkSize;
      int end = (chunk == numChunks - 1) ? fileSize! : start + chunkSize;
      file.setRange(start, end, chunkData.sublist(0, end - start));
    }

    return file;
  }

  Session.student() {
    mode = Mode.student;
    advertiser = Advertiser();
    scanner = Scanner(this);
    server = TcpServer(this);
    client = TcpClient(this);
  }

  Future<void> start() async {
    await server.flush();
    await server.start();

    id = uuid.v4();

    if (mode == Mode.student) {
      await scanner.flush();
      await scanner.init();
      await scanner.start();

      while (!completed) {
        try {
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
              if (common.isNotEmpty) {
                var chunk = common.first;

                var req = await client.getChunk(
                  host.attributes.host,
                  host.attributes.port,
                  chunk,
                );

                if (!req) continue;

                pending!.remove(chunk);
                print("Pending chunks: $pending");

                if (pending!.isEmpty) {
                  completed = true;
                }
                restartAdvertiser();
                continue;
              }
            }
          }
          await Future.delayed(Duration(milliseconds: 1));
        } catch (e) {
          print(e);
        }
      }
      scanner.stop();
      return;
    } else {
      while (true) {
        restartAdvertiser();
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  Future<void> stop() async {
    try {
      await Future.wait([server.flush(), advertiser.flush(), scanner.flush()]);
    } catch (e) {
      print(e);
    }
  }

  Future<void> restartAdvertiser() async {
    await advertiser.flush();
    await advertiser.init(
      ServiceAttributes(
        id: id,
        host: await info.getWifiIP() ?? "",
        port: port,
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
        try {
          var attributes = ServiceAttributes.fromMap(event.service!.attributes);

          if (attributes.host != await info.getWifiIP()) {
            knowHosts[attributes.id] = Host(attributes: attributes);
            print("Host added to known list ${attributes.id}");
          }
        } catch (e) {
          // ignore
        }

      case BonsoirDiscoveryEventType.discoveryServiceLost:
        knowHosts.remove(event.service!.attributes["id"] ?? "");
        print(
          "Host removed from known list ${event.service!.attributes["id"]}",
        );
      default:
    }
  }
}
