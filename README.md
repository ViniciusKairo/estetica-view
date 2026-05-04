# Estética View

Aplicativo mobile desenvolvido em Flutter com integração ao Supabase, criado como parte de um Trabalho de Conclusão de Curso. O sistema tem como objetivo auxiliar no controle de procedimentos estéticos, gerenciamento de usuários e controle seguro de acesso a imagens relacionadas aos procedimentos realizados.

## Sobre o Projeto

O Estética View foi desenvolvido para atender três perfis principais de usuários:

- Administrador
- Médico
- Paciente

Cada perfil possui permissões específicas dentro do sistema, garantindo que cada usuário tenha acesso apenas às funcionalidades e informações compatíveis com sua função.

O projeto utiliza autenticação, banco de dados, armazenamento de imagens e regras de segurança por meio do Supabase, buscando organizar o fluxo de cadastro, realização de procedimentos, solicitação de acesso a imagens e aprovação dessas solicitações.

## Principais Funcionalidades

### Administrador

- Cadastro e gerenciamento de administradores
- Cadastro e gerenciamento de médicos
- Cadastro e gerenciamento de pacientes
- Cadastro e gerenciamento de tipos de procedimentos
- Visualização e controle de procedimentos realizados
- Aprovação e revogação de acesso às imagens dos procedimentos
- Visualização de logs e registros de auditoria
- Controle de usuários ativos e inativos

### Médico

- Cadastro e gerenciamento de pacientes vinculados
- Cadastro e gerenciamento de tipos de procedimentos
- Registro de procedimentos realizados
- Inclusão de imagens dos procedimentos
- Aprovação ou revogação de solicitações de acesso às imagens
- Visualização apenas dos procedimentos relacionados ao próprio médico

### Paciente

- Visualização dos próprios procedimentos
- Solicitação de acesso às imagens dos procedimentos realizados
- Visualização das imagens após aprovação
- Acompanhamento do status das solicitações

## Tecnologias Utilizadas

- Flutter
- Dart
- Supabase
- Supabase Auth
- Supabase Database
- Supabase Storage
- Supabase Edge Functions
- Riverpod
- GoRouter
- Android

## Estrutura Geral do Sistema

O sistema foi estruturado com separação de responsabilidades entre telas, controladores, serviços, modelos e rotas. A aplicação utiliza controle de estado para gerenciar autenticação, permissões e carregamento de dados.

A navegação é baseada no perfil do usuário autenticado, direcionando automaticamente cada usuário para sua respectiva área do sistema.

## Banco de Dados

O banco de dados foi criado no Supabase com tabelas relacionadas a:

- Perfis de usuários
- Administradores
- Médicos
- Pacientes
- Relacionamento entre médicos e pacientes
- Tipos de procedimentos
- Procedimentos realizados
- Imagens dos procedimentos
- Solicitações de acesso às imagens
- Logs de auditoria

Foram aplicadas políticas de segurança utilizando Row Level Security, garantindo que os dados sejam acessados apenas por usuários autorizados.

## Segurança

O projeto utiliza mecanismos de segurança fornecidos pelo Supabase, incluindo:

- Autenticação de usuários
- Controle de permissões por perfil
- Row Level Security nas tabelas
- Políticas de acesso por usuário autenticado
- Controle de usuários ativos e inativos
- Registro de ações em logs de auditoria
- Armazenamento seguro de imagens
- Controle de aprovação para acesso às imagens dos pacientes

O acesso às imagens dos procedimentos depende de aprovação realizada por um administrador ou pelo médico responsável.

## Fluxo Básico do Sistema

1. O usuário realiza login no aplicativo.
2. O sistema identifica o perfil do usuário.
3. O usuário é redirecionado para a área correspondente.
4. Administradores e médicos podem cadastrar e gerenciar dados conforme suas permissões.
5. Procedimentos realizados podem receber imagens.
6. Pacientes podem solicitar acesso às imagens dos seus procedimentos.
7. Administradores ou médicos aprovam ou recusam essas solicitações.
8. Após aprovação, o paciente consegue visualizar as imagens permitidas.

## Instalação e Execução

### Pré-requisitos

Antes de executar o projeto, é necessário ter instalado:

- Flutter SDK
- Dart
- Android Studio ou Visual Studio Code
- Emulador Android ou dispositivo físico
- Conta e projeto configurado no Supabase