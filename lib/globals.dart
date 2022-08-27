library globals;

bool _vOperationContinue = false;

void checkOperation() {
  if (!_vOperationContinue) {
    throw "Operation stopped!";
  }
}

set operationContinue(bool value) {
  _vOperationContinue = value;
}
