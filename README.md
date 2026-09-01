# HERMES

Sistema de transporte autônomo de materiais desenvolvido para a PUC Minas — Unidade São Gabriel.

## Sobre o Projeto

O HERMES é uma solução desenvolvida para facilitar o transporte de materiais dentro do campus da PUC Minas São Gabriel. Por meio de um aplicativo mobile, usuários podem solicitar materiais à assistência técnica e definir o local onde desejam recebê-los.

Após a solicitação, o robô HERMES realiza o transporte do material até o destino informado. Durante o processo, o usuário poderá acompanhar o status da solicitação e visualizar a localização do robô em tempo real pelo aplicativo.

O projeto busca reduzir o tempo gasto no transporte de ferramentas e materiais, facilitando o acesso aos recursos necessários para aulas e atividades práticas.

## Objetivos

* Facilitar a solicitação de materiais à assistência técnica.
* Automatizar o transporte de materiais dentro do campus.
* Reduzir o tempo de espera para recebimento dos materiais.
* Permitir o acompanhamento do robô em tempo real.
* Centralizar as solicitações de transporte em um único aplicativo.
* Melhorar a organização e o controle das entregas.

## Funcionamento

O funcionamento do sistema segue o seguinte fluxo:

```text
Usuário
   |
   v
Aplicativo HERMES
   |
   | Solicitação de material e destino
   v
Assistência Técnica
   |
   | Material preparado
   v
Robô HERMES
   |
   | Transporte
   v
Local de destino
   |
   v
Usuário
```

O usuário realiza a solicitação pelo aplicativo, selecionando o material desejado e informando o local de entrega. A assistência técnica prepara o material e disponibiliza a solicitação para o robô.

Após iniciar o transporte, o robô se desloca até o destino definido. Durante esse processo, sua localização é atualizada no aplicativo, permitindo que o usuário acompanhe seu deslocamento em tempo real.

## Aplicativo

O aplicativo HERMES é desenvolvido utilizando Flutter e Dart.

Entre as principais funcionalidades previstas estão:

* Solicitação de materiais;
* Seleção do local de entrega;
* Acompanhamento do status da solicitação;
* Visualização da localização do robô em tempo real;
* Acompanhamento do deslocamento do robô;
* Finalização e confirmação da entrega.

## Localização em Tempo Real

Uma das principais funcionalidades do HERMES é o acompanhamento da localização do robô em tempo real.

Durante uma solicitação, o aplicativo apresenta a posição atual do robô e permite que o usuário acompanhe seu deslocamento até o destino.

Essa funcionalidade proporciona maior previsibilidade para o usuário, permitindo que ele saiba onde o robô está e acompanhe a evolução da entrega.

## Arquitetura

O sistema é composto principalmente por três partes:

### Aplicativo Mobile

Responsável pela interface com o usuário, criação e acompanhamento das solicitações e visualização da localização do robô.

### Sistema de Controle e Comunicação

Responsável pela comunicação entre o aplicativo e o robô, transmitindo informações relacionadas às solicitações, destino, status e localização.

### Robô HERMES

Responsável pelo transporte físico dos materiais entre a assistência técnica e o local solicitado pelo usuário.

```text
                 +----------------+
                 |     Usuário    |
                 +-------+--------+
                         |
                         v
                 +----------------+
                 |  App HERMES    |
                 | Flutter / Dart |
                 +-------+--------+
                         |
                         v
                 +----------------+
                 | Comunicação e  |
                 |    Controle     |
                 +-------+--------+
                         |
                         v
                 +----------------+
                 |  Robô HERMES   |
                 +-------+--------+
                         |
                         v
                 +----------------+
                 |     Entrega    |
                 +----------------+
```

## Tecnologias

O aplicativo é desenvolvido utilizando:

* Flutter
* Dart

As tecnologias utilizadas no hardware e na comunicação com o robô serão documentadas conforme a implementação do sistema.

## Estrutura do Projeto

```text
HERMES/
│
├── lib/
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   └── main.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── test/
│
├── pubspec.yaml
└── README.md
```

A estrutura poderá ser modificada conforme a evolução do projeto.

## Execução

### Pré-requisitos

Para executar o aplicativo, é necessário possuir:

* Flutter SDK;
* Dart SDK;
* Android Studio ou ambiente de desenvolvimento compatível;
* Emulador Android ou dispositivo físico.

### Instalação

Clone o repositório:

```bash
git clone <URL_DO_REPOSITORIO>
```

Acesse o diretório do projeto:

```bash
cd HERMES
```

Instale as dependências:

```bash
flutter pub get
```

Execute o aplicativo:

```bash
flutter run
```

## Status do Projeto

Em desenvolvimento.

O projeto está em fase de desenvolvimento, com implementação progressiva do aplicativo, integração com o robô e funcionalidades de localização e acompanhamento em tempo real.

## Contexto Acadêmico

O HERMES é um projeto desenvolvido no contexto acadêmico da PUC Minas — Unidade São Gabriel, com o objetivo de aplicar conhecimentos de desenvolvimento de software, sistemas embarcados, comunicação entre dispositivos e automação na resolução de um problema real do ambiente universitário.

## Equipe

Projeto desenvolvido por alunos da PUC Minas — Unidade São Gabriel.

### Desenvolvimento do Aplicativo

* [Nome do integrante]
* [Nome do integrante]
* [Nome do integrante]

### Desenvolvimento do Robô

* [Nome do integrante]
* [Nome do integrante]
* [Nome do integrante]

## Licença

Este projeto foi desenvolvido para fins acadêmicos no contexto da PUC Minas.
