import 'dart:async';
import 'dart:html';

// https://github.com/grpc/grpc-dart/tree/master/example/route_guide
// final grpc = GrpcWebClientChannel.xhr(Uri.http("domain.blah.com", "/"));
// final grpcConnection = grpc.createConnection();
// grpcConnection.dispatchCall(call);

import 'data/operations.dart';
import 'data/socket.dart';

Stream stream(String table) {
  var socket = Socket('ws://localhost:8081/ws');

  // BytesBuilder bytesBuilder = BytesBuilder();
  // Uint8List bytes = bytesBuilder.toBytes();

  socket.request(table);

  StreamController controller = StreamController();

  socket.listen(table, (Operation msg) {
    handleResponse(controller, msg);
  }, onError: (Object err) {
    print("Error occurred! $err");
  });

  return controller.stream;

  // var fabric = Fabric("myApp/database");
  // var collection = await fabric.getCollection("my/collection");
  // var docs = await collection.getDocuments();
  // var doc1Attr = await docs[0].getAttributes();
  //
  // docs[0].stream().listen(
  //   (value) {
  //     print("Stream gave value $value");
  //   }
  // );
  // print("Keys: ${doc1Attr.keys}");
}

handleResponse(StreamController controller, Operation msg) {
  if (msg.kind == Operation.kAdd) {
    var addOp = msg as AddOp;
    var map = addOp.parsedData; // .parse();
    print("Message response is: $map");

    // Add the response to the stream for any listeners
    controller.add(addOp);

  } else {
    print("Unknown message response!");
  }
}


class Document {
  const Document();

  Future<Map<String,Object>> getAttributes() async {
    // return Future.value(new HashMap<String,Object>());
    const Map<String,Object> result = {
      "test": "123",
      "test2": "456"
    };
    return Future.delayed(const Duration(seconds: 1), () => result);
  }

  Stream<int> stream() {
    return Stream.periodic(const Duration(seconds: 120), (count) {
      return count;
    });
  }
}

class Collection {
  const Collection();

  Future<List<Document>> getDocuments() async {
    const result = <Document>[Document(), Document()];
    return Future.delayed(const Duration(seconds: 1), () => result);
  }
}


class Fabric {
  Fabric(String appName);

  Future<Document> getDocument(String path) async {
    const result = Document();
    return Future.delayed(const Duration(seconds: 1), () => result);
  }

  Future<Collection> getCollection(String name) async {
    const result = Collection();
    return Future.delayed(const Duration(seconds: 1), () => result);
  }
}

