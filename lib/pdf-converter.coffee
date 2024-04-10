path = require 'path'
open = require 'open'
fs = require 'fs'

module.exports =

  convert: ({target}) ->
    convertToPdf target.dataset.path

  convertFromPath: (sourceFilePath) ->
    convertToPdf sourceFilePath

convertToPdf = (sourceFilePath) ->
    cmd = executeAsciiDoctorPdf sourceFilePath
    cmd.stdout.on 'data', (data) ->
      atom.notifications.addInfo 'Export as PDF:', detail: data.toString() or '', dismissable: true
    cmd.stderr.on 'data', (data) ->
      console.error "stderr: #{data}"
      atom.notifications.addError 'Error:', detail: data.toString() or '', dismissable: true

    cmd.on 'close', (code) ->
      basename = path.basename(sourceFilePath, path.extname(sourceFilePath))
      pdfFilePath = path.join(path.dirname(sourceFilePath), basename) + '.pdf'

      if code is 0
        atom.notifications.addSuccess 'Export as PDF completed!', detail: pdfFilePath or '', dismissable: false

        if atom.config.get 'asciidoc-preview.exportAsPdf.openWithExternal'
          open(pdfFilePath).catch (error) ->
            atom.notifications.addError error.toString(), detail: error?.stack or '', dismissable: true
            console.error error
        cleanAsciiDoctorPdf sourceFilePath
      else
        atom.notifications.addWarning 'Export as PDF completed with errors.', detail: pdfFilePath or '', dismissable: false

executeAsciiDoctorPdf = (sourceFilePath) ->
  {spawn} = require 'child_process'

  asciidoctorPdfArguments = makeAsciiDoctorPdfArguments()

  if process.platform is 'win32'
    shell = process.env['SHELL'] or 'cmd.exe'
    spawn 'asciidoctor-pdf.bat', [asciidoctorPdfArguments, "\"#{sourceFilePath}\""], shell: "#{shell}"
  else
    shell = process.env['SHELL'] or 'bash'
    spawn 'asciidoctor-pdf', [asciidoctorPdfArguments, "\"#{sourceFilePath}\""], shell: "#{shell}"

cleanAsciiDoctorPdf = (sourceFilePath) ->
  cdir = path.dirname(sourceFilePath)
  deletePDFTempFiles cdir
  atom.notifications.addSuccess 'Clean temp files success!!!', detail: '', dismissable: false

deletePDFTempFiles = (dirPath) ->
  files = fs.readdirSync(dirPath)
  for file in files
    filePath = path.join(dirPath, file)
    if fs.statSync(filePath).isDirectory()
      if file is '.asciidoctor'
        fs.rmdirSync(filePath, { recursive: true })
    else
      if file.match(/^diag-.*\.(png|svg)$/)
        fs.unlinkSync(filePath)

makeAsciiDoctorPdfArguments = ->
  asciidoctorPdfArguments = []
  asciidoctorPdfArguments.push "-a scripts=cjk"
  asciidoctorPdfArguments.push "-a source-highlighter=rouge"
  asciidoctorPdfArguments.push "-r asciidoctor-diagram"
  asciidoctorPdfArguments.push "-a allow-uri-read"

  asciidoctorPdfStyle = atom.config.get 'asciidoc-preview.exportAsPdf.pdfStyle'
  if asciidoctorPdfStyle isnt ""
    asciidoctorPdfArguments.push "-a pdf-style=\"#{asciidoctorPdfStyle}\""

  asciidoctorPdfStylesDir = atom.config.get 'asciidoc-preview.exportAsPdf.pdfStylesDir'
  if asciidoctorPdfStylesDir isnt ""
    asciidoctorPdfArguments.push "-a pdf-stylesdir=\"#{asciidoctorPdfStylesDir}\""

  asciidoctorPdfFontsDir = atom.config.get 'asciidoc-preview.exportAsPdf.pdfFontsDir'
  if asciidoctorPdfFontsDir isnt ""
    asciidoctorPdfArguments.push "-a pdf-fontsdir=\"#{asciidoctorPdfFontsDir}\""

  asciidoctorPdfAdditionalArguments = atom.config.get 'asciidoc-preview.exportAsPdf.arguments'
  if asciidoctorPdfAdditionalArguments isnt ""
    asciidoctorPdfArguments.push asciidoctorPdfAdditionalArguments

  asciidoctorPdfArguments.join(' ').trim()
