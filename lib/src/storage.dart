import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqlutter/src/exceptions.dart';

abstract class Storage<T> {
  abstract final String storageName;
  abstract String name;

  Storage(
    T value, {
    bool notifyChanges = false,
    this.nullable = true,
  }) : _notifyChanges = notifyChanges {
    if (!nullable && value == null) {
      throw InvalidNullSetException(
        'Instance of $name is set to be non-nullable, but null was provided',
      );
    }

    _value = value;
    if (_notifyChanges) initNotifier();
  }

  late T _value;
  final bool _notifyChanges;
  ValueNotifier<T>? _valueNotifier;

  T get value {
    return _value;
  }

  set value(T v) {
    if (_value == v) return;
    if (!nullable && v == null) {
      throw InvalidNullSetException(
        'Instance of $name is set to be non-nullable, but null was provided',
      );
    }

    _value = v;
    if (_notifyChanges) _valueNotifier?.value = v;
  }

  /// If false, prevents value from ever being null.
  final bool nullable;

  dynamic get sqlValue => _value;

  set sqlValue(dynamic v) => value = v;

  void initNotifier() {
    _valueNotifier?.dispose();
    _valueNotifier = ValueNotifier(_value);
    disposed = false;
  }

  bool get hasListeners => _valueNotifier?.hasListeners ?? false;

  void addListener(void Function() listener) {
    if (!_notifyChanges) {
      throw StorageNotNotifiableException(
        'Instance of $name Storage Unit has notifyChanges set to false on construction',
      );
    }

    if (disposed) {
      throw StorageDisposedException(
        'Instance of $name has been disposed. call initNotifier to resume notification',
      );
    }
    _valueNotifier?.addListener(listener);
  }

  void removeListener(void Function() listener) {
    if (!_notifyChanges) {
      throw StorageNotNotifiableException(
        'Instance of $name Storage Unit has notifyChanges set to false on construction',
      );
    }

    if (disposed) {
      throw StorageDisposedException(
        'Instance of $name has been disposed. call initNotifier to resume notification',
      );
    }
    _valueNotifier?.removeListener(listener);
  }

  bool disposed = false;
  void dispose() {
    _valueNotifier?.dispose();
    disposed = true;
  }
}

class IntStorage<T extends int?> extends Storage<T> {
  @override
  final String storageName = 'INTEGER';

  IntStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;
}

class RealStorage<T extends num?> extends Storage<T> {
  @override
  final String storageName = 'REAL';

  RealStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;
}

class TextStorage<T extends String?> extends Storage<T> {
  @override
  final String storageName = 'TEXT';

  TextStorage(
    super.value, {
    required this.name,
    super.nullable,
    this.charLimit,
  });

  @override
  String name;

  int? charLimit;

  @override
  set value(T v) {
    int vLength = v?.length ?? 0;
    if (charLimit != null && vLength > charLimit!) {
      throw TextCharLimitException(
        'Value $v of length $vLength exceeded $name char limit of $charLimit',
      );
    }

    super.value = v;
  }
}

class BlobStorage<T extends Uint8List?> extends Storage<T> {
  @override
  final String storageName = 'BLOB';

  BlobStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;
}

class DateTimeStorage<T extends DateTime?> extends Storage<T> {
  @override
  final String storageName = 'TEXT';

  DateTimeStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;

  @override
  dynamic get sqlValue => _value?.toString();

  @override
  set sqlValue(dynamic v) {
    if (v == null) {
      value = v;
    } else if (v is DateTime) {
      value = v as T;
    } else if (v is String) {
      value = DateTime.parse(v) as T;
    } else {
      throw UnimplementedError('Unexpected type: ${v.runtimeType}');
    }
  }
}

class TimeOfDayStorage<T extends TimeOfDay?> extends Storage<T> {
  @override
  final String storageName = 'TEXT';

  TimeOfDayStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;

  @override
  dynamic get sqlValue {
    if (value == null) return null;
    DateTime dateTime = DateTime(
      1999, // Represent
      1,
      1,
      _value!.hour,
      _value!.minute,
    );

    return dateTime.toString();
  }

  @override
  set sqlValue(dynamic v) {
    if (v == null) {
      value = v;
    } else if (v is TimeOfDay) {
      value = v as T;
    } else if (v is String) {
      DateTime dateTime = DateTime.parse(v);
      value = TimeOfDay.fromDateTime(dateTime) as T;
    } else {
      throw UnimplementedError('Unexpected type: ${v.runtimeType}');
    }
  }
}

class BooleanStorage<T extends bool?> extends Storage<T> {
  @override
  final String storageName = 'INTEGER';

  BooleanStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;

  @override
  dynamic get sqlValue {
    if (_value == true) {
      return 1;
    } else if (_value == false) {
      return 0;
    } else {
      return _value;
    }
  }

  @override
  set sqlValue(dynamic v) {
    if (v != null) {
      value = (v == 1) as T;
    } else {
      value = v;
    }
  }
}

class JSONStorage<T extends Object?> extends Storage<T> {
  @override
  final String storageName = 'TEXT';

  JSONStorage(
    super.value, {
    required this.name,
    super.nullable,
  });

  @override
  String name;

  @override
  dynamic get sqlValue {
    return const JsonEncoder().convert(value);
  }

  @override
  set sqlValue(dynamic v) {
    if (v == null) {
      value = v;
    } else if (v is String) {
      value = const JsonDecoder().convert(v);
    } else {
      throw UnimplementedError('Unexpected type: ${v.runtimeType}');
    }
  }
}
