TemplateHelper = require './template-helper'


BasicHtmlTemplate = """
<div>
  <h1>HELLO WORLD</h1>
</div>
"""


class NvimElement extends HTMLElement

  basicTemplate: TemplateHelper.create(BasicHtmlTemplate)

  constructor: ->

  initialize: ->
    @renderPromise = @render().catch (e) ->
      console.error e.message
      console.error e.stack


  render: ->
    @classList.add ""

    @innerHTML = basicTemplate
