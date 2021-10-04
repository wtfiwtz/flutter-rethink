import 'package:flutter/material.dart';

import 'fabric/data/operations.dart';
import 'fabric/fabric.dart' as fabric;

class TestWidget extends StatelessWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: fabric.stream("authors"),
        builder: (context, AsyncSnapshot snapshot) {
          print(snapshot.data);
          if (snapshot.data is AddOp) {
            var addOp = snapshot.data as AddOp;
            List list = addOp.parsedData;
            print("addOp $list");
            return Text(list.toString());
          }
          // print(snapshot);
          return const Text('(unknown message type)');
        });

    // return const Text('Test Widget goes here');
  }
}


