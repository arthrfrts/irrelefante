---
layout: note
title: Bibliotecas de filmes e séries
tags: biblioteca
---

As bibliotecas de filmes e séries sofriam com uma desorganização imensa. Não em catalogação, mas em formato. Filmes estavam em MP4, MKV e até mesmo AVI. Alguns possuíam legendas externas, em outros as legendas estavam dessincronizadas. Atualmente, eu tô organizando e padronizando esse armazenamento para ser compatível com o Compartilhamento de Mídia do macOS através do aplicativo TV. Isso significa que:

1. Eles precisam estar em contêineres MP4 ou M4V.
2. Eles precisam ser codificados em H.264 ou HEVC.
3. Legendas precisam ser embutidas e localizadas — com idioma e região especificados.
4. Arquivos precisam ser reorganizados através de metadados.

Esse tem sido um processo longo que eu quero documentar aqui. Em geral, ele funciona assim atualmente:

### Localização e correção de legendas

Eu procuro legendas no [Legendas.TV](http://legendas.tv) (preferencialmente) ou no OpenSubtitles.

Quando encontro, eu corrijo e sincronizo a legenda, se necessário. Eu uso um editor de texto normal para a correção de strings, mas uso o site [subsyncer](https://subsyncer.com) para ressincronizar elas. Eu defino o tempo necessário para ressincronizar usando o recurso de atraso de legendas do player [IINA](https://iina.io).

### Remux dos arquivos-fonte

É necessário adicionar a faixa de legenda SRT nos arquivos MKV ou MP4 através de ferramentas como [MKVToolNix](https://mkvtoolnix.download) (MKV) e [Subler](https://subler.org) (MP4).

Para resultados melhores, eu removo todas as legendas que não são substrings (em MKV é possível adicionar legendas como arquivos bitmap, rips de blu-ray e DVD geralmente usam esse formato) para não causar resultados indesejados na conversão.

### Conversão para MP4

Se os arquivos-fonte já estão codificados em H.264/HEVC e AAC/AC3, só é preciso converter o container de MKV para MP4. Eu uso o comando `convert-video` do [Don Melton](https://github.com/donmelton/video_transcoding), que é uma suíte de comandos pré-definidos e otimizados através do HandBrake e do `ffmpeg`.

```bash
convert-video --no-double "fonte.mkv"
```

Se o MKV fonte for um vídeo H.264 com faixa de som AAC ou AC3, está tudo pronto para a importação na biblioteca.

Se o MKV fonte for um vídeo HEVC (H.265), o cabeçalho do arquivo não é reconhecido pelo QuickTime e, assim, não é compatível pela biblioteca de vídeos do app TV. Esse é um ajuste pequeno e, pra isso, eu posso usar o `ffmpeg` para corrigir o cabeçalho:

```bash
ffmpeg -i "arquivo.mp4" -map 0 -c:v copy -tag:v hvc1 -c:a copy -c:s copy "arquivo-corrigido.mp4"
```

Se os arquivos-fonte estão codificados em outros codecs de áudio e vídeo, eu uso o comando `transcode-video` (da mesma suíte de comandos do Don Melton) para criar uma versão com a codificação válida. Essa transcodificação remove qualidade do arquivo final, então eu prefiro sempre fazer isso como um último recurso. Como eu não entendo muito de transcodificação, eu opto por seguir os padrões oferecidos pelo `transcode-video`.

O comando geralmente é esse:

```bash
transcode-video --no-auto-burn --add-subtitle por --encoder x265 --target big --audio-format surround=aac --mp4 "fonte.mkv"
```

Esse comando cria um arquivo MP4 com vídeo HEVC e som AAC (surround por padrão, mas estéreo ou monoaural dependendo da fonte) a partir do MKV. Esse arquivo final segue todas as definições aceitas pelo QuickTime, então é só importá-los no app TV.

### Edição de metadados

Quando a biblioteca de mídias era apenas um HD externo organizado através de pastas por nome do diretor ou ano eu nunca me importei muito com nomes de arquivos ou outras informações dos títulos, principalmente porque não existia uma interface de navegação além do Finder para acessá-los. Agora que eles existirão na biblioteca do app TV, e poderão ser acessados através do AirPlay pelo meu iPhone e na TV, eu preciso adicionar metadados em cada título manualmente.

Eu não encontrei uma ferramenta que eu possa indicar o arquivo e o nome da obra e ele adicione esses metadados automaticamente. Pelo menos o app TV possui uma interface de edição desses metadados, com campos diferentes para cada tipo de mídia. Filmes possuem o título, nome do diretor, elenco, etc., enquanto episódios de séries exibem temporada, número do episódio, data de exibição, e assim por diante. É um processo maçante, mas eu gosto de fazer isso quando estou com um tempo livre.
