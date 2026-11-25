# Hermes — app Flutter (v2, com Firebase)

App de pedido e controle de materiais entregues pelo robô Hermes. Mantém o visual
do protótipo original (tema escuro ciano / claro laranja, botão de sol e lua em
todas as telas) e agora funciona de verdade, ligado ao Firebase.

O backend (14 Cloud Functions, regras e índices) fica no pacote **hermes_firebase**.
Publique ele primeiro: este app não funciona sem ele.

## Como entra (login simplificado, só para testes)

Sem e-mail, sem cadastro:

- **Entrar** → entra como **cliente**.
- **Sou do suporte técnico** (cadeado) → pede a senha **1234** → entra como **admin**.

Só existem dois papéis. O admin **é** o suporte técnico.

| | Cliente | Admin (suporte técnico) |
|---|:-:|:-:|
| Pedir: materiais → sala → pedido aprovado → fila → mapa → confirmar recebimento | ✅ | ✅ |
| Meus itens: pedidos, empréstimos, pedir recolhimento | ✅ | ✅ |
| Entregas: fila completa, iniciar rota, marcar chegada | | ✅ |
| Empréstimos: receber devolução (bom, danificado, perdido) | | ✅ |
| Estoque: entrada, contagem, baixa | | ✅ |
| Cadastrar/editar/desativar itens, histórico de movimentações | | ✅ |

Por baixo, o app entra como usuário **anônimo** do Firebase e chama a função
`hermesEntrar`; é o **servidor** que confere a senha (trocável pela variável
`HERMES_SENHA_ADMIN`). Quem sai e entra de novo ganha um usuário anônimo novo.
Antes de produção, troque isso por login de verdade.

**Fila privada:** quem espera vê só "3º na fila, 2 pedidos à frente". Código,
destino e itens de outros pedidos nunca chegam ao app.

## Passo a passo

1. **Publique o backend** (pacote `hermes_firebase`, README dele). Se a região das
   funções não for `southamerica-east1`, troque `kRegiaoFunctions` em `lib/config.dart`.
2. **No console do Firebase:** Authentication → Sign-in method → ative **Anônimo**.
3. **Crie o projeto Flutter e copie os arquivos**
   ```bash
   flutter create hermes_app
   ```
   Copie `lib/`, `pubspec.yaml` e `analysis_options.yaml` deste pacote por cima.
4. **Conecte ao Firebase** (mesmo projeto do backend)
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. **Rode**
   ```bash
   flutter pub get
   flutter run
   ```
6. Cadastre itens (entre como admin → Estoque → +) e locais em `locais_eventos`,
   ou use o `seed` do backend.

### Testando no emulador
```bash
flutter run --dart-define=USAR_EMULADOR=true --dart-define=EMULADOR_HOST=10.0.2.2
```
(`10.0.2.2` é o localhost do emulador Android; no simulador iOS use `localhost`.)
O emulador de Auth aceita login anônimo sem configurar nada.

## Estrutura

```
lib/
  main.dart  config.dart  firebase_options.dart
  theme/      cores e textos (claro/escuro), tema
  models/     Pedido, Emprestimo, ItemEstoque, Local, FilaInfo, Movimentacao, Perfil...
  services/   AuthService (entrar anônimo + hermesEntrar), HermesApi (chamadas às funções), Sessao (perfil atual)
  data/       leituras em tempo real do Firestore (itens, pedidos, empréstimos, locais, movimentações)
  utils/      formatadores, ícones, andares, mensagens de erro
  widgets/    componentes (cards, botões, estados, diálogos...)
  screens/
    auth/     login, porteiro (AuthGate), sem acesso
    home_shell.dart        abas por papel
    pedir/    materiais, sala, aprovado, fila, mapa, recebimento
    meus_itens_screen.dart
    equipe/   entregas, empréstimos, devolução, estoque, item, ações, cadastro, movimentações
```

## Premissas (diga se alguma estiver errada)

- **Login simplificado** (anônimo + senha 1234 do admin), só para testes.
- **`locais_eventos` precisa ser legível por usuário logado.** A tela de sala lê essa coleção direto (as regras dela são as que já existem no projeto de vocês).
- **A fila se atualiza sozinha a cada 15 segundos** e quando o status do seu pedido muda.
- **Mapa em tempo real:** continua um espaço reservado ("Mapa não encontrado"), como combinado. A tela mostra o status real e as etapas (Na fila → A caminho → Chegou).
- **Setor do solicitante:** o cadastro de usuários não tem esse campo, então o app não envia setor.
- **Estoque baixo** = disponível abaixo do estoque mínimo do item.

## O que foi verificado — e o que NÃO foi

**Não foi compilado nem executado.** O ambiente onde isto foi escrito não tem o
Flutter SDK, então ninguém rodou `flutter run` nem `flutter analyze` neste código.

O que foi checado por análise estática (fora do Flutter):
- Sintaxe de todos os arquivos `.dart` (parser de Dart), validada antes contra o código do Xeque e do Hermes antigo que já rodam.
- Todo parâmetro nomeado passado às telas/widgets do projeto existe, e nenhum obrigatório falta.
- Todo `Classe.membro` do projeto existe; toda chamada `HermesApi.instance.x` existe; todo import aponta para um arquivo real.
- Nenhum `const` com cor/estilo do tema (que congela a tela na troca de claro/escuro), e nenhuma tela do projeto instanciada como `const`.

Isso pega o erro de digitação, mas **não pega erro de tipo**. Se `flutter run`
reclamar de algo, me mande a mensagem inteira que eu corrijo.

## Se algo der errado

- **"requires an index"** ao abrir uma lista: falta criar um índice do Firestore (ver README do backend, ou use o link que aparece no log).
- **"permission-denied"** nas listas: as regras do backend ainda não foram publicadas, ou o usuário não tem o módulo.
- **"Função não encontrada"**: o backend não foi publicado, ou a região em `config.dart` é diferente da das funções.
- **Erro de `minSdkVersion` no Android**: em `android/app/build.gradle`, ajuste `minSdkVersion` para 23.
- **Conflito de versões do Firebase**: o `pubspec.yaml` usa a família `firebase_core ^3`; não misture com pacotes Firebase da família 4.
