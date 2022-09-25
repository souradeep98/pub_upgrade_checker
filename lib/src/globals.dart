library globals;

//import 'package:flutter/widgets.dart';

bool _vOperationContinue = false;

void checkOperation() {
  if (!_vOperationContinue) {
    throw "Operation stopped!";
  }
}

set operationContinue(bool value) {
  _vOperationContinue = value;
}

/*TextDirection? _textDirection;

void setAppTextDirection(TextDirection? value) {
  _textDirection = value;
}

TextDirection getAppTextDirection(BuildContext context) {
  return _textDirection ??= Directionality.of(context);
}*/
