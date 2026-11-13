# Emplake

Jogo de matemática com placas de carro: use os quatro dígitos da placa, na
ordem, para montar uma igualdade verdadeira. Feito em Flutter (web).

Modos de jogo:

- **Aleatório**: placas sorteadas entre as que o jogador ainda não resolveu,
  em quatro níveis de operadores.
- **Específico**: o jogador digita a placa (o app avisa se não houver solução
  no nível escolhido; placa já resolvida não pontua de novo).
- **Aventura**: sobrevivência com moedas. Começa com 2000 moedas e só
  `+ − × ÷ ( )`; acertos rendem um prêmio que cai com o tempo, erros e pulos
  custam moedas e os operadores avançados são comprados. Acaba quando as
  moedas acabam; o recorde fica salvo na nuvem.

## Como rodar

```bash
flutter pub get
flutter run -d chrome
```

Sem Firebase configurado, dá para ver as páginas internas em modo de
demonstração (usuário e dados falsos):

```bash
flutter run -d chrome -t test/demo_main.dart
```


Na URL do modo demonstração dá para escolher o modo: `?mode=specific`,
`?mode=adventure` ou `?mode=adventure&start=1`.

Testes: `flutter test`.

## Configuração do Firebase (plano Spark)

1. Crie um projeto em <https://console.firebase.google.com>.
2. **Authentication > Método de login**: ative *E-mail/senha* e *Google*.
3. **Firestore Database**: crie o banco e publique as regras de
   `firestore.rules`.
4. Gere `lib/firebase_options.dart` (substitui o arquivo de exemplo):

   ```bash
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=web
   ```

5. Em `lib/core/constants.dart`, preencha `googleWebClientId` (Authentication
   > Google > Configuração do SDK da Web) e os nomes em `groupMembers`.
6. Ao publicar, adicione o domínio do site em **Authentication >
   Configurações > Domínios autorizados**.

## Publicação na web

```bash
flutter build web --release
firebase deploy --only hosting,firestore:rules
```

O `firebase.json` já aponta para `build/web`. A pasta também pode ser
publicada em Netlify, Vercel ou GitHub Pages (as rotas usam `#`, então não é
preciso configurar redirecionamentos).

## Organização do código

| Pasta | Conteúdo |
| --- | --- |
| `lib/game` | Operadores e níveis, analisador/avaliador de expressões, conversão para LaTeX, solver e controladores dos modos (Riverpod) |
| `lib/data` | Leitura e escrita do progresso no Firestore |
| `lib/settings` | Configurações persistidas (tema, fonte, cor, idioma, som) |
| `lib/routing` | Rotas com go_router e retomada da última página |
| `lib/ui` | Login, barra de navegação curva, jogo, progresso, configurações e ajuda |
| `lib/l10n` | Traduções (pt, en, es) com flutter_localizations |
| `lib/audio` | Efeitos sonoros sintetizados (opcionais, desligados por padrão) |
