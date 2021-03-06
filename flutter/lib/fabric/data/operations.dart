import 'dart:convert';

abstract class Operation {
  int kind;

  static int kUnknown = 0;
  static int kListen  = 1;
  static int kAdd     = 2;

  Operation(this.kind);
}

class AddOp extends Operation {
  int requestId;
  String data;
  dynamic parsedData;

  AddOp(this.requestId, this.parsedData): data = '', super(Operation.kAdd);

  // dynamic parse() {
  //   parsedData = jsonDecode(data);
  //
  //   // TODO: Fix non-list
  //   // if (parsedData is! List) {
  //   //   parsedData = [parsedData];
  //   // }
  //
  //   return parsedData;
  // }
}