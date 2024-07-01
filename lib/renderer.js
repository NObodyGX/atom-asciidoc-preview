const path = require('path')
asciidoctorRuntimeConfig = {
  runtime: {
    platform: 'node',
    engine: 'v8',
    framework: 'electron',
  }
}
Asciidoctor = require('@asciidoctor/core')(asciidoctorRuntimeConfig)


exports.renderHtml = async function (text, filePath, grammar, callback) {
  baseDir = path.basename(filePath)
  asciidoctorOptions = {
    base_dir: baseDir,
    safe: true,
    doctype: 'article',
    backend: 'html5',
  }

  doc = Asciidoctor.load(text, asciidoctorOptions);
  html = doc.convert()
  return html
}
