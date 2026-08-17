---
layout: post
title: Teste de link
external_url: "https://arthr.dev"
image: 
  path: "https://notetoself.studio/post/best-things-i-watched-listened-to-and-read-in-2025/header-best-of-2025_hu_a909be7a3e61322.JPG"
  alt: "Elefante"
  caption: "O ícone de elefante vem do SerenityOS"
category: links
tags:
  - sites pessoais
  - teste
  - web
---

# Pré-visualização de estilos

Este arquivo reúne os principais elementos de texto usados no blog, para testar a folha de estilos de ponta a ponta.

## Parágrafos

Uma cena de *Cópia Fiel* dura pouco mais de dois minutos e não corta uma vez sequer. É o tipo de decisão que só faz sentido quando se confia inteiramente no espectador — confiança rara, hoje em dia, em qualquer meio.

Já tinha escrito sobre isso antes, num rascunho que nunca publiquei[^rascunho]. Volto ao assunto porque parece que **cada revisão** muda um pouco o que eu penso sobre o filme, e isso talvez seja o ponto: a cópia nunca é igual à anterior[^benjamin].

## Lista não ordenada

Elementos que pretendo revisitar neste ensaio:

- A ambiguidade do casal como estratégia narrativa
- O uso do carro como confessionário móvel
- A luz da Toscana como personagem
  - Comparação com *Viagem à Itália*, de Rossellini
  - Notas soltas sobre Kiarostami e o documentário

## Lista ordenada

Passos para revisar o ensaio antes de publicar:

1. Reler em voz alta
2. Cortar qualquer frase que soe "bonita demais"
3. Verificar as citações
4. Confirmar as fontes das imagens

## Lista de definição

<dl>
  <dt>POSSE</dt>
  <dd>Publish (on your) Own Site, Syndicate Elsewhere — publicar primeiro no próprio domínio e depois replicar em outras redes.</dd>
  <dt>Webmention</dt>
  <dd>Protocolo aberto para notificar que uma página faz referência a outra, base de comentários e respostas descentralizadas.</dd>
  <dt>jf2</dt>
  <dd>Formato JSON simplificado para representar dados de microformats2.</dd>
</dl>

## Tabela

| Formato | Câmera        | Filme          |
| ------- | ------------- | -------------- |
| 35mm    | Yashica MF-1  | Kodak Gold 200 |
| 35mm    | Yashica MF-1  | Ilford HP5+    |
| Digital | —             | —              |

## Figura e imagem

<figure>
  <img src="https://arthr.me/img/exemplo.jpg" alt="Fachada de um cinema de rua em Porto Alegre, à noite, com letreiro luminoso.">
  <figcaption>Cinema Bourbon Country, no bairro Cidade Baixa — uma das últimas salas de rua da cidade.</figcaption>
</figure>

## Bloco de código

Trecho do worker que normaliza respostas do Mastodon e do Bluesky em jf2:

```javascript
export async function toJf2(post, source) {
  return {
    type: 'entry',
    author: source === 'mastodon' ? post.account.acct : post.author.handle,
    published: post.created_at ?? post.indexedAt,
    content: { html: post.content ?? post.record.text },
  };
}
```

{% highlight javascript linenos %}
export async function toJf2(post, source) {
  return {
    type: 'entry',
    author: source === 'mastodon' ? post.account.acct : post.author.handle,
    published: post.created_at ?? post.indexedAt,
    content: { html: post.content ?? post.record.text },
  };
}
{% endhighlight %}

## Código inline

A função `toJf2()` recebe um objeto bruto e devolve algo compatível com o meu renderizador de webmentions.

## Citação em bloco

> A crítica não deveria dizer ao leitor o que sentir diante de uma obra, mas oferecer um vocabulário para que ele descubra o que já sentia.
>
> — anotação de rodapé, sem fonte, provavelmente minha mesma

## Citação inline

Como diria Sontag, <q>a interpretação é a vingança do intelecto sobre a arte</q> — frase que releio sempre que estou prestes a explicar demais um filme que deveria só ser sentido.

## Inserção e remoção

Revisão do parágrafo de abertura: <del>o filme discute o casamento</del> <ins>o filme discute a performance do casamento</ins>, o que muda bastante o argumento do ensaio.

## Marcação (highlight)

Ainda preciso confirmar esta data: a exibição foi em <mark>outubro de 2023</mark>, não em 2022 como eu tinha anotado.

## Notas de rodapé

[^rascunho]: Datado de março de 2022, ainda salvo numa pasta chamada "ideias-soltas".
[^benjamin]: Referência solta a Walter Benjamin, "A obra de arte na era de sua reprodutibilidade técnica" — vale revisar antes de citar de fato.
