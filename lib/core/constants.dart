/// Integrantes do grupo, mostrados na página de login.
const List<String> groupMembers = [
  'André Esteves',
  // TODO: preencher com o nome do(a) segundo(a) integrante do grupo.
  'Segundo integrante',
];

/// ID do cliente OAuth "Web" do projeto Firebase (Authentication > Método de
/// login > Google > Configuração do SDK da Web). No navegador o login com
/// Google funciona via pop-up do Firebase mesmo sem ele, mas o valor é
/// necessário em outras plataformas.
const String googleWebClientId =
    'SEU_CLIENT_ID.apps.googleusercontent.com';

/// Largura a partir da qual o jogo usa o layout de duas colunas.
const double wideLayoutBreakpoint = 900;

/// Largura máxima do conteúdo das páginas em telas grandes.
const double maxContentWidth = 1100;
