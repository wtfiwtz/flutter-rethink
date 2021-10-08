import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:p2pflutter/fabric/data/sync_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'operations.dart';


class Socket {
  static const int uint32WidthBytes = 4;
  static const int uint32MaxValue = 0xFFFFFFFF;

  late WebSocketChannel channel;
  SyncEngine syncEngine;
  HashMap<String,List<Function>> listenerMap;
  HashMap<int,String> requestMap;
  int requestId;


  Socket(String target)
      : listenerMap = HashMap(), requestMap = HashMap(), syncEngine = SyncEngine(), requestId = 1
  {
    channel = WebSocketChannel.connect(Uri.parse(target));
  }

  void request(String path) {
    int currentId = requestId++;
    requestMap[currentId] = path;

    Uint8List request = _buildRequest(currentId, path, Operation.kListen);

    channel.sink.add(request);
  }

  void listen(String path, void Function(Operation event) onData, { Function? onError }) {

    _addToListenerMap(path, onData);

    var cache = syncEngine.buildCache(path);

    channel.stream.listen((msg) {

      Uint8List list = msg;
      // Uint8List list = Uint8List.fromList(utf8.encode(stringMsg));
      ByteData byteData = ByteData.sublistView(list, 0, 8);
      int requestId = byteData.getUint32(0, Endian.little);
      int responseLen = byteData.getUint32(4, Endian.little);
      ByteData byteData2 = ByteData.sublistView(list, 8, 8 + responseLen);
      String asString = getStringFromBytes(byteData2);

      var objs = jsonDecode(asString);
      if (objs is List) {
        (objs as List).forEach((obj) {
          syncEngine.addToCache(cache, obj);
          print("New value: $obj");
        });
      } else {
        syncEngine.addToCache(cache, objs);
        print("New value (1): $objs");
      }

      onData(AddOp(requestId, List.of(cache.values)));

    }, onError: onError);
  }

  static String getStringFromBytes(ByteData data) {
    final buffer = data.buffer;
    Uint8List list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return utf8.decode(list);
  }

  void _addToListenerMap(String path, Function onData) {
    if (listenerMap.containsKey(path)) {
      List<Function>? funcs = listenerMap[path];
      funcs?.add(onData);
    } else {
      listenerMap[path] = List.of([onData]);
    }
  }

  Uint8List _buildRequest(int requestId, String path, int kind) {
    BytesBuilder bytesBuilder = BytesBuilder();
    ByteData uint32Value = ByteData(uint32WidthBytes);

    // Add message kind
    uint32Value.setUint32(0, kind & uint32MaxValue, Endian.little);
    bytesBuilder.add(uint32Value.buffer.asUint8List());

    // Add request Id
    uint32Value.setUint32(0, requestId & uint32MaxValue, Endian.little);
    bytesBuilder.add(uint32Value.buffer.asUint8List());

    // Add path size and path
    uint32Value.setUint32(0, path.length & uint32MaxValue, Endian.little);
    bytesBuilder.add(uint32Value.buffer.asUint8List());
    bytesBuilder.add(utf8.encode(path));

    return bytesBuilder.toBytes();
  }
}