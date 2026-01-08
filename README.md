# Flutter Simple Contact

A lightweight (~2KB), transparent Flutter plugin for fetching contacts from Android and iOS with zero third-party dependencies. Built specifically for fintech and enterprise applications that require full control over contact data handling.

[![pub package](https://img.shields.io/pub/v/flutter_simple_contact.svg)](https://pub.dev/packages/flutter_simple_contact)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Why Flutter Simple Contact?

- ** Zero Third-Party Dependencies**: Direct native implementation using Android ContactsContract and iOS Contacts framework
- ** Lightweight**: Only ~5KB - no bloated dependencies
- ** Enterprise-Ready**: Built for fintech/banking apps requiring audit trails
- ** Transparent**: Clean, readable source code - audit every line
- ** Flexible**: Minimal mode (name + phone) or full metadata (emails, addresses, organizations)
- ** Privacy-First**: Built-in permission handling with configurable UI flows
- ** Production-Tested**: Works on Android (API 21+) and iOS (13.0+)

---

## Features

✅ Fetch unified or raw contacts  
✅ Built-in permission handling (optional)  
✅ Filter by phone/photo availability  
✅ Sort alphabetically or by last updated  
✅ Minimize data mode (name + phones only)  
✅ Rich metadata mode (emails, addresses, websites, organizations)  
✅ Progress events via EventChannel (optional)  
✅ Typed API or raw maps for flexibility  
✅ iOS notes support (with entitlement flag)

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_simple_contact: ^0.0.1
```

Run:

```bash
flutter pub get
```

---

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.READ_CONTACTS"/>
</manifest>
```

**Minimum SDK**: API 21 (Android 5.0)

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSContactsUsageDescription</key>
<string>We need access to your contacts to help you share referral links with friends and family.</string>
```

**Minimum Version**: iOS 13.0

---

## Usage

### 1. Minimal Mode (Name + Phone Only)

Perfect for referral systems, contact pickers, or minimal data collection:

```dart
import 'package:flutter_simple_contact/flutter_simple_contact.dart';

Future<void> fetchBasicContacts() async {
  final raw = await FlutterSimpleContact.fetchContactsRaw(
    options: {
      "handlePermission": true,
      "mode": "unified",
      "sort": "alphabetical",
      "filters": {
        "onlyWithPhone": true,  // Skip contacts without phone numbers
        "onlyStarred": false,
        "onlyWithPhoto": false,
      },
      "minimizeData": true,  // Only name + phones (fast & minimal)
      "advanced": {
        "enableProgressEvents": false,
        "includeNotes": false,
      },
    },
  );

  final contacts = (raw["contacts"] as List? ?? []).map((c) {
    return {
      "name": c["displayName"] ?? "Unknown",
      "phones": c["phones"] ?? [],
    };
  }).toList();

  print("Fetched ${contacts.length} contacts");
}
```

**Output:**

```json
[
  {
    "name": "John Doe",
    "phones": [{ "number": "+1234567890", "label": "Mobile" }]
  }
]
```

---

### 2. Full Metadata Mode

Get comprehensive contact data (emails, addresses, websites, organizations):

```dart
Future<void> fetchDetailedContacts() async {
  final raw = await FlutterSimpleContact.fetchContactsRaw(
    options: {
      "handlePermission": true,
      "mode": "unified",
      "sort": "alphabetical",
      "filters": {
        "onlyWithPhone": false,
        "onlyStarred": false,
        "onlyWithPhoto": false,
      },
      "minimizeData": false,  // Fetch all metadata
      "advanced": {
        "enableProgressEvents": false,
        "includeNotes": false,  // Requires iOS entitlement
      },
    },
  );

  final contacts = raw["contacts"] as List? ?? [];

  for (var contact in contacts) {
    print("Name: ${contact['displayName']}");
    print("Phones: ${contact['phones']}");
    print("Emails: ${contact['emails']}");
    print("Addresses: ${contact['addresses']}");
    print("Websites: ${contact['websites']}");
    print("Organizations: ${contact['organizations']}");
  }
}
```

**Output:**

```json
{
  "id": "ABC123",
  "displayName": "Jane Smith",
  "phones": [
    { "number": "+9876543210", "label": "Work", "normalizedNumber": null }
  ],
  "emails": [{ "address": "jane@example.com", "label": "Work" }],
  "addresses": [
    {
      "street": "123 Main St",
      "city": "San Francisco",
      "state": "CA",
      "postalCode": "94105",
      "country": "USA",
      "isoCountryCode": "US",
      "label": "Home"
    }
  ],
  "websites": [{ "url": "https://example.com", "label": "Homepage" }],
  "organizations": [
    {
      "company": "Acme Corp",
      "department": "Engineering",
      "jobTitle": "Engineer"
    }
  ],
  "hasPhoto": true,
  "starred": false,
  "lastModifiedMillis": 1704672000000
}
```

---

### 3. Typed API (Strongly Typed)

For apps preferring type safety:

```dart
import 'package:flutter_simple_contact/flutter_simple_contact.dart';

Future<void> fetchTypedContacts() async {
  final result = await FlutterSimpleContact.fetchContacts(
    options: SimpleFetchOptions(
      handlePermission: true,
      mode: SimpleContactMode.unified,
      sort: SimpleSort.alphabetical,
      filters: const SimpleFetchFilters(onlyWithPhone: true),
      minimizeData: false,
      advanced: const SimpleAdvancedOptions(
        enableProgressEvents: false,
        includeNotes: false,
      ),
    ),
  );

  if (result.ok) {
    for (var contact in result.contacts) {
      print("${contact.displayName}: ${contact.phones.length} phones");
    }
  } else {
    print("Error: ${result.errorMessage}");
  }
}
```

---

## Configuration Options

### Main Options

| Option             | Type     | Default     | Description                                     |
| ------------------ | -------- | ----------- | ----------------------------------------------- |
| `handlePermission` | `bool`   | `true`      | Automatically request contacts permission       |
| `mode`             | `String` | `"unified"` | `"unified"` or `"raw"` (Android only)           |
| `sort`             | `String` | `"none"`    | `"none"`, `"alphabetical"`, `"lastUpdatedDesc"` |
| `minimizeData`     | `bool`   | `false`     | If `true`, only fetch name + phones (faster)    |

### Filters

| Filter          | Type   | Default | Description                                   |
| --------------- | ------ | ------- | --------------------------------------------- |
| `onlyWithPhone` | `bool` | `false` | Skip contacts without phone numbers           |
| `onlyStarred`   | `bool` | `false` | Only starred/favorite contacts (Android only) |
| `onlyWithPhoto` | `bool` | `false` | Only contacts with photos                     |

### Advanced Options

| Option                 | Type   | Default | Description                                                                          |
| ---------------------- | ------ | ------- | ------------------------------------------------------------------------------------ |
| `enableProgressEvents` | `bool` | `false` | Enable progress EventChannel (for large contact lists)                               |
| `includeNotes`         | `bool` | `false` | Fetch contact notes (iOS: requires `com.apple.developer.contacts.notes` entitlement) |

---

## Returned Fields

### Always Available (minimizeData: true or false)

- `id` - Contact identifier (String)
- `displayName` - Full name (String)
- `phones` - Array of `{number, label, normalizedNumber}`
- `hasPhoto` - Boolean
- `starred` - Boolean (Android only, `null` on iOS)
- `lastModifiedMillis` - Timestamp (Android only, `null` on iOS)

### Additional Fields (minimizeData: false)

- `emails` - Array of `{address, label}`
- `addresses` - Array of `{street, city, state, postalCode, country, isoCountryCode, label}`
- `websites` - Array of `{url, label}`
- `organizations` - Array of `{company, department, jobTitle}` (iOS) or `{company, title, department}` (Android)
- `note` - String (iOS only, requires `includeNotes: true` and entitlement)

---

## Permission Handling

### Automatic (Recommended)

```dart
final raw = await FlutterSimpleContact.fetchContactsRaw(
  options: {"handlePermission": true, /* ... */},
);

// Plugin automatically requests permission if needed
```

### Manual

```dart
// 1. Request permission yourself using permission_handler or similar
// 2. Then fetch with handlePermission: false

final raw = await FlutterSimpleContact.fetchContactsRaw(
  options: {"handlePermission": false, /* ... */},
);
```

---

## Error Handling

```dart
final raw = await FlutterSimpleContact.fetchContactsRaw(
  options: {/* ... */},
);

if (raw["ok"] == false) {
  final status = raw["status"]; // "permission_denied", "error", etc.
  final errorCode = raw["errorCode"];
  final errorMessage = raw["errorMessage"];

  print("Failed: $errorMessage ($errorCode)");

  if (status == "permission_denied") {
    // Show dialog: "Enable contacts permission in Settings"
  }
}
```

### Error Status Codes

| Status              | Description                                       |
| ------------------- | ------------------------------------------------- |
| `permission_denied` | User denied permission                            |
| `error`             | Native exception (see `errorMessage` for details) |
| `success`           | Contacts fetched successfully                     |

---

## Performance Tips

1. **Use `minimizeData: true`** for name + phone only (10x faster on large contact lists)
2. **Use `onlyWithPhone: true`** to skip contacts without numbers
3. **Enable progress events** for large datasets (1000+ contacts)

```dart
// For 5000+ contacts, enable progress to avoid ANR/UI freezing
final raw = await FlutterSimpleContact.fetchContactsRaw(
  options: {
    "advanced": {"enableProgressEvents": true},
    // ...
  },
);
```

---

## Platform Differences

| Feature                 | Android             | iOS                       |
| ----------------------- | ------------------- | ------------------------- |
| Unified contacts        | ✅                  | ✅                        |
| Raw contacts            | ✅                  | ❌ (not exposed by Apple) |
| Starred/favorites       | ✅                  | ❌                        |
| Last modified timestamp | ✅                  | ❌                        |
| Notes                   | ✅ (no entitlement) | ⚠️ (requires entitlement) |
| All other fields        | ✅                  | ✅                        |

---

## iOS Notes Entitlement (Optional)

To enable `includeNotes: true` on iOS, add this to your Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` target → **Signing & Capabilities**
3. Click **+ Capability** → Search "Contacts"
4. Enable **Contacts Notes**

Or manually edit `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.contacts.notes</key>
<true/>
```

**Without this entitlement, `includeNotes: true` will cause an "Unauthorized Keys" error.**

---

## Examples

See the `/example` folder for a complete demo app with:

- Minimal mode UI
- Detailed mode UI
- Permission flow examples
- Error handling

Run:

```bash
cd example
flutter run
```

---

## Contributing

Contributions are welcome! This plugin intentionally has **zero dependencies** to maintain auditability for enterprise use. Please ensure:

- No third-party packages added for core contact fetching
- Code remains transparent and readable
- Tests pass on both Android and iOS

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_simple_contact/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_simple_contact/discussions)

---

## Roadmap

- [ ] EventChannel progress UI helper widget
- [ ] Contact write support (create/update/delete)
- [ ] Contact groups support
- [ ] SIM contacts filter (Android)
- [ ] Contact usage frequency (where available)

---

---

## Developer

**Developed by Gunjan Sharma**  
_Full Stack System Architect & Tech Lead_

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](<[https://www.linkedin.com/in/gunjan1sharma/](https://www.linkedin.com/in/gunjan1sharma/)>)
[![Email](https://img.shields.io/badge/Email-Contact-red?style=flat&logo=gmail)](mailto:gunjan.sharmo@gmail.com)

### Note on This Package

This is a **minimal, production-ready version** focused on core contact fetching with zero dependencies. It's built to be lightweight, transparent, and auditable for enterprise/fintech applications.

**Need Additional Features?**

If your use case isn't covered or you need extended functionality (e.g., contact write operations, advanced filters, SIM-specific contacts, contact groups), I'm happy to extend this package!

- **Request a Feature**: [Open an Issue](https://github.com/gunjan1sharma/flutter_simple_contact/issues/new) with detailed requirements
- **Found a Bug?**: [Report it here](https://github.com/gunjan1sharma/flutter_simple_contact/issues/new)
- **Like this package?**: Please ⭐ [star the repo](https://github.com/gunjan1sharma/flutter_simple_contact) to show your support!

Your feedback and contributions help make this package better for everyone in the Flutter community.

---

**Built with ❤️ for fintech and enterprise Flutter apps that need transparent, auditable contact access.**

```

```
