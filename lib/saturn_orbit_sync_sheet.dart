import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'saturn_orbit_cloud.dart';

class SaturnOrbitSyncSheet extends StatefulWidget {
  final SaturnOrbitCloud? cloud;

  const SaturnOrbitSyncSheet({super.key, required this.cloud});

  @override
  State<SaturnOrbitSyncSheet> createState() => _SaturnOrbitSyncSheetState();
}

class _SaturnOrbitSyncSheetState extends State<SaturnOrbitSyncSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _partner = TextEditingController();
  bool _running = false;
  String? _message;
  List<String> _orbits = const [];

  @override
  void initState() {
    super.initState();
    if (widget.cloud?.signedIn == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOrbits());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _partner.dispose();
    super.dispose();
  }

  Future<void> _execute(Future<void> Function() action,
      {String? success}) async {
    if (_running) return;
    setState(() {
      _running = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = success);
    } catch (e) {
      if (mounted) {
        setState(() => _message =
            'Não foi possível concluir. Confira o código, a conta '
            'e a conexão com o SATURN Cloud.');
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _refreshOrbits() async {
    final cloud = widget.cloud;
    if (cloud == null || !cloud.signedIn) return;
    await _execute(() async {
      final ids = await cloud.availableOrbits();
      if (!mounted) return;
      setState(() => _orbits = ids);
      if (cloud.orbitId == null && ids.length == 1) {
        await cloud.attach(ids.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.cloud;
    const accent = Color(0xFFC6A477);
    const cream = Color(0xFFF2E8DF);
    // Keep the form inside iOS Safari's visual viewport when its keyboard
    // appears; the long account/partner form stays independently scrollable.
    final screen = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.viewPaddingOf(context);
    final available = (screen.height - keyboard -
        safe.top - safe.bottom - 24).clamp(150.0, screen.height).toDouble();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 8, 14, keyboard),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: available),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.sync_rounded, color: accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Nossa Órbita · Sincronização',
                    style: TextStyle(
                      color: cream, fontSize: 19, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Android e iPhone podem compartilhar avaliações, '
                'Watchlists, livros e Nossa Órbita após conectar '
                'dois logins ao mesmo espaço privado.',
                style: TextStyle(color: Color(0xFFD3C0C7), height: 1.4),
              ),
              const SizedBox(height: 13),
              if (cloud == null)
                const Text(
                  'A sincronização está preparada, mas ainda precisa '
                  'de um projeto Supabase exclusivo do SATURN, '
                  'com Auth e segurança habilitados. Seus dados '
                  'continuam salvos somente neste aparelho.',
                  style: TextStyle(color: Color(0xFFFFD8A4)),
                )
              else if (!cloud.signedIn) ...[
                const Text(
                  'Entre com seu próprio e-mail. Cada pessoa usa '
                  'uma conta, sem compartilhar senhas.',
                  style: TextStyle(color: cream),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Seu e-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: _running
                      ? null
                      : () => _execute(
                          () => cloud.sendEmailCode(_email.text),
                          success: 'Código solicitado. Confira o e-mail.'),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Enviar código de acesso'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código recebido por e-mail',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 9),
                FilledButton.icon(
                  onPressed: _running
                      ? null
                      : () => _execute(() async {
                          await cloud.verifyEmailCode(
                            _email.text, _code.text);
                          final ids = await cloud.availableOrbits();
                          if (!mounted) return;
                          setState(() => _orbits = ids);
                          if (ids.length == 1) await cloud.attach(ids.first);
                        }, success: 'Conta conectada.'),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Entrar na minha conta'),
                ),
              ] else ...[
                const Text('MEU CÓDIGO DE PAREAMENTO',
                  style: TextStyle(
                    color: accent, letterSpacing: 1.5, fontSize: 11),
                ),
                const SizedBox(height: 6),
                SelectableText(cloud.userId ?? '',
                  style: const TextStyle(
                    color: cream, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: cloud.userId ?? ''),
                    );
                    if (mounted) {
                      setState(() => _message = 'Código copiado.');
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar meu código'),
                ),
                const Divider(),
                Text(
                  cloud.connected
                      ? 'Órbita conectada: ${cloud.orbitId}'
                      : 'Ainda sem Órbita selecionada',
                  style: const TextStyle(color: cream, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: _running ? null : _refreshOrbits,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Buscar minhas Órbitas'),
                  ),
                  FilledButton.icon(
                    onPressed: _running
                        ? null
                        : () => _execute(() async {
                            final id = await cloud.createOrbit();
                            if (mounted) setState(() => _orbits = [id]);
                          }, success: 'Nossa Órbita criada.'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Criar Nossa Órbita'),
                  ),
                ]),
                if (_orbits.length > 1) ...[
                  const SizedBox(height: 10),
                  for (final id in _orbits)
                    ListTile(
                      dense: true,
                      title: Text('Órbita ${id.substring(0, 8)}'),
                      trailing: Icon(
                        cloud.orbitId == id
                            ? Icons.check_circle : Icons.link,
                        color: accent,
                      ),
                      onTap: () => _execute(() => cloud.attach(id),
                        success: 'Órbita selecionada.'),
                    ),
                ],
                if (cloud.connected) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'CONECTAR O OUTRO CELULAR',
                    style: TextStyle(
                      color: accent, letterSpacing: 1.5, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sua namorada entra com o e-mail dela no iPhone '
                    'e envia o código dela para você. '
                    'Você autoriza o código abaixo. '
                    'Depois, ela toca em Buscar minhas Órbitas.',
                    style: TextStyle(
                      color: Color(0xFFD3C0C7), fontSize: 12),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _partner,
                    decoration: const InputDecoration(
                      labelText: 'Código da outra pessoa (UUID)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _running
                        ? null
                        : () => _execute(
                            () => cloud.addPartner(_partner.text),
                            success: 'Parceira autorizada.'),
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text('Autorizar parceira'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _running
                        ? null
                        : () => _execute(
                            cloud.syncNow, success: 'Sincronização solicitada.'),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Sincronizar agora'),
                  ),
                  if (cloud.lastSyncedAt != null)
                    Text('Última sincronização: ${cloud.lastSyncedAt}',
                      style: const TextStyle(
                        color: Color(0xFFB9A6B0), fontSize: 11),
                    ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _execute(cloud.signOut,
                      success: 'Sessão encerrada. Os dados locais permanecem.'),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
              ],
              if (_running) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(color: accent),
              ],
              if (_message != null) ...[
                const SizedBox(height: 10),
                Text(_message!, style: const TextStyle(
                    color: Color(0xFFF1D9B6), fontSize: 12)),
              ],
              if (cloud?.lastError != null)
                Text(cloud!.lastError!, style: const TextStyle(
                  color: Color(0xFFFFC0C0), fontSize: 12)),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
