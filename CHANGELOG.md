# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-01-08

### 🎉 Initial Release

First public release of `flutter_simple_contact` - a lightweight, transparent contact fetching plugin for Flutter with zero third-party dependencies.

### ✨ Features

#### Core Functionality

- **Android Support**: Full support for Android API 21+ using native `ContactsContract` provider
- **iOS Support**: Full support for iOS 13.0+ using native `CNContactStore` Contacts framework
- **Zero Dependencies**: No third-party packages - direct native implementation only
- **Lightweight**: ~5KB package size for maximum efficiency

#### Contact Modes

- **Unified Contacts**: Fetch aggregated contacts (default, works on both platforms)
- **Raw Contacts**: Fetch per-account raw contacts (Android only)
- Automatic fallback handling for platform-specific limitations

#### Permission Management

- **Built-in Permission Handling**: Automatic runtime permission requests
- **Manual Permission Mode**: Disable auto-handling for custom flows
- **Permission Status Tracking**: Detailed error codes for denied/permanently denied states
- Platform-specific permission dialogs (Material for Android, Cupertino for iOS)

#### Data Fetching Options

##### Minimal Mode (`minimizeData: true`)

- Contact ID
- Display name
- Phone numbers with labels
- Photo availability flag
- Starred/favorite status (Android only)
- Last modified timestamp (Android only)

##### Full Metadata Mode (`minimizeData: false`)

- All minimal mode fields, plus:
- **Email addresses** with labels
- **Postal addresses** (street, city, state, postal code, country, ISO code, labels)
- **Websites** with labels
- **Organizations** (company, department, job title)
- **Notes** (iOS: requires entitlement; Android: included)
- **Social profiles** (keys included for future use)
- **Birthdays** (keys included for future use)
- **Relations** (keys included for future use)

#### Filters

- `onlyWithPhone`: Skip contacts without phone numbers
- `onlyStarred`: Only starred/favorite contacts (Android only)
- `onlyWithPhoto`: Only contacts with profile photos

#### Sorting

- `none`: Default system order
- `alphabetical`: Sort by display name (locale-aware)
- `lastUpdatedDesc`: Sort by last modified timestamp (Android only)

#### Advanced Features

- **EventChannel Progress**: Optional progress events for large contact lists
- **Cancel Support**: Cancel ongoing fetch operations via `cancelFetch()`
- **Raw Map API**: Flexible JSON-like output for backend integration
- **Typed API**: Strongly-typed Dart models for type safety
- **iOS Notes Support**: Optional with entitlement flag (`includeNotes`)

### 🔒 Security & Privacy

- Transparent source code (auditable by enterprises)
- No data sent to third parties
- Respects platform permission models
- Optional minimal data collection mode
- Clear permission rationale requirements

### 📱 Platform-Specific Implementations

#### Android

- Uses `ContactsContract.Contacts` for unified contacts
- Uses `ContactsContract.RawContacts` for raw contact mode
- Queries `ContactsContract.Data` table for rich metadata (emails, addresses, websites)
- Runtime permission handling via `ActivityCompat`
- Supports filters: starred, hasPhoto, hasPhone
- Returns `lastModifiedMillis` timestamp where available

#### iOS

- Uses `CNContactStore.enumerateContacts` for efficient fetching
- `keysToFetch` optimization to avoid unauthorized key errors
- Conditional `CNContactNoteKey` based on `includeNotes` flag
- Handles `.notDetermined`, `.denied`, `.restricted`, `.authorized` states
- Returns structured postal addresses with ISO country codes
- Organization data (company, department, job title) from contact fields

### 🛠️ APIs

#### Methods

- `FlutterSimpleContact.fetchContactsRaw()`: Returns raw maps
- `FlutterSimpleContact.fetchContacts()`: Returns typed `SimpleFetchResult`
- `FlutterSimpleContact.cancelFetch()`: Cancel ongoing operation
- `FlutterSimpleContact.progressStreamRaw()`: Listen to progress events

#### Models

- `SimpleFetchOptions`: Main configuration object
- `SimpleFetchFilters`: Contact filtering options
- `SimpleAdvancedOptions`: Progress events and iOS notes config
- `SimpleFetchResult`: Typed result with status/error handling
- `SimpleContact`: Typed contact model
- `SimplePhone`: Phone number with label

### 📋 Configuration Options

| Option                 | Type     | Default     | Description                            |
| ---------------------- | -------- | ----------- | -------------------------------------- |
| `handlePermission`     | `bool`   | `true`      | Auto-request permissions               |
| `mode`                 | `String` | `"unified"` | Contact mode (unified/raw)             |
| `sort`                 | `String` | `"none"`    | Sort order                             |
| `minimizeData`         | `bool`   | `false`     | Fetch only name + phones               |
| `onlyWithPhone`        | `bool`   | `false`     | Filter: has phone                      |
| `onlyStarred`          | `bool`   | `false`     | Filter: starred (Android)              |
| `onlyWithPhoto`        | `bool`   | `false`     | Filter: has photo                      |
| `enableProgressEvents` | `bool`   | `false`     | Enable progress stream                 |
| `includeNotes`         | `bool`   | `false`     | Fetch notes (iOS entitlement required) |

### 🐛 Known Limitations

- **iOS Starred Contacts**: Not exposed by Apple's Contacts framework (returns error if `onlyStarred: true` on iOS)
- **iOS Raw Contacts**: Not available (iOS only provides unified contacts)
- **iOS Last Modified**: Timestamp not reliably available via public API
- **iOS Notes**: Requires `com.apple.developer.contacts.notes` entitlement
- **Android Website Labels**: Manual mapping (no native `getTypeLabel()` helper)

### 📦 Package Info

- **Minimum Flutter SDK**: 3.22.0
- **Minimum Dart SDK**: 3.9.0
- **Android Minimum SDK**: API 21 (Android 5.0 Lollipop)
- **iOS Minimum Version**: 13.0
- **Package Size**: ~5KB
- **Dependencies**: 0 (zero third-party packages)

### 🧪 Testing

- Tested on Android emulator (API 34)
- Tested on iOS simulator (iOS 17)
- Verified with 7+ test contacts
- Permission flows validated on both platforms
- Error handling tested (denied/permanently denied states)

### 📝 Documentation

- Complete README with usage examples
- Inline code documentation
- Platform setup instructions
- Error handling guide
- Performance optimization tips
- Platform differences table

### 🙏 Credits

Developed by **Gunjan Sharma** (Full Stack System Architect & Tech Lead)

---

## [Unreleased]

### Planned Features (Community Requested)

- Progress UI helper widget
- Contact write operations (create/update/delete)
- Contact groups support
- SIM-specific contacts filter (Android)
- Contact usage frequency (where available)
- Batch operations for large contact lists

---

[0.0.1]: https://github.com/gunjan1sharma/flutter_simple_contact/releases/tag/v0.0.1
