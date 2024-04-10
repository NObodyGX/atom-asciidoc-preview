# readme

## you should know

it is a fork of [atom-asciidoc-preview](https://github.com/asciidoctor/atom-asciidoc-preview), which has been archived, and it takes much error in atom editor.

I will continue to maintain this repository according to my own needs. If you have any needs, you are welcomed to create an issue in [repo](https://github.com/NObodyGX/atom-asciidoc-preview/issues)

## usage

```shell
# 1. clone repo
git clone ${REPO} ~/.atom/packages/

# 2. install package
cd ~/.atom/packages/ && npm i

# 3. open atom and enjoy
```

## changlog

1. fix the display issue of codeblock
2. saving as pdf support chinese. due to the issue of generating garbage during the conversion process of asciidoctor-pdf, after the conversion is completed, the `.asciidoctor` folder and image files similar to `diag-*.[png | svg]` under the conversion file directory will be deleted by default.
3. support highlight of codeblock, by using `atom-text-editor` instand of origin codeblock
