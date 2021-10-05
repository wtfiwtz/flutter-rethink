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
          if (snapshot.data is! AddOp) {
            return const Text('(unknown message type)');
          }
          var addOp = snapshot.data as AddOp;
          List list = addOp.parsedData;

          return _listView(list);
        });
  }

  Widget _listView(List list) {
    return ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        itemBuilder: (BuildContext context, int index) {
          return Row(
              children: [
                  SizedBox(
                      height: 50,
                      width: 300,
                      child: Text(list[index]['name'])
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _children(list[index]['posts'])
                  )
              ]
          );
        }
    );
  }

  List<Widget> _children(List list) {
    print("Item: ${list[0]}");
    return list.map((e) => _subItem(e)).toList();
  }

  Widget _subItem(e) => SizedBox(
      height: 50,
      child: Align(
          alignment: Alignment.topLeft,
          child: Text("${e['title']} - ${e['content']}", textAlign: TextAlign.left)
      )
  );

  Widget _debug(Widget child, {Color color = Colors.red}) {
    return Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        child: Align(
            alignment: Alignment.topLeft,
            child: child)
    );
  }
}


