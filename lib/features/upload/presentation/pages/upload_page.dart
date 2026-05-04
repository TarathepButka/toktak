import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toktak/core/theme/app_theme.dart';
import 'package:toktak/injection.dart';
import 'package:toktak/features/upload/presentation/bloc/upload_bloc.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UploadBloc>(),
      child: const _UploadPageView(),
    );
  }
}

class _UploadPageView extends StatefulWidget {
  const _UploadPageView();

  @override
  State<_UploadPageView> createState() => _UploadPageViewState();
}

class _UploadPageViewState extends State<_UploadPageView> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false, // stream from path, don't load into memory
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;
      if (!context.mounted) return;

      final path = result.files.single.path;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not access the selected file. Try a different video.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<UploadBloc>().add(UploadEvent.videoPicked(File(path)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('New Video',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            context.read<UploadBloc>().add(const UploadEvent.reset());
            Navigator.of(context).pop();
          },
        ),
      ),
      body: BlocConsumer<UploadBloc, UploadState>(
        listener: (context, state) {
          if (!context.mounted) return;
          state.maybeWhen(
            success: (result) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Video uploaded successfully!'),
                  backgroundColor: AppTheme.primary,
                ),
              );
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => _PickerView(onPick: () => _pickVideo(context)),
            previewing: (file, caption) => _PreviewView(
              file: file,
              captionController: _captionController,
              onCaptionChanged: (v) =>
                  context.read<UploadBloc>().add(UploadEvent.captionChanged(v)),
              onPickAnother: () => _pickVideo(context),
              onSubmit: () =>
                  context.read<UploadBloc>().add(const UploadEvent.submit()),
            ),
            uploading: (file, caption, progress) =>
                _UploadingView(progress: progress),
            success: (result) =>
                const SizedBox.shrink(), // nav handled in listener
            error: (failure, file, caption) => _ErrorView(
              message: failure.when(
                server: (msg, _) => msg,
                network: (msg) => msg,
                cache: (msg) => msg,
                auth: (msg) => msg,
                unknown: (msg) => msg,
              ),
              onRetry: file != null
                  ? () => context
                      .read<UploadBloc>()
                      .add(UploadEvent.videoPicked(file))
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ─── Sub-views ───────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final VoidCallback onPick;
  const _PickerView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.video_library_rounded,
                size: 56, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          const Text('Select a video to upload',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Choose from Gallery'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final File file;
  final TextEditingController captionController;
  final ValueChanged<String> onCaptionChanged;
  final VoidCallback onPickAnother;
  final VoidCallback onSubmit;

  const _PreviewView({
    required this.file,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onPickAnother,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video file info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.path.split('/').last,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ready to upload',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onPickAnother,
                  child: const Text('Change',
                      style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Caption',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: captionController,
            onChanged: onCaptionChanged,
            maxLines: 4,
            maxLength: 300,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write a caption…',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Post Video',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadingView extends StatelessWidget {
  final double progress;
  const _UploadingView({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.surfaceVariant,
                    color: AppTheme.primary,
                  ),
                  Text('$percent%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Uploading your video…',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
