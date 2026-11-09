import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_service.dart';

const _gold = Color(0xFFC6A477);
const _ivory = Color(0xFFF2E8DF);

/// Central de atualizações acessível sem sair do SATURN.
///
/// Até a publicação de releases assinadas no repositório público de downloads,
/// oferece um atalho explícito para o GitHub Actions e informa os limites.
class SaturnUpdateCenter extends StatefulWidget {
  const SaturnUpdateCenter({super.key});

  @override
  State<SaturnUpdateCenter> createState() => _SaturnUpdateCenterState();
}

class _SaturnUpdateCenterState extends State<SaturnUpdateCenter> {
  final SaturnUpdateService _updates = SaturnUpdateService();
  UpdateCheckResult? _result;
  bool _checking = false;
  String _version = '—';
  int _build = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _loadLocalVersion();
    } else {
      _check();
    }
  }

  Future<void> _loadLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _build = int.tryParse(info.buildNumber) ?? 0;
      });
    } catch (_) {
      // Never use the Android feed as an iPhone update source.
    }
  }

  @override
  void dispose() {
    _updates.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final package = await PackageInfo.fromPlatform();
      final build = int.tryParse(package.buildNumber) ?? 0;
      final result = await _updates.check(currentBuild: build);
      if (!mounted) return;
      setState(() {
        _version = package.version;
        _build = build;
        _result = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = const UpdateCheckResult(
          UpdateState.failed,
          'Não foi possível identificar a versão instalada.',
        );
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o navegador.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir esse endereço.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _result?.state == UpdateState.available;
    final release = _result?.release;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final channelMessage = isIos
        ? 'No iPhone, o TestFlight entrega atualizações após o build '
          'ser publicado e seu convite estar ativo. Não é possível '
          'instalar uma atualização Android (APK) no iOS.'
        : _result?.state == UpdateState.available
            ? 'Atualização encontrada no canal SATURN. O arquivo será aberto '
              'no navegador e o Android solicitará sua confirmação.'
            : _result?.state == UpdateState.current
                ? 'O canal de versões SATURN está ativo. '
                  'Não há uma atualização mais recente neste momento.'
                : _result?.state == UpdateState.failed
                    ? 'Não foi possível validar o canal agora. '
                      'As builds experimentais continuam no GitHub Actions.'
                    : 'O canal de atualizações assinadas ainda não tem '
                      'uma release publicada. Use as builds de teste pelo GitHub.';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.system_update_alt_rounded, color: _gold, size: 29),
                SizedBox(width: 11),
                Expanded(child: Text('Atualizar SATURN',
                  style: TextStyle(
                    color: _ivory, fontFamily: 'serif',
                    fontSize: 25, fontWeight: FontWeight.bold,
                  ),
                )),
              ]),
              const SizedBox(height: 15),
              Text('Instalado: versão $_version (build $_build)',
                style: const TextStyle(color: _gold)),
              const SizedBox(height: 8),
              Text(
                isIos
                    ? 'Atualizações do SATURN iOS são distribuídas por '
                      'TestFlight, após convite e publicação da build assinada.'
                    : _checking ? 'Consultando atualizações...' :
                        _result?.message ?? 'Verificando versões...',
                style: const TextStyle(color: _ivory, height: 1.35),
              ),
              if (_checking) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(color: _gold),
              ],
              if (!isIos && available && release != null) ...[
                const SizedBox(height: 14),
                Text('Versão disponível: ${release.version} (build ${release.build})',
                  style: const TextStyle(color: _gold,
                    fontWeight: FontWeight.bold)),
                if (release.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(release.notes,
                    style: const TextStyle(color: _ivory)),
                ],
                const SizedBox(height: 12),
                if (isAndroid)
                  FilledButton.icon(
                    onPressed: () => _open(release.apkUrl),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Baixar APK no navegador'),
                  )
                else
                  const Text(
                    'O arquivo APK é apenas para Android. '
                    'No iPhone, a instalação será feita por TestFlight futuramente.',
                    style: TextStyle(color: _ivory),
                  ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isIos
                      ? () => _open('https://testflight.apple.com/')
                      : _checking ? null : _check,
                  icon: Icon(isIos
                      ? Icons.phone_iphone_rounded
                      : Icons.refresh_rounded),
                  label: Text(
                    isIos ? 'Abrir TestFlight' : 'Verificar novamente'),
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _open(saturnBuildsPage),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir builds de teste no GitHub'),
                ),
              ),
              const Divider(height: 30),
              Text(
                channelMessage,
                style: const TextStyle(color: Color(0xFFD0B8C0),
                  fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Text(
                'A verificação do SHA-256 do arquivo após download e a '
                'instalação automática ainda não estão implementadas. '
                'Não desinstale o aplicativo com notas importantes: '
                'isso pode apagar os dados locais.',
                style: TextStyle(color: Color(0xFFC9AAB2),
                  fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
