package com.roosty.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private var pendingDirectoryResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> pickDirectory(result)
                "writeTextFile" -> {
                    try {
                        val treeUri = call.argument<String>("treeUri")
                            ?: throw IllegalArgumentException("treeUri is required")
                        val directoryName = call.argument<String>("directoryName")
                            ?: throw IllegalArgumentException("directoryName is required")
                        val fileName = call.argument<String>("fileName")
                            ?: throw IllegalArgumentException("fileName is required")
                        val content = call.argument<String>("content")
                            ?: throw IllegalArgumentException("content is required")
                        val writtenName = writeTextFile(treeUri, directoryName, fileName, content)
                        result.success(writtenName)
                    } catch (error: Exception) {
                        result.error("write_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingDirectoryResult != null) {
            result.error("pick_in_progress", "Directory picker is already open.", null)
            return
        }

        pendingDirectoryResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, PICK_DIRECTORY_REQUEST_CODE)
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_DIRECTORY_REQUEST_CODE) {
            return
        }

        val result = pendingDirectoryResult
        pendingDirectoryResult = null
        if (result == null) {
            return
        }

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val uri = data.data!!
        val flags = data.flags and (
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
            result.success(uri.toString())
        } catch (error: Exception) {
            result.error("permission_failed", error.message, null)
        }
    }

    private fun writeTextFile(
        treeUriValue: String,
        directoryName: String,
        fileName: String,
        content: String,
    ): String {
        val treeUri = Uri.parse(treeUriValue)
        val rootUri = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val directoryUri = findChild(treeUri, rootUri, directoryName, DIRECTORY_MIME_TYPE)
            ?: DocumentsContract.createDocument(
                contentResolver,
                rootUri,
                DIRECTORY_MIME_TYPE,
                directoryName,
            )
            ?: throw IllegalStateException("Could not create $directoryName directory")
        val availableName = nextAvailableName(treeUri, directoryUri, fileName)
        val fileUri = DocumentsContract.createDocument(
            contentResolver,
            directoryUri,
            "text/markdown",
            availableName,
        ) ?: throw IllegalStateException("Could not create $availableName")

        contentResolver.openOutputStream(fileUri, "wt").use { stream ->
            if (stream == null) {
                throw IllegalStateException("Could not open $availableName for writing")
            }
            stream.write(content.toByteArray(StandardCharsets.UTF_8))
        }
        return availableName
    }

    private fun nextAvailableName(treeUri: Uri, parentUri: Uri, fileName: String): String {
        val dotIndex = fileName.lastIndexOf('.')
        val baseName = if (dotIndex > 0) fileName.substring(0, dotIndex) else fileName
        val extension = if (dotIndex > 0) fileName.substring(dotIndex) else ""
        var candidate = fileName
        var suffix = 2
        while (findChild(treeUri, parentUri, candidate, null) != null) {
            candidate = "$baseName-$suffix$extension"
            suffix += 1
        }
        return candidate
    }

    private fun findChild(
        treeUri: Uri,
        parentUri: Uri,
        displayName: String,
        mimeType: String?,
    ): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getDocumentId(parentUri),
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
        )
        contentResolver.query(childrenUri, projection, null, null, null).use { cursor ->
            if (cursor == null) {
                return null
            }
            val idIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
            while (cursor.moveToNext()) {
                val childName = cursor.getString(nameIndex)
                val childMimeType = cursor.getString(mimeIndex)
                if (childName == displayName && (mimeType == null || childMimeType == mimeType)) {
                    val documentId = cursor.getString(idIndex)
                    return DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                }
            }
        }
        return null
    }

    companion object {
        private const val CHANNEL = "roosty/android_saf"
        private const val PICK_DIRECTORY_REQUEST_CODE = 7301
        private val DIRECTORY_MIME_TYPE = DocumentsContract.Document.MIME_TYPE_DIR
    }
}
