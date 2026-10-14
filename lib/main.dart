import 'package:flutter/material.dart';

void main() {
  runApp(const SessaoApp());
}

class SessaoApp extends StatelessWidget {
  const SessaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaInicio(),
    );
  }
}

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  final List<Map<String, Object>> _sessoes = [];
  int _proximoId = 1;

  String resumoSessao() {
    return 'Sessões nesta execução: ${_sessoes.length}';
  }

  Future<void> abrirFormulario({Map<String, Object>? sessao}) async {
    final resultado = await Navigator.push<Map<String, Object>>(
      context,
      MaterialPageRoute(builder: (context) => TelaFormulario(sessao: sessao)),
    );

    if (!mounted || resultado == null) {
      return;
    }

    setState(() {
      if (sessao == null) {
        resultado['id'] = _proximoId++;
        _sessoes.add(resultado);
      } else {
        final index = _sessoes.indexWhere((item) => item['id'] == sessao['id']);

        if (index != -1) {
          _sessoes[index] = resultado;
        }
      }
    });
  }

  Future<void> excluirSessao(Map<String, Object> sessao) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir sessão?'),
        content: Text('Excluir "${sessao['tema']}" (ID ${sessao['id']})?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop<bool>(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop<bool>(dialogContext, true);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (!mounted || confirmou != true) {
      return;
    }

    setState(() {
      _sessoes.removeWhere((item) => item['id'] == sessao['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas sessões')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(resumoSessao()),
            ),
            Expanded(
              child: _sessoes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma sessão. Toque em Cadastrar para começar.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sessoes.length,
                      itemBuilder: (context, index) {
                        final sessao = _sessoes[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${sessao['id']}'),
                                  ),
                                  title: Text(sessao['tema'] as String),
                                  subtitle: Text(
                                    '${sessao['minutos']} minutos\n'
                                    '${(sessao['observacao'] as String).isEmpty ? "Sem observação" : sessao['observacao']}',
                                  ),
                                ),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        abrirFormulario(sessao: sessao);
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Editar'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        excluirSessao(sessao);
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        tooltip: 'Nova sessão',
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
    );
  }
}

class TelaFormulario extends StatefulWidget {
  final Map<String, Object>? sessao;

  const TelaFormulario({super.key, this.sessao});

  @override
  State<TelaFormulario> createState() => _TelaFormularioState();
}

class _TelaFormularioState extends State<TelaFormulario> {
  final _formKey = GlobalKey<FormState>();
  final _temaController = TextEditingController();
  final _minutosController = TextEditingController();
  final _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final sessao = widget.sessao;

    if (sessao != null) {
      _temaController.text = sessao['tema'] as String;
      _minutosController.text = (sessao['minutos'] as int).toString();
      _observacaoController.text = sessao['observacao'] as String;
    }
  }

  @override
  void dispose() {
    _temaController.dispose();
    _minutosController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void confirmar() {
    final valido = _formKey.currentState?.validate() ?? false;

    if (!valido) {
      return;
    }

    final minutos = int.tryParse(_minutosController.text.trim());

    if (minutos == null) {
      return;
    }

    final sessao = <String, Object>{
      'id': widget.sessao?['id'] ?? 0,
      'tema': _temaController.text.trim(),
      'minutos': minutos,
      'observacao': _observacaoController.text.trim(),
    };

    Navigator.pop<Map<String, Object>>(context, sessao);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessao == null ? 'Nova sessão' : 'Editar sessão'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Planeje uma sessão de estudo.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _temaController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o tema do estudo.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tema do estudo',
                    hintText: 'Ex.: Revisar Form e validação',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minutosController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final texto = (value ?? '').trim();

                    if (texto.isEmpty) {
                      return 'Informe a duração.';
                    }

                    final minutos = int.tryParse(texto);

                    if (minutos == null) {
                      return 'Digite um número inteiro de minutos.';
                    }

                    if (minutos < 1 || minutos > 240) {
                      return 'Use uma duração de 1 a 240 minutos.';
                    }

                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Duração em minutos',
                    hintText: 'De 1 a 240',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observacaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: Resolver os exemplos da aula',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: confirmar,
                  child: const Text('Confirmar sessão'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
