enum SimpleContactMode { unified, raw }

enum SimpleContactFormat { listOfMaps, jsonString }

enum SimpleSort { none, alphabetical, lastUpdatedDesc }

class SimpleContact {
  final String id; // unified contact id on Android; CNContact.identifier on iOS
  final String? rawContactId; // Android raw contact id if available
  final String displayName;
  final List<SimplePhone> phones;

  // Optional metadata (filled later in Android/iOS batches)
  final int? lastModifiedMillis; // best-effort
  final bool? starred;
  final bool? hasPhoto;

  const SimpleContact({
    required this.id,
    required this.displayName,
    required this.phones,
    this.rawContactId,
    this.lastModifiedMillis,
    this.starred,
    this.hasPhoto,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "rawContactId": rawContactId,
    "displayName": displayName,
    "phones": phones.map((p) => p.toMap()).toList(),
    "lastModifiedMillis": lastModifiedMillis,
    "starred": starred,
    "hasPhoto": hasPhoto,
  };
}

class SimplePhone {
  final String number;
  final String? label;
  final String? normalizedNumber;

  const SimplePhone({required this.number, this.label, this.normalizedNumber});

  Map<String, dynamic> toMap() => {
    "number": number,
    "label": label,
    "normalizedNumber": normalizedNumber,
  };
}

class SimpleFetchFilters {
  final bool onlyWithPhone;
  final bool onlyStarred;
  final bool onlyWithPhoto;

  const SimpleFetchFilters({
    this.onlyWithPhone = false,
    this.onlyStarred = false,
    this.onlyWithPhoto = false,
  });

  Map<String, dynamic> toMap() => {
    "onlyWithPhone": onlyWithPhone,
    "onlyStarred": onlyStarred,
    "onlyWithPhoto": onlyWithPhoto,
  };
}

class SimpleFetchOptions {
  final bool handlePermission;
  final SimpleContactMode mode;
  final SimpleSort sort;
  final SimpleFetchFilters filters;

  /// For enterprise: if true, plugin will return only minimal subset
  /// (e.g., name + phones) and omit extra metadata where possible.
  final bool minimizeData;

  const SimpleFetchOptions({
    this.handlePermission = true,
    this.mode = SimpleContactMode.unified,
    this.sort = SimpleSort.none,
    this.filters = const SimpleFetchFilters(),
    this.minimizeData = false,
  });

  Map<String, dynamic> toMap() => {
    "handlePermission": handlePermission,
    "mode": mode.name,
    "sort": sort.name,
    "filters": filters.toMap(),
    "minimizeData": minimizeData,
  };
}

class SimpleFetchResult {
  final bool ok;
  final String status; // success | permission_denied | cancelled | error
  final String? errorCode;
  final String? errorMessage;
  final List<SimpleContact> contacts;

  const SimpleFetchResult({
    required this.ok,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.contacts = const [],
  });

  Map<String, dynamic> toMap() => {
    "ok": ok,
    "status": status,
    "errorCode": errorCode,
    "errorMessage": errorMessage,
    "contacts": contacts.map((c) => c.toMap()).toList(),
  };
}
