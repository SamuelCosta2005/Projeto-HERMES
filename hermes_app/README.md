# Hermes App (Flutter)

App de solicitação e rastreio de entregas feitas pelo robô Hermes, seguindo o fluxo:

**Materiais requisitados → Seleção de sala → Aprovação do pedido → Posição na fila → Localização em tempo real → Confirmação de recebimento**

## ⚠️ Antes de rodar

Este pacote contém a pasta `lib/` completa e o `pubspec.yaml`, mas **não inclui as pastas nativas** (`android/`, `ios/`, `web/` etc.), pois elas precisam ser geradas pelo próprio Flutter SDK na sua máquina (não tenho acesso ao SDK neste ambiente para gerá-las).

### Passo a passo

1. Crie um projeto Flutter novo e vazio:
   ```bash
   flutter create hermes_app
   ```
2. Copie o conteúdo deste pacote **por cima** do projeto criado:
   - Substitua a pasta `lib/` inteira pela `lib/` deste pacote.
   - Substitua o `pubspec.yaml` pelo deste pacote (ou apenas confira se as dependências batem).
   - Copie o `analysis_options.yaml` também (opcional, só regras de lint).
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Rode o app:
   ```bash
   flutter run
   ```

## Estrutura do projeto

```
lib/
  main.dart                     # Ponto de entrada
  theme/                        # Cores, textos e ThemeData centralizados
  models/                       # Modelos de dados (item, sala, pedido, fila, rastreio)
  data/                         # Repositórios (interface abstrata + implementação mock)
  widgets/                      # Componentes reutilizados entre telas
  screens/
    materials_screen.dart          # Tela 1 - Materiais requisitados
    select_room_screen.dart        # Tela 2 - Seleção de sala
    order_approved_screen.dart     # Tela 3 - Pedido aprovado
    queue_screen.dart              # Tela 4 - Posição na fila
    tracking_screen.dart           # Tela 5 - Localização em tempo real
    delivery_complete_screen.dart  # Tela 6 - Confirmação de recebimento
```

## Decisões técnicas (conforme combinado)

- **Gerenciamento de estado:** `setState` nativo. Cada tela é um `StatefulWidget` e os dados
  são passados para a próxima tela via construtor, na medida em que o fluxo avança
  (`Navigator.push`).
- **Dados:** cada fonte de dado (estoque, salas, pedidos, fila, rastreio) tem uma
  **interface abstrata** (`InventoryRepository`, `RoomRepository`, `OrderRepository`,
  `QueueRepository`, `TrackingRepository`) e hoje só existe a implementação `Mock*`
  (dados fixos/simulados com pequeno delay, como se fosse uma chamada de rede).
  Quando houver uma API real, basta criar, por exemplo, `ApiInventoryRepository
  implements InventoryRepository` e trocar a instância usada na tela — nenhuma tela
  precisa ser alterada.
- **Tela 5 (Localização em tempo real):** conforme pedido, a área do mapa é apenas
  um placeholder ("Mapa não encontrado"), pronta para ser substituída depois por uma
  integração de mapa real. O card de status abaixo do mapa (robô, ETA, progresso)
  já é funcional e vem do `TrackingRepository`.
- **Reset do fluxo:** ao confirmar o recebimento na Tela 6, a pilha de navegação é
  limpa (`pushAndRemoveUntil`) e o app volta para a Tela 1 já com as quantidades
  zeradas.

## Fluxo de navegação

```
MaterialsScreen
   │  (categoria + itens selecionados)
   ▼
SelectRoomScreen
   │  (sala escolhida -> gera pedido)
   ▼
OrderApprovedScreen
   │
   ▼
QueueScreen
   │
   ▼
TrackingScreen
   │
   ▼
DeliveryCompleteScreen
   │  (confirmar recebimento -> reinicia o fluxo)
   ▼
MaterialsScreen (novo estado limpo)
```
