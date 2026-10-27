import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for handling native Android and iOS share sheet intents.
/// Supports sharing actual video files (e.g. to WhatsApp, Instagram, Telegram)
/// and post images/text.
class NativeShareService {
  /// Shares a reel video natively via Android / iOS system share sheet.
  /// If [videoAssetPath] is a Flutter asset, it extracts it to a cache file
  /// and passes it to [Share.shareXFiles] as a video/mp4 MIME type.
  /// This allows WhatsApp, Instagram (Stories/Reels/Chats), Telegram, etc.
  /// to receive the original video media.
  static Future<void> shareReel({
    required String reelId,
    required String videoAssetPath,
    required String caption,
    String? authorUsername,
  }) async {
    try {
      String? localVideoPath;

      if (videoAssetPath.startsWith('assets/')) {
        // Extract asset bytes to a temp file so external apps can access it
        final byteData = await rootBundle.load(videoAssetPath);
        final tempDir = await getTemporaryDirectory();
        final sanitizedId = reelId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final file = File('${tempDir.path}/inno_reel_$sanitizedId.mp4');

        if (!await file.exists() || (await file.length()) != byteData.lengthInBytes) {
          await file.writeAsBytes(
            byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            flush: true,
          );
        }
        localVideoPath = file.path;
      } else if (await File(videoAssetPath).exists()) {
        localVideoPath = videoAssetPath;
      }

      final shareText = caption.isNotEmpty
          ? '$caption\n\nShared via InnoMedia'
          : 'Check out this reel on InnoMedia!';

      if (localVideoPath != null && await File(localVideoPath).exists()) {
        final xFile = XFile(
          localVideoPath,
          mimeType: 'video/mp4',
          name: 'reel_$reelId.mp4',
        );

        await Share.shareXFiles(
          [xFile],
          text: shareText,
          subject: 'Watch this Reel on InnoMedia',
        );
      } else {
        await Share.share(
          shareText,
          subject: 'Watch this Reel on InnoMedia',
        );
      }
    } catch (e) {
      debugPrint('[NativeShareService] shareReel notice: $e');
      try {
        await Share.share(
          caption.isNotEmpty ? '$caption\n\nShared via InnoMedia' : 'Watch this Reel on InnoMedia!',
        );
      } catch (_) {}
    }
  }

  /// Shares a feed post natively with image and text
  static Future<void> sharePost({
    required String postId,
    String? imageUrl,
    required String caption,
    String? authorUsername,
  }) async {
    try {
      final shareText = caption.isNotEmpty
          ? '$caption\n\nShared via InnoMedia'
          : 'Check out this post on InnoMedia!';

      if (imageUrl != null && imageUrl.startsWith('assets/')) {
        final byteData = await rootBundle.load(imageUrl);
        final tempDir = await getTemporaryDirectory();
        final sanitizedId = postId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final file = File('${tempDir.path}/inno_post_$sanitizedId.jpg');
        if (!await file.exists()) {
          await file.writeAsBytes(
            byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            flush: true,
          );
        }
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg', name: 'post_$postId.jpg')],
          text: shareText,
          subject: 'Shared from InnoMedia',
        );
      } else if (imageUrl != null && imageUrl.startsWith('http')) {
        try {
          final request = await HttpClient().getUrl(Uri.parse(imageUrl));
          final response = await request.close();
          if (response.statusCode == 200) {
            final bytes = await consolidateHttpClientResponseBytes(response);
            final tempDir = await getTemporaryDirectory();
            final sanitizedId = postId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
            final file = File('${tempDir.path}/inno_post_$sanitizedId.jpg');
            await file.writeAsBytes(bytes, flush: true);
            await Share.shareXFiles(
              [XFile(file.path, mimeType: 'image/jpeg', name: 'post_$postId.jpg')],
              text: shareText,
              subject: 'Shared from InnoMedia',
            );
            return;
          }
        } catch (_) {}
        await Share.share(
          '$shareText\n$imageUrl',
          subject: 'Shared from InnoMedia',
        );
      } else {
        await Share.share(
          shareText,
          subject: 'Shared from InnoMedia',
        );
      }
    } catch (e) {
      debugPrint('[NativeShareService] sharePost notice: $e');
      try {
        await Share.share(caption.isNotEmpty ? caption : 'Shared from InnoMedia');
      } catch (_) {}
    }
  }
}
