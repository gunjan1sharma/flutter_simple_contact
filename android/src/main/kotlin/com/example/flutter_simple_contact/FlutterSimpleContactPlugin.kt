package com.example.flutter_simple_contact

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class FlutterSimpleContactPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

  private lateinit var channel: MethodChannel
  private var applicationContext: Context? = null
  private var activity: Activity? = null

  private var pendingResult: Result? = null
  private var pendingCall: MethodCall? = null

  private val REQ_CONTACTS = 7001

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "flutter_simple_contact/methods")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    applicationContext = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "fetchContacts" -> handleFetchContacts(call, result)
      else -> result.notImplemented()
    }
  }

  private fun handleFetchContacts(call: MethodCall, result: Result) {
    val ctx = applicationContext
    if (ctx == null) {
      result.success(mapOf(
        "ok" to false,
        "status" to "error",
        "errorCode" to "no_context",
        "errorMessage" to "Android context is null",
        "contacts" to emptyList<Map<String, Any?>>()
      ))
      return
    }

    val args = (call.arguments as? Map<*, *>) ?: emptyMap<Any, Any>()
    val handlePermission = args["handlePermission"] as? Boolean ?: true

    if (handlePermission) {
      val has = hasReadContactsPermission(ctx)
      if (!has) {
        val act = activity
        if (act == null) {
          result.success(mapOf(
            "ok" to false,
            "status" to "permission_denied",
            "errorCode" to "no_activity",
            "errorMessage" to "No Activity attached; cannot request permission",
            "contacts" to emptyList<Map<String, Any?>>()
          ))
          return
        }

        // Request permission and resume later
        pendingResult = result
        pendingCall = call
        ActivityCompat.requestPermissions(act, arrayOf(Manifest.permission.READ_CONTACTS), REQ_CONTACTS)
        return
      }
    } else {
      // If caller disabled permission handling, fail fast if not granted
      if (!hasReadContactsPermission(ctx)) {
        result.success(mapOf(
          "ok" to false,
          "status" to "permission_denied",
          "errorCode" to "read_contacts_not_granted",
          "errorMessage" to "READ_CONTACTS not granted",
          "contacts" to emptyList<Map<String, Any?>>()
        ))
        return
      }
    }

    // Permission available -> fetch
    result.success(fetchContacts(ctx.contentResolver, args))
  }

  private fun hasReadContactsPermission(ctx: Context): Boolean {
    return ContextCompat.checkSelfPermission(ctx, Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED
  }

  private fun fetchContacts(resolver: ContentResolver, args: Map<*, *>): Map<String, Any?> {
    val mode = (args["mode"] as? String) ?: "unified"
    val sort = (args["sort"] as? String) ?: "none"
    val filters = (args["filters"] as? Map<*, *>) ?: emptyMap<Any, Any>()
    val minimizeData = args["minimizeData"] as? Boolean ?: false

    val onlyWithPhone = filters["onlyWithPhone"] as? Boolean ?: false
    val onlyStarred = filters["onlyStarred"] as? Boolean ?: false
    val onlyWithPhoto = filters["onlyWithPhoto"] as? Boolean ?: false

    return try {
      val contacts = if (mode == "raw") {
        fetchRawContacts(resolver, sort, onlyWithPhone, onlyStarred, onlyWithPhoto, minimizeData)
      } else {
        fetchUnifiedContacts(resolver, sort, onlyWithPhone, onlyStarred, onlyWithPhoto, minimizeData)
      }

      mapOf(
        "ok" to true,
        "status" to "success",
        "contacts" to contacts
      )
    } catch (t: Throwable) {
      mapOf(
        "ok" to false,
        "status" to "error",
        "errorCode" to "android_exception",
        "errorMessage" to (t.message ?: t.toString()),
        "contacts" to emptyList<Map<String, Any?>>()
      )
    }
  }

  /**
   * Unified contacts = ContactsContract.Contacts (aggregated people)
   * Contacts Provider structure: Contacts / RawContacts / Data [page:1].
   */
  private fun fetchUnifiedContacts(
    resolver: ContentResolver,
    sort: String,
    onlyWithPhone: Boolean,
    onlyStarred: Boolean,
    onlyWithPhoto: Boolean,
    minimizeData: Boolean,
  ): List<Map<String, Any?>> {

    val projection = arrayOf(
      ContactsContract.Contacts._ID,
      ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
      ContactsContract.Contacts.HAS_PHONE_NUMBER,
      ContactsContract.Contacts.STARRED,
      ContactsContract.Contacts.PHOTO_URI,
      ContactsContract.Contacts.CONTACT_LAST_UPDATED_TIMESTAMP
    )

    val selectionParts = mutableListOf<String>()
    val selectionArgs = mutableListOf<String>()

    if (onlyWithPhone) selectionParts.add("${ContactsContract.Contacts.HAS_PHONE_NUMBER}=1")
    if (onlyStarred) selectionParts.add("${ContactsContract.Contacts.STARRED}=1")
    if (onlyWithPhoto) selectionParts.add("${ContactsContract.Contacts.PHOTO_URI} IS NOT NULL")

    val selection = if (selectionParts.isEmpty()) null else selectionParts.joinToString(" AND ")

    val sortOrder = when (sort) {
      "alphabetical" -> "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} COLLATE LOCALIZED ASC"
      "lastUpdatedDesc" -> "${ContactsContract.Contacts.CONTACT_LAST_UPDATED_TIMESTAMP} DESC"
      else -> null
    }

    val out = ArrayList<Map<String, Any?>>()

    resolver.query(
      ContactsContract.Contacts.CONTENT_URI,
      projection,
      selection,
      if (selectionArgs.isEmpty()) null else selectionArgs.toTypedArray(),
      sortOrder
    )?.use { cursor ->
      val idIdx = cursor.getColumnIndexOrThrow(ContactsContract.Contacts._ID)
      val nameIdx = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
      val starredIdx = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.STARRED)
      val photoIdx = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.PHOTO_URI)
      val updatedIdx = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.CONTACT_LAST_UPDATED_TIMESTAMP)

      while (cursor.moveToNext()) {
        val contactId = cursor.getString(idIdx)
        val displayName = cursor.getString(nameIdx) ?: ""
        val starred = cursor.getInt(starredIdx) == 1
        val hasPhoto = !cursor.isNull(photoIdx)
        val lastUpdated = if (cursor.isNull(updatedIdx)) null else cursor.getLong(updatedIdx)

        val phones = if (minimizeData) {
          fetchPhonesForContact(resolver, contactId)
        } else {
          fetchPhonesForContact(resolver, contactId) // still only phones for now; more metadata in later batch
        }

        if (onlyWithPhone && phones.isEmpty()) continue

        out.add(
          mapOf(
            "id" to contactId,
            "rawContactId" to null, // unified contact doesn't map to a single raw id
            "displayName" to displayName,
            "phones" to phones,
            "starred" to starred,
            "hasPhoto" to hasPhoto,
            "lastModifiedMillis" to lastUpdated
          )
        )
      }
    }

    return out
  }

  /**
   * Raw contacts = ContactsContract.RawContacts rows (per-account source)
   * RawContacts table documented by Android Contacts Provider [page:1].
   */
  private fun fetchRawContacts(
    resolver: ContentResolver,
    sort: String,
    onlyWithPhone: Boolean,
    onlyStarred: Boolean,
    onlyWithPhoto: Boolean,
    minimizeData: Boolean,
  ): List<Map<String, Any?>> {

    val projection = arrayOf(
      ContactsContract.RawContacts._ID,
      ContactsContract.RawContacts.CONTACT_ID,
      ContactsContract.RawContacts.DELETED
    )

    val selectionParts = mutableListOf<String>()
    if (onlyStarred) {
      // STARRED is on Contacts table; for raw mode we filter later by reading contact row
    }
    selectionParts.add("${ContactsContract.RawContacts.DELETED}=0") // skip deleted raw contacts [page:1]
    val selection = selectionParts.joinToString(" AND ")

    val sortOrder = when (sort) {
      "lastUpdatedDesc" -> null // RawContacts has VERSION but not a reliable timestamp; keep none for now
      "alphabetical" -> null
      else -> null
    }

    val out = ArrayList<Map<String, Any?>>()

    resolver.query(
      ContactsContract.RawContacts.CONTENT_URI,
      projection,
      selection,
      null,
      sortOrder
    )?.use { cursor ->
      val rawIdIdx = cursor.getColumnIndexOrThrow(ContactsContract.RawContacts._ID)
      val contactIdIdx = cursor.getColumnIndexOrThrow(ContactsContract.RawContacts.CONTACT_ID)

      while (cursor.moveToNext()) {
        val rawId = cursor.getString(rawIdIdx)
        val contactId = cursor.getString(contactIdIdx)

        // For raw contact display name + phones, we still query by CONTACT_ID for simplicity.
        val displayName = fetchDisplayNameForContactId(resolver, contactId) ?: ""
        val starred = fetchStarredForContactId(resolver, contactId)
        val hasPhoto = fetchHasPhotoForContactId(resolver, contactId)
        val phones = fetchPhonesForContact(resolver, contactId)

        if (onlyWithPhone && phones.isEmpty()) continue
        if (onlyStarred && starred != true) continue
        if (onlyWithPhoto && hasPhoto != true) continue

        out.add(
          mapOf(
            "id" to contactId,
            "rawContactId" to rawId,
            "displayName" to displayName,
            "phones" to phones,
            "starred" to starred,
            "hasPhoto" to hasPhoto,
            "lastModifiedMillis" to fetchLastUpdatedForContactId(resolver, contactId)
          )
        )
      }
    }

    return out
  }

  private fun fetchPhonesForContact(resolver: ContentResolver, contactId: String): List<Map<String, Any?>> {
    val out = ArrayList<Map<String, Any?>>()

    val projection = arrayOf(
      ContactsContract.CommonDataKinds.Phone.NUMBER,
      ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER,
      ContactsContract.CommonDataKinds.Phone.TYPE,
      ContactsContract.CommonDataKinds.Phone.LABEL
    )

    resolver.query(
      ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
      projection,
      "${ContactsContract.CommonDataKinds.Phone.CONTACT_ID}=?",
      arrayOf(contactId),
      null
    )?.use { cursor ->
      val numIdx = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
      val normIdx = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER)
      val typeIdx = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.TYPE)
      val labelIdx = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.LABEL)

      while (cursor.moveToNext()) {
        val number = cursor.getString(numIdx) ?: ""
        if (number.isBlank()) continue

        val normalized = if (cursor.isNull(normIdx)) null else cursor.getString(normIdx)
        val type = cursor.getInt(typeIdx)
        val customLabel = if (cursor.isNull(labelIdx)) null else cursor.getString(labelIdx)
        val label = ContactsContract.CommonDataKinds.Phone.getTypeLabel(
          applicationContext?.resources,
          type,
          customLabel
        )?.toString()

        out.add(
          mapOf(
            "number" to number,
            "normalizedNumber" to normalized,
            "label" to label
          )
        )
      }
    }

    return out
  }

  private fun fetchDisplayNameForContactId(resolver: ContentResolver, contactId: String): String? {
    resolver.query(
      ContactsContract.Contacts.CONTENT_URI,
      arrayOf(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY),
      "${ContactsContract.Contacts._ID}=?",
      arrayOf(contactId),
      null
    )?.use { c ->
      if (c.moveToFirst()) return c.getString(0)
    }
    return null
  }

  private fun fetchStarredForContactId(resolver: ContentResolver, contactId: String): Boolean? {
    resolver.query(
      ContactsContract.Contacts.CONTENT_URI,
      arrayOf(ContactsContract.Contacts.STARRED),
      "${ContactsContract.Contacts._ID}=?",
      arrayOf(contactId),
      null
    )?.use { c ->
      if (c.moveToFirst()) return c.getInt(0) == 1
    }
    return null
  }

  private fun fetchHasPhotoForContactId(resolver: ContentResolver, contactId: String): Boolean? {
    resolver.query(
      ContactsContract.Contacts.CONTENT_URI,
      arrayOf(ContactsContract.Contacts.PHOTO_URI),
      "${ContactsContract.Contacts._ID}=?",
      arrayOf(contactId),
      null
    )?.use { c ->
      if (c.moveToFirst()) return !c.isNull(0)
    }
    return null
  }

  private fun fetchLastUpdatedForContactId(resolver: ContentResolver, contactId: String): Long? {
    resolver.query(
      ContactsContract.Contacts.CONTENT_URI,
      arrayOf(ContactsContract.Contacts.CONTACT_LAST_UPDATED_TIMESTAMP),
      "${ContactsContract.Contacts._ID}=?",
      arrayOf(contactId),
      null
    )?.use { c ->
      if (c.moveToFirst()) return if (c.isNull(0)) null else c.getLong(0)
    }
    return null
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
      if (requestCode == REQ_CONTACTS) {
        val res = pendingResult
        val call = pendingCall
        pendingResult = null
        pendingCall = null

        if (res == null || call == null) return@addRequestPermissionsResultListener false

        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        val ctx = applicationContext

        if (!granted) {
          val act = activity
          val permanentlyDenied = act != null && !ActivityCompat.shouldShowRequestPermissionRationale(act, Manifest.permission.READ_CONTACTS)

          res.success(mapOf(
            "ok" to false,
            "status" to "permission_denied",
            "errorCode" to if (permanentlyDenied) "permanently_denied" else "denied",
            "errorMessage" to if (permanentlyDenied) "Permission permanently denied; open settings." else "Permission denied.",
            "contacts" to emptyList<Map<String, Any?>>()
          ))
          return@addRequestPermissionsResultListener true
        }

        if (ctx == null) {
          res.success(mapOf(
            "ok" to false,
            "status" to "error",
            "errorCode" to "no_context",
            "errorMessage" to "Android context is null after permission grant",
            "contacts" to emptyList<Map<String, Any?>>()
          ))
          return@addRequestPermissionsResultListener true
        }

        val args = (call.arguments as? Map<*, *>) ?: emptyMap<Any, Any>()
        res.success(fetchContacts(ctx.contentResolver, args))
        return@addRequestPermissionsResultListener true
      }
      false
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
