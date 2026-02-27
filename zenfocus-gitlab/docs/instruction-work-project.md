Trabalho 1 (único) - Pipeline de uma Aplicação Web
Objetivo: Mostrar sua habilidade em montar um ambiente completo de construção, teste e implantação de uma aplicação web. Do código-fonte à execução em produção!

Enunciado: Personalize uma aplicação web CRUD para uma empresa fictícia. Hospede o código em um repositório Git, crie um pipeline de construção, teste e implantação. Depois, grave um vídeo explicando tudo e mostrando os Jobs rodando até a aplicação estar no ar.

Passo I) Personalize a sua Aplicação Web CRUD
Encontre uma aplicação web CRUD na internet. Você pode usar qualquer uma, desde que respeite os termos e direitos autorais de quem a disponibilizou. Deixe o projeto privado e dê o seu toque!

REQ01: Crie um nome fictício para a sua empresa. Seja criativo para não ter nome repetido.

REQ02: Crie um logotipo. Ele precisa aparecer em todas as páginas da sua aplicação.

REQ03: Escolha um domínio (DNS) para a empresa, ex.: empresatal.com.br. Ele será o endereço da sua aplicação.

REQ04: A aplicação deve ser somente CRUD. Nada de módulos extras.

REQ05: A aplicação deve ter apenas uma tabela, com 3 a 10 campos (colunas).

REQ06: Embora trabalhemos com PHP, outras linguagens são permitidas, desde que o frontend seja HTML/CSS para navegadores.

REQ07: Nada de frameworks, a menos que você consulte o professor antes.

REQ08: Trabalharemos com MySQL/MariaDB, mas pode usar outros bancos acessíveis pela rede (nada de arquivos de texto ou SQLite).

Passo II) Prepare uma Topologia
Para seu pipeline rodar, você vai precisar de uma topologia de servidores. Escolha a que mais se encaixa com seus recursos:

REQ09: Prepare a sua topologia. Sugestões:

Mínima: 1 cliente, 1 servidor (DNS, CA, WEB) e 1 servidor (GitLab, Runner).

Ideal: 1 cliente, 1 servidor (DNS, CA), 1 servidor (GitLab), 1 servidor (Runner) e 1 servidor WEB.

Completa: uma máquina virtual para cada serviço, se tiver recursos suficientes.

Passo III) Prepare o Ambiente
Instale os servidores e a máquina cliente para o Pipeline de uma Aplicação Web.

REQ10: Configure um servidor DNS para *.empresatal.com.br.

REQ11: Prepare uma autoridade certificadora e gere certificados para *.empresatal.com.br.

REQ12: Instale o GitLab, dê um FQDN (ex.: gitlab.empresatal.com.br) e instale os certificados.

REQ13: Instale um runner, dê um FQDN (ex.: runner.empresatal.com.br) e instale os certificados.

REQ14: Prepare o servidor web para a aplicação em produção, dê um FQDN (ex.: www.empresatal.com.br) e instale os certificados.

REQ15: Prepare a máquina cliente: instale e configure o Git e os certificados.

Passo IV) Crie e Execute um Pipeline no GitLab
REQ16: Hospede sua aplicação em um projeto/repositório do GitLab.

REQ17: Crie um pipeline simples: no mínimo 2 etapas e 1 Job por etapa. Sugestão de Pipeline:

Build (construir/preparar requisitos no servidor)

Test (testar algo na aplicação)

Deploy (subir a aplicação para o servidor web)

REQ18: A etapa de testes deve ter, no mínimo, um Job que realmente teste algo na aplicação.

REQ19: A etapa de deploy precisa ter um Job que suba a aplicação com sucesso para produção.

Passo V) Implemente um Diferencial
Inove! Implemente algo a mais na esteira/pipeline. Pode ser um job diferente, uma nova etapa, ou até um serviço CI/CD local (não usar GitHub Actions, pois é tema de outra disciplina). Seja criativo, pesquise e surpreenda. Se for quebrar algum requisito, fale com o professor antes!

Passo VI) Prepare o Ambiente de Demonstração
Crie um cenário claro para o seu vídeo.

REQ20: Pense no DevOps, no cliente usando a aplicação e no público que assiste.

Sugestão: Em um cenário, mostre o pipeline capturando um erro. Depois, resolva o problema e apresente um pipeline completo e bem-sucedido.

REQ21: Deixe a gravação nítida. Aumente as fontes de editores, navegadores e terminais se for preciso.

Passo VII) Grave o seu Vídeo Explicativo
REQ22: Grave seu rosto quando estiver explicando.

REQ23: Grave sua voz nitidamente.

REQ24: O vídeo deve ter entre 7 e 12 minutos. Não acelere o vídeo!

Passo VIII) Poste o seu Vídeo
REQ25: Use um link do Youtube (não listado) ou do Google Drive. Dê permissão de acesso para hermanopereira@professores.utfpr.edu.br.

REQ26: ATENÇÃO: Não envie link quebrado, encurtado, sem permissão, incompleto, corrompido ou de uma pasta do Drive. O trabalho será zerado. Verifique e teste antes!

REQ27: Não poste como rascunho no Moodle. Poste completamente o seu trabalho.

Avaliação
CRIT01: Atendimento aos requisitos do enunciado.

CRIT02: Originalidade. Foi você quem fez e funcionou? Ótimo!

CRIT03: Competência. Mostre que você realmente entendeu o que fez.

CRIT04: Diferencial. Demonstre que você foi além do básico.

Pontuação: CRIT01, CRIT02 e CRIT03 valem 7 pontos. CRIT04 (passo V) vale 3 pontos. Totalizando 10 pontos.

Dicas do Professor
1) Leia o enunciado: Por favor, leia o enunciado com atenção. Muitos trabalhos bons não recebem nota total por não cumprirem todos os requisitos.

2) Apresentação é chave: O vídeo com seu rosto e sua voz nítida é essencial. É a forma de eu ter certeza de que você fez e sabe o que está falando.

3) Foco no projeto: Não precisa dar uma aula sobre o que é DNS, WEB ou MySQL. Apenas apresente seu projeto. Mostre como você hospedou a aplicação, as ferramentas usadas e configurações importantes. Por exemplo: mostre um erro/bug detectado pelo pipeline, corrija e mostre a nova execução do pipeline resultando em sucesso.

4) Estratégia de apresentação: Alguns alunos apresentaram o trabalho requisito por requisito, o que é uma boa estratégia se você tiver dificuldades. Mas sinta-se à vontade para desenvolver sua própria forma.

5) Seja direto: Otimize sua apresentação para ser certeiro. O importante é o espectador entender seu projeto, sem precisar de detalhes maçantes.

6) Destaque seu diferencial: Explique bem o que torna seu trabalho único. Qual foi a melhoria ou a ideia diferente que você teve em relação ao que foi visto em aula?

7) Comece cedo: Comece o trabalho com no mínimo um mês de antecedência. Isso evita correria e garante a qualidade.