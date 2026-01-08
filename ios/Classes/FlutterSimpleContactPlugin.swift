import Flutter
import UIKit
import Contacts

public class FlutterSimpleContactPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_simple_contact/methods", binaryMessenger: registrar.messenger())
    let instance = FlutterSimpleContactPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "fetchContacts":
      let args = call.arguments as? [String: Any] ?? [:]
      fetchContacts(args: args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func fetchContacts(args: [String: Any], result: @escaping FlutterResult) {
    let handlePermission = args["handlePermission"] as? Bool ?? true
    let mode = args["mode"] as? String ?? "unified" // iOS is unified-first [web:61]
    let sort = args["sort"] as? String ?? "none"
    let filters = args["filters"] as? [String: Any] ?? [:]
    let minimizeData = args["minimizeData"] as? Bool ?? false

    let advanced = args["advanced"] as? [String: Any] ?? [:]
    let includeNotes = advanced["includeNotes"] as? Bool ?? false
    let enableProgressEvents = advanced["enableProgressEvents"] as? Bool ?? false


    let onlyWithPhone = filters["onlyWithPhone"] as? Bool ?? false
    let onlyStarred = filters["onlyStarred"] as? Bool ?? false // iOS has no starred in CNContact
    let onlyWithPhoto = filters["onlyWithPhoto"] as? Bool ?? false

    if onlyStarred {
      // Not supported on iOS Contacts framework in a stable way.
      result([
        "ok": false,
        "status": "error",
        "errorCode": "unsupported_filter",
        "errorMessage": "onlyStarred is not supported on iOS Contacts framework.",
        "contacts": []
      ])
      return
    }

    let store = CNContactStore()

    // Permission flow
    if handlePermission {
      let status = CNContactStore.authorizationStatus(for: .contacts)
      if status == .notDetermined {
        store.requestAccess(for: .contacts) { granted, err in
          DispatchQueue.main.async {
            if let err = err {
              result([
                "ok": false,
                "status": "error",
                "errorCode": "ios_permission_error",
                "errorMessage": err.localizedDescription,
                "contacts": []
              ])
              return
            }
            if !granted {
              result([
                "ok": false,
                "status": "permission_denied",
                "errorCode": "denied",
                "errorMessage": "Contacts permission denied by user.",
                "contacts": []
              ])
              return
            }
            self.fetchContactsAuthorized(
              store: store,
              mode: mode,
              sort: sort,
              onlyWithPhone: onlyWithPhone,
              onlyWithPhoto: onlyWithPhoto,
              minimizeData: minimizeData,
               includeNotes: includeNotes,
              result: result
            )
          }
        }
        return
      } else if status == .denied || status == .restricted {
        result([
          "ok": false,
          "status": "permission_denied",
          "errorCode": status == .denied ? "denied" : "restricted",
          "errorMessage": "Contacts permission is \(status == .denied ? "denied" : "restricted"). Enable it in Settings.",
          "contacts": []
        ])
        return
      }
      // .authorized or .limited (limited is for Photos; Contacts doesn't have limited)
    } else {
      // If caller disabled permission handling, fail fast if not authorized
      let status = CNContactStore.authorizationStatus(for: .contacts)
      if status != .authorized {
        result([
          "ok": false,
          "status": "permission_denied",
          "errorCode": "not_authorized",
          "errorMessage": "Contacts permission not authorized.",
          "contacts": []
        ])
        return
      }
    }

 fetchContactsAuthorized(
   store: store,
   mode: mode,
   sort: sort,
   onlyWithPhone: onlyWithPhone,
   onlyWithPhoto: onlyWithPhoto,
   minimizeData: minimizeData,
   includeNotes: includeNotes,  // ✅ CORRECT
   result: result
 )

  }

  private func fetchContactsAuthorized(
    store: CNContactStore,
    mode: String,
    sort: String,
    onlyWithPhone: Bool,
    onlyWithPhoto: Bool,
    minimizeData: Bool,
    includeNotes: Bool,
    result: @escaping FlutterResult
  ) {
    // keysToFetch controls which data is returned by iOS Contacts framework [web:61]
    var keys: [CNKeyDescriptor] = [
      CNContactIdentifierKey as CNKeyDescriptor,
      CNContactGivenNameKey as CNKeyDescriptor,
      CNContactMiddleNameKey as CNKeyDescriptor,
      CNContactFamilyNameKey as CNKeyDescriptor,
      CNContactOrganizationNameKey as CNKeyDescriptor,
      CNContactPhoneNumbersKey as CNKeyDescriptor,
      CNContactImageDataAvailableKey as CNKeyDescriptor,
      CNContactThumbnailImageDataKey as CNKeyDescriptor
    ]

//     if !minimizeData {
//       // Add more metadata keys (safe/common). Add more in Batch 4 if needed.
//       keys.append(CNContactEmailAddressesKey as CNKeyDescriptor)
//       keys.append(CNContactPostalAddressesKey as CNKeyDescriptor)
//       keys.append(CNContactUrlAddressesKey as CNKeyDescriptor)
//       keys.append(CNContactSocialProfilesKey as CNKeyDescriptor)
//       keys.append(CNContactBirthdayKey as CNKeyDescriptor)
//       keys.append(CNContactInstantMessageAddressesKey as CNKeyDescriptor)
//       keys.append(CNContactDatesKey as CNKeyDescriptor)
//       keys.append(CNContactRelationsKey as CNKeyDescriptor)
//       keys.append(CNContactNoteKey as CNKeyDescriptor) // may require entitlement in some cases
//     }

if !minimizeData {
  // Add more metadata keys (safe/common)
  keys.append(CNContactEmailAddressesKey as CNKeyDescriptor)
  keys.append(CNContactPostalAddressesKey as CNKeyDescriptor)
  keys.append(CNContactUrlAddressesKey as CNKeyDescriptor)
  keys.append(CNContactSocialProfilesKey as CNKeyDescriptor)
  keys.append(CNContactBirthdayKey as CNKeyDescriptor)
  keys.append(CNContactInstantMessageAddressesKey as CNKeyDescriptor)
  keys.append(CNContactDatesKey as CNKeyDescriptor)
  keys.append(CNContactRelationsKey as CNKeyDescriptor)

  // ONLY add note key if explicitly requested (requires entitlement)
  if includeNotes {
    keys.append(CNContactNoteKey as CNKeyDescriptor)
  }
}


    let request = CNContactFetchRequest(keysToFetch: keys)
    // Sorting options supported by CNContactFetchRequest: user default / given / family
    // We'll map your sort options to iOS-supported ones.
    switch sort {
    case "alphabetical":
      request.sortOrder = .userDefault
    default:
      request.sortOrder = .none
    }

    var out: [[String: Any]] = []

    do {
      try store.enumerateContacts(with: request) { contact, stop in
        let hasPhoto = contact.imageDataAvailable
        if onlyWithPhoto && !hasPhoto { return }

        let emails = contact.emailAddresses.map { v in
  return [
    "address": v.value as String,
    "label": CNLabeledValue<NSString>.localizedString(forLabel: v.label ?? "")
  ]
}

let websites = contact.urlAddresses.map { v in
  return [
    "url": v.value as String,
    "label": CNLabeledValue<NSString>.localizedString(forLabel: v.label ?? "")
  ]
}

let addresses = contact.postalAddresses.map { v in
  let a = v.value
  return [
    "label": CNLabeledValue<NSString>.localizedString(forLabel: v.label ?? ""),
    "street": a.street,
    "city": a.city,
    "state": a.state,
    "postalCode": a.postalCode,
    "country": a.country,
    "isoCountryCode": a.isoCountryCode
  ]
}

        let phones = contact.phoneNumbers.map { labeledValue -> [String: Any] in
          let number = labeledValue.value.stringValue
          let label = CNLabeledValue<NSString>.localizedString(forLabel: labeledValue.label ?? "")
          return [
            "number": number,
            "label": label,
            "normalizedNumber": NSNull() // iOS doesn't provide normalized number reliably here
          ]
        }.filter { phoneMap in
          let n = phoneMap["number"] as? String ?? ""
          return !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if onlyWithPhone && phones.isEmpty { return }

        let displayName = self.buildDisplayName(contact: contact)

        var map: [String: Any] = [
          "id": contact.identifier,
          "rawContactId": NSNull(), // iOS doesn't expose raw-contact id like Android
          "displayName": displayName,
          "phones": phones,
          "starred": NSNull(),
          "hasPhoto": hasPhoto,
          "lastModifiedMillis": NSNull(),
          "emails": emails,
          "addresses": addresses,
          "websites": websites
        ]

        // Best-effort extras (do not promise availability)
        if mode == "raw" {
          // iOS has containers (accounts) but not raw contact rows in the same sense.
          // We can attach container identifiers later in Batch 4 if you want.
        }

        out.append(map)
      }

      result([
        "ok": true,
        "status": "success",
        "contacts": out
      ])
      } catch let error as NSError {
        let keyPaths = (error.userInfo["CNKeyPaths"] as? [String]) ?? []
        result([
          "ok": false,
          "status": "error",
          "errorCode": "ios_fetch_error",
          "errorMessage": "\(error.localizedDescription) | unauthorizedKeys=\(keyPaths.joined(separator: ", "))",
          "contacts": []
        ])
      }}



  private func buildDisplayName(contact: CNContact) -> String {
    // Keep it predictable, no formatter dependency
    let parts = [contact.givenName, contact.middleName, contact.familyName]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    if !parts.isEmpty { return parts.joined(separator: " ") }

    // fallback
    if !contact.organizationName.isEmpty { return contact.organizationName }

    return "Unknown"
  }
}
