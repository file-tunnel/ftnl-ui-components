package dev.filetunnel.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import java.time.Instant

data class TunnelFileProgress(
    val id: String,
    val name: String,
    val fractionCompleted: Float,
    val complete: Boolean = false,
)

sealed interface FileTunnelPickerState {
    data object Idle : FileTunnelPickerState
    data object Creating : FileTunnelPickerState
    data class Pairing(val uri: String, val expiresAt: Instant) : FileTunnelPickerState
    data class Transferring(
        val uri: String,
        val expiresAt: Instant,
        val files: List<TunnelFileProgress>,
    ) : FileTunnelPickerState
    data object Complete : FileTunnelPickerState
    data class Failed(val message: String) : FileTunnelPickerState
}

@Composable
fun FileTunnelPicker(
    state: FileTunnelPickerState,
    chooseLocal: () -> Unit,
    chooseRemote: () -> Unit,
    cancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text("Add files", style = MaterialTheme.typography.headlineLarge)
        when (state) {
            FileTunnelPickerState.Idle -> {
                Button(onClick = chooseLocal, modifier = Modifier.fillMaxWidth()) {
                    Text("Files on this device")
                }
                OutlinedButton(onClick = chooseRemote, modifier = Modifier.fillMaxWidth()) {
                    Text("Files on another device")
                }
            }
            FileTunnelPickerState.Creating -> {
                Text("Opening a secure tunnel…")
                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
            }
            is FileTunnelPickerState.Pairing ->
                Pairing(state.uri, emptyList(), cancel)
            is FileTunnelPickerState.Transferring ->
                Pairing(state.uri, state.files, cancel)
            FileTunnelPickerState.Complete -> Text("Files received")
            is FileTunnelPickerState.Failed -> {
                Text(state.message, color = MaterialTheme.colorScheme.error)
                Button(onClick = chooseRemote) { Text("Try again") }
            }
        }
    }
}

@Composable
private fun Pairing(
    uri: String,
    files: List<TunnelFileProgress>,
    cancel: () -> Unit,
) {
    val size = with(LocalDensity.current) { 224.dp.roundToPx() }
    val bitmap = remember(uri, size) { qrBitmap(uri, size) }
    Text("Scan with your phone", style = MaterialTheme.typography.headlineSmall)
    Image(
        bitmap.asImageBitmap(),
        contentDescription = null,
        modifier = Modifier.semantics {
            contentDescription = "Pairing QR code. Scan with the device that has your files."
        },
    )
    files.forEach { file ->
        Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(file.name, maxLines = 1)
                Text(if (file.complete) "Received" else "${(file.fractionCompleted * 100).toInt()}%")
            }
            LinearProgressIndicator(
                progress = { file.fractionCompleted.coerceIn(0f, 1f) },
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
    OutlinedButton(onClick = cancel) { Text("Cancel") }
}

internal fun qrBitmap(value: String, size: Int): Bitmap {
    val matrix = QRCodeWriter().encode(value, BarcodeFormat.QR_CODE, size, size)
    val pixels = IntArray(size * size)
    for (y in 0 until size) {
        for (x in 0 until size) {
            pixels[y * size + x] = if (matrix[x, y]) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
        }
    }
    return Bitmap.createBitmap(pixels, size, size, Bitmap.Config.ARGB_8888)
}
