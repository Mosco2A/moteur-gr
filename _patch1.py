
import pathlib

svc_path = pathlib.Path('C:/Users/Christophe/Claude/projets/interne/Moteur-GR/lib/core/services/trail_download_service.dart')
content = svc_path.read_text(encoding='utf-8')

D = chr(36)  # dollar sign
Q = chr(39)  # single quote

# PATCH 1: Add typed_data import
content = content.replace(
    "import 'dart:convert';",
    "import 'dart:convert';
import 'dart:typed_data';",
    1
)

# PATCH 2: Add DownloadProgressCallback + HttpDownloadException before class
old_class_doc = '/// Service de telechargement des donnees sentier depuis Firebase Storage.'
new_block = (
    '/// Callback de progression du telechargement brut (octets).
'
    '///
'
    '/// [bytesDownloaded] octets recus depuis le debut (incluant offset reprise).
'
    '/// [totalBytes] taille totale du fichier (0 si inconnue).
'
    'typedef DownloadProgressCallback = void Function(
'
    '  int bytesDownloaded,
'
    '  int totalBytes,
'
    ');
'
    '
'
    '/// Exception HTTP specifique au telechargement.
'
    '///
'
    '/// Permet de distinguer les erreurs HTTP des autres erreurs
'
    '/// pour un retry cible dans le pipeline de telechargement.
'
    'class HttpDownloadException implements Exception {
'
    '  HttpDownloadException(this.message, this.statusCode);
'
    '  final String message;
'
    '  final int statusCode;
'
    '  @override
'
    '  String toString() => ' + Q + 'HttpDownloadException(' + D + 'statusCode): ' + D + 'message' + Q + ';
'
    '}
'
    '
'
    '/// Service de telechargement des packs sentier depuis Firebase Storage.
'
    '///
'
    '/// Pack sentier = JSON config + GPX + MBTiles.
'
    '/// Supporte la reprise apres interruption via HTTP Range header
'
    '/// et le suivi de progression via callback et Stream<DownloadProgress>.
'
    '///
'
    '/// Reprise a 2 niveaux :
'
    '/// 1. Niveau HTTP : resume byte offset pour fichiers volumineux (GPX, MBTiles)
'
    '/// 2. Niveau insertion : SyncQueue reprend a la derniere etape completee'
)
content = content.replace(old_class_doc, new_block, 1)

print('Patches 1-2 OK')
svc_path.write_text(content, encoding='utf-8')
print(f'Written: {svc_path.stat().st_size} bytes')
