import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

sealed class FileTunnelPickerState {
  const FileTunnelPickerState();
}

final class Idle extends FileTunnelPickerState {
  const Idle();
}

final class Creating extends FileTunnelPickerState {
  const Creating();
}

final class Pairing extends FileTunnelPickerState {
  const Pairing({required this.uri, required this.expiresAt});
  final Uri uri;
  final DateTime expiresAt;
}

final class Transferring extends FileTunnelPickerState {
  const Transferring({
    required this.uri,
    required this.expiresAt,
    required this.files,
  });
  final Uri uri;
  final DateTime expiresAt;
  final List<TunnelFileProgress> files;
}

final class Complete extends FileTunnelPickerState {
  const Complete();
}

final class Failed extends FileTunnelPickerState {
  const Failed(this.message);
  final String message;
}

@immutable
final class TunnelFileProgress {
  const TunnelFileProgress({
    required this.id,
    required this.name,
    required this.fractionCompleted,
    this.isComplete = false,
  });
  final String id;
  final String name;
  final double fractionCompleted;
  final bool isComplete;
}

final class FileTunnelPicker extends StatelessWidget {
  const FileTunnelPicker({
    required this.state,
    required this.chooseLocal,
    required this.chooseRemote,
    required this.cancel,
    super.key,
  });

  final FileTunnelPickerState state;
  final VoidCallback chooseLocal;
  final VoidCallback chooseRemote;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Add files',
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add files', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          switch (state) {
            Idle() => _SourceChoices(
              chooseLocal: chooseLocal,
              chooseRemote: chooseRemote,
            ),
            Creating() => const Column(
              children: [
                LinearProgressIndicator(),
                SizedBox(height: 12),
                Text('Opening a secure tunnel…'),
              ],
            ),
            Pairing(:final uri, :final expiresAt) => _Pairing(
              uri: uri,
              expiresAt: expiresAt,
              files: const [],
              cancel: cancel,
            ),
            Transferring(:final uri, :final expiresAt, :final files) =>
              _Pairing(
                uri: uri,
                expiresAt: expiresAt,
                files: files,
                cancel: cancel,
              ),
            Complete() => const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Files received'),
            ),
            Failed(:final message) => Column(
              children: [
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: chooseRemote,
                  child: const Text('Try again'),
                ),
              ],
            ),
          },
        ],
      ),
    ),
  );
}

final class _SourceChoices extends StatelessWidget {
  const _SourceChoices({required this.chooseLocal, required this.chooseRemote});
  final VoidCallback chooseLocal;
  final VoidCallback chooseRemote;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: chooseLocal,
        icon: const Icon(Icons.folder_outlined),
        label: const Text('Files on this device'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: chooseRemote,
        icon: const Icon(Icons.qr_code),
        label: const Text('Files on another device'),
      ),
    ],
  );
}

final class _Pairing extends StatelessWidget {
  const _Pairing({
    required this.uri,
    required this.expiresAt,
    required this.files,
    required this.cancel,
  });
  final Uri uri;
  final DateTime expiresAt;
  final List<TunnelFileProgress> files;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Scan with your phone',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      Semantics(
        label: 'Pairing QR code. Scan with the device that has your files.',
        image: true,
        child: Center(
          child: QrImageView(
            data: uri.toString(),
            size: 224,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...files.map(
        (file) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: LinearProgressIndicator(
            value: file.fractionCompleted.clamp(0, 1),
          ),
          trailing: Text(
            file.isComplete
                ? 'Received'
                : '${(file.fractionCompleted.clamp(0, 1) * 100).round()}%',
          ),
        ),
      ),
      TextButton(onPressed: cancel, child: const Text('Cancel')),
    ],
  );
}
