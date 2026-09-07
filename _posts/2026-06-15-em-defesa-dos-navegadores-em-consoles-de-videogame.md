---
layout: post
title: Em defesa dos navegadores em consoles de videogame
date: 2026-06-15 16:55 -0300
category: textos
tags:
  - web
  - desenvolvimento
  - hardware
  - consoles
syndication:
  - https://irrelefante.tumblr.com/post/819533560892604416/
redirect_from: /post/819533560892604416/
at_uri: "at://did:plc:5anqf5uonyp67nsex6h55l6p/site.standard.document/3muxb3aldag2e"
---

Por alguma razão misteriosa na forma como eu tropeço em links na internet, eu me deparei com dois links que tocam no assunto ultra-específico de navegadores em consoles de videogame.

O primeiro, é [esse baita trabalho de pesquisa por Declan Chidlow][vale] em documentar a interface desses navegadores, passando por curiosidades como o CD-i e o Apple Pippin até o PlayStation 2 e o Wii — e então pros consoles mais recentes.

Eu sempre gostei do fato do Wii e do 3DS terem navegadores. Eu nunca usei muito eles além da parte em que eles facilitam os hacks para homebrew de ambos os consoles. Porém, eu sempre achei curiosa a forma como a Nintendo e a desenvolvedora responsável por esses navegadores faziam um esforço em usar as capacidades específicas de hardware na navegação. No Wii, era o uso do sensor de movimentos pra controlar o ponteiro; no 3DS, o recurso de duas telas espalhava os controles pela tela de toque enquanto a de cima exibia o conteúdo da página.

Eu me deparei com o segundo link quase que por engano. Em [um artigo][mohkohn] sobre como construir sites principalmente em HTML melhorou as métricas de visitas de um site tem um link para _outro_ artigo sobre a importância da simplicidade no desenvolvimento para a web. É [nesse link](https://shkspr.mobi/blog/2021/01/the-unreasonable-effectiveness-of-simple-html/) que está essa pequena anedota de Terence Eden:

> Há alguns anos, eu estava fazendo pesquisa de políticas públicas em um escritório de auxílio-moradia em Londres. São lugares singularmente desagradáveis. As paredes estão repletas de cartazes oferecendo serviços úteis para pessoas que fogem da violência doméstica. Os seguranças na porta demonstram uma indiferença cautelosa a quem entra. O ar é carregado de conversas tensas entre casais, abafadas pelo barulho de crianças gritando.
> 
> No meio, tem uma jovem sentada em uma cadeira de plástico rígido. Ela está cercada por sacolas contendo seus pertences. Ela não parece estar em um bom momento. Em suas mãos, ela segura um console de videogame – um PlayStation Portable. Ela o encara intensamente, bloqueando o mundo com _Candy Crush_.
> 
> Ou, pelo menos, era o que eu pensava.
> 
> Passando por ela, dou uma olhada em seu console e reconheço a tela em que ela está. Ela está conectada ao Wi-Fi do prédio e navegando nas páginas do [GOV.UK sobre Auxílio-Moradia](https://www.gov.uk/housing-benefit). Ela não está cortando frutas; está se munindo de conhecimento.
> 
> O navegador web do PSP é — para dizer o mínimo — [patético]. É lento, frequentemente fica sem memória e só consegue abrir 3 abas simultaneamente.
> 
> Mas as páginas do GOV.UK são escritas em HTML simples. Elas são projetadas para serem leves e funcionarem até em navegadores ruins. Precisam funcionar. Isso é para todos.

Desenvolvimento para a web pensando nessas situações sempre foi o que me guiou a desenvolver com HTML antes, scripts depois. Eu morei por muito tempo no interior, no meio do campo, sem acesso à infraestrutura de internet de boa qualidade. Existem limites do que essas conexões conseguem oferecer, e é o nosso trabalho como desenvolvedores esquecer que nossos MacBooks conectados à internet de alta velocidade podem fazer, e lembrar de tudo o que um Moto G de 2018 no interior de, sei lá, Minas Gerais, vai conseguir fazer também. _Todo o resto_ de performance a gente pode usar para melhorar uma experiência. Mas ela já tem que ser boa o suficiente pro usuário com o pior hardware possível.

É um pouco do que me faz querer que o nosso _gov.br_ fosse mais pensado para essa parte da população. A infraestrutura do _gov.br_ é pensada para o melhor hardware possível — mas a parcela de quem vai acessar esses serviços usando o iPhone do ano é mínima.

Tudo isso pra dizer que eu lembro de ter feito um sitezinho na aula de programação no segundo ano do ensino médio e ter testado ela usando o navegador do Wii. Foi mágico usar o Wii Remote para apertar em botões que eu mesmo desenvolvi. Até hoje essas pequenas felicidades de programação me impulsionam pra seguir em frente.

[vale]: https://vale.rocks/posts/game-console-browsers
[mohkohn]: https://mohkohn.co.uk/writing/html-first/
