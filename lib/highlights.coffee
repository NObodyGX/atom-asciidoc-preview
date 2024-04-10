# Inspired by https://github.com/atom-haskell/atom-highlights

_ = require 'underscore-plus'

pushScope = (scopeStack, scope, html) ->
  scopeStack.push(scope)
  html += "<span class=\"#{scope.replace(/\.+/g, ' ')}\">"

popScope = (scopeStack, html) ->
  scopeStack.pop()
  html += '</span>'

updateScopeStack = (scopeStack, desiredScopes, html) ->
  excessScopes = scopeStack.length - desiredScopes.length
  if excessScopes > 0
    html = popScope(scopeStack, html) while excessScopes--

  # pop until common prefix
  for i in [scopeStack.length..0]
    break if _.isEqual(scopeStack[0...i], desiredScopes[0...i])
    html = popScope(scopeStack, html)

  # push on top of common prefix until scopeStack is desiredScopes
  for j in [i...desiredScopes.length]
    html = pushScope(scopeStack, desiredScopes[j], html)

  html

module.exports =
  highlightSync = (options = {}) ->
    registry = atom.grammars
    {fileContents, scopeName, lineDivs, editorDiv, wrapCode, editorDivTag, editorDivClass, nullScope} = options
    lineDivs ?= false
    editorDiv ?= false
    wrapCode ?= false
    editorDivTag ?= 'div'
    editorDivClass ?= 'editor editor-colors'
    nullScope ?= 'text.plain.null-grammar'

    grammar = registry.grammarForScopeName(scopeName) ? (registry.grammarForScopeName(nullScope) if nullScope)

    throw new Error("Grammar #{scopeName} not found, and no #{nullScope} grammar") unless grammar?

    lineTokens = grammar.tokenizeLines fileContents

    # Remove trailing newline
    if lineTokens.length > 0
      lastLineTokens = lineTokens[lineTokens.length - 1]

      if lastLineTokens.length is 1 and lastLineTokens[0].value is ''
        lineTokens.pop()

    html = ''
    html = "<#{editorDivTag} class=\"#{editorDivClass}\">" if editorDiv
    html += "<code>" if wrapCode
    scopeStack = []
    for tokens in lineTokens
      html += '<div class="line">' if lineDivs
      {value, scopes} = tokens
      value = ' ' unless value
      scopes = scopes.map (scope) -> "syntax--#{scope.replace(/\./g, '.syntax--')}"
      html = updateScopeStack scopeStack, scopes, html
      value = value.replace(/&/, '&amp;').replace(/</, '&lt;')
      html += "<span>#{value}</span>"
      html = popScope(scopeStack, html) while scopeStack.length > 0
      html += '\n'
      html += '</div>' if lineDivs
    html += "</code>" if wrapCode
    html += "</#{editorDivTag}>" if editorDiv
    html
