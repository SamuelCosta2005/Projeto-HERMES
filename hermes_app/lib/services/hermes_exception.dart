
/// Erro de regra de negócio do Hermes (estoque, permissão, etc.).
///
/// [identificador] é o código estável que o servidor manda (ex.: "estoque-insuficiente");
/// [codigo] é o código do Firebase (ex.: "failed-precondition").
class HermesException implements Exception {
  final String codigo;
  final String identificador;
  final Map<String, dynamic> detalhes;

  HermesException({
    required this.codigo,
    required this.identificador,
    this.detalhes = const <String, dynamic>{},
  });

  String get mensagem => traduzirErro(identificador, codigo, detalhes);

  @override
  String toString() => 'HermesException($codigo, $identificador)';
}

/// Texto em português para cada erro que a API pode devolver.
String traduzirErro(String id, String codigo, Map<String, dynamic> d) {
  String v(String chave) => '${d[chave] ?? ''}';

  switch (id) {
    case 'estoque-insuficiente':
      return 'Só há ${v('disponivel')} unidade(s) de ${v('item')} disponível(is).';
    case 'item-inativo':
      return 'O item ${v('item')} não está mais disponível.';
    case 'item-de-outra-categoria':
      return 'Os itens do pedido precisam ser da mesma categoria.';
    case 'item-inexistente':
    case 'local-inexistente':
    case 'pedido-inexistente':
    case 'emprestimo-inexistente':
      return 'Registro não encontrado. Atualize a tela e tente de novo.';
    case 'pedido-sem-itens':
      return 'Escolha pelo menos um item.';
    case 'quantidade-invalida':
    case 'inteiro-positivo-obrigatorio':
      return 'Informe uma quantidade válida (maior que zero).';
    case 'inteiro-nao-negativo-obrigatorio':
      return 'Informe um número válido (zero ou mais).';
    case 'itens-demais':
      return 'Há itens demais no pedido (máximo ${v('max')}).';
    case 'campo-obrigatorio':
      return 'Preencha todos os campos obrigatórios.';
    case 'campo-muito-longo':
      return 'Um dos textos está longo demais.';
    case 'pedido-de-outro-usuario':
    case 'emprestimo-de-outro-usuario':
      return 'Você não tem acesso a este registro.';
    case 'pedido-nao-cancelavel':
      return 'Este pedido não pode mais ser cancelado.';
    case 'pedido-nao-chegou':
      return 'O robô ainda não chegou.';
    case 'transicao-invalida':
    case 'status-invalido':
      return 'Esta etapa da entrega não pode ser aplicada agora.';
    case 'emprestimo-nao-esta-em-posse':
      return 'Este item já teve o recolhimento solicitado ou concluído.';
    case 'emprestimo-ja-devolvido':
      return 'Este empréstimo já foi encerrado.';
    case 'devolucao-nao-solicitada':
      return 'O usuário ainda não pediu o recolhimento deste item.';
    case 'devolucao-vazia':
      return 'Informe pelo menos uma unidade recebida.';
    case 'devolucao-maior-que-pendente':
      return 'Foram informadas mais unidades do que as ${v('pendente')} pendentes.';
    case 'baixa-maior-que-disponivel':
      return 'Só dá para dar baixa no que está disponível (${v('disponivel')}).';
    case 'contagem-menor-que-reservas':
      return 'Há ${v('reservadas')} unidade(s) reservada(s) em pedidos ativos; a contagem não pode ser menor que isso.';
    case 'item-em-uso':
      return 'Não dá para mudar "retornável" enquanto há unidades em uso.';
    case 'nada-para-alterar':
      return 'Nada para alterar.';
    case 'estoque-inconsistente':
      return 'Inconsistência de estoque detectada. Avise um administrador.';
    case 'fora-da-vez':
      return 'Ainda não é a vez deste pedido. O robô atende um por vez, na ordem da fila.';
    case 'senha-incorreta':
      return 'Senha incorreta.';
    case 'login-obrigatorio':
      return 'Faça login para continuar.';
    case 'usuario-nao-cadastrado':
      return 'Entre novamente para continuar.';
    case 'usuario-inativo':
      return 'Seu usuário está inativo.';
    case 'sem-acesso-ao-modulo':
    case 'papel-invalido':
      return 'Seu usuário não tem acesso ao Hermes. Procure um administrador.';
    case 'papel-insuficiente':
      return 'Você não tem permissão para esta ação.';
    case 'erro-interno':
      return 'Algo deu errado no servidor. Tente de novo.';
  }

  switch (codigo) {
    case 'unavailable':
    case 'deadline-exceeded':
      return 'Sem conexão com o servidor. Verifique a internet e tente de novo.';
    case 'unauthenticated':
      return 'Faça login para continuar.';
    case 'permission-denied':
      return 'Você não tem permissão para esta ação.';
    case 'not-found':
      return 'Registro não encontrado.';
  }
  return 'Algo deu errado ($codigo). Tente de novo.';
}
