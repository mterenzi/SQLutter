class DBEmptyResultException implements Exception {
  String cause;
  DBEmptyResultException(this.cause);

  @override
  String toString() {
    if (cause.isEmpty) {
      return super.toString();
    } else {
      return "DBEmptyResultException: $cause";
    }
  }
}

class InvalidNullSetException implements Exception {
  String cause;
  InvalidNullSetException(this.cause);

  @override
  String toString() {
    if (cause.isEmpty) {
      return super.toString();
    } else {
      return "InvalidNullSetException: $cause";
    }
  }
}

class StorageNotNotifiableException implements Exception {
  String cause;
  StorageNotNotifiableException(this.cause);

  @override
  String toString() {
    if (cause.isEmpty) {
      return super.toString();
    } else {
      return "StorageNotNotifiableException: $cause";
    }
  }
}


class StorageDisposedException implements Exception {
  String cause;
  StorageDisposedException(this.cause);

  @override
  String toString() {
    if (cause.isEmpty) {
      return super.toString();
    } else {
      return "StorageDisposedException: $cause";
    }
  }
}
class TextCharLimitException implements Exception {
  String cause;
  TextCharLimitException(this.cause);

  @override
  String toString() {
    if (cause.isEmpty) {
      return super.toString();
    } else {
      return "TextCharLimitException: $cause";
    }
  }
}
