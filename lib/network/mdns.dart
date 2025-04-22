import 'package:bonsoir/bonsoir.dart';
import 'package:labshare/network/session.dart';

const serviceType = "_labshare._tcp";
const serviceName = "LabShare";

class ServiceAttributes {
  late String id;
  late String host;
  late int port;
  late String name;
  late int size;
  late Set<int> available;

  ServiceAttributes({
    required this.id, // device id
    required this.host,
    required this.port,
    required this.name, // file name
    required this.size, // file size in bytes
    required this.available, // list of available chunks
  });

  ServiceAttributes.fromMap(Map<String, String> map) {
    id = map["id"] ?? "";
    host = map["host"] ?? "";
    port = int.tryParse(map["port"] ?? "0") ?? 0;
    name = map["name"] ?? "";
    size = int.tryParse(map["size"] ?? "0") ?? 0;
    available =
        (map["available"] ?? "")
            .split(',')
            .where((e) => e.isNotEmpty)
            .map((e) => int.tryParse(e) ?? 0)
            .toSet();
  }

  Map<String, String> toMap() {
    return {
      "id": id,
      "host": host,
      "port": port.toString(),
      "name": name,
      "size": size.toString(),
      "available": available.join(','),
    };
  }
}

class Advertiser {
  BonsoirBroadcast? broadcast;
  bool isRunning = false;

  Future<void> init(ServiceAttributes attributes) async {
    if (isRunning) stop();

    BonsoirService service = BonsoirService(
      name: serviceName,
      type: serviceType,
      port: 3030,
      attributes: attributes.toMap(),
    );

    broadcast = BonsoirBroadcast(service: service);
    await broadcast!.ready;
  }

  Future<void> start() async {
    if (broadcast == null) throw Exception("Not initialized");
    if (isRunning) return;
    await broadcast!.start();
    isRunning = true;
  }

  Future<void> stop() async {
    if (broadcast == null) throw Exception("Not initialized");
    if (!isRunning) return;
    await broadcast!.stop();
    isRunning = false;
  }
}

class Scanner {
  BonsoirDiscovery? discovery;
  bool isRunning = false;

  Session session;

  Scanner(this.session);

  Future<void> init() async {
    discovery = BonsoirDiscovery(type: serviceType);
    await discovery!.ready;
    discovery!.eventStream!.listen(
      (event) => session.onScannerDiscovery(event, discovery!),
    );
  }

  Future<void> start() async {
    if (discovery == null) throw Exception("Not initialized");
    if (isRunning) return;
    await discovery!.start();
    isRunning = true;
  }

  Future<void> stop() async {
    if (discovery == null) throw Exception("Not initialized");
    if (!isRunning) return;
    await discovery!.start();
    isRunning = false;
  }
}
