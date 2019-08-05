# Introducing the jstreebuilder gem

## Usage

    require 'jstreebuilder'


    tree = "
    <tree>
      <item title='breakfast'>
        <item title='Corn Flakes'/>
        <item title='coffee'/>
      </item>
      <item title='lunch'>
        <item title='soup'>
          <item title='tomato'/>
          <item title='oxtail'/>
        </item>
        <item title='apple'/>
      </item>
      <item title='mealtime'>
        <item title='melon'/>
        <item title='cheese burger'/>
        <item title='milk shake'/>
      </item>
      

    </tree>
    "

    jtb = JsTreeBuilder.new :tree, {xml: tree, debug: true}
    File.write '/tmp/tree3.html',  jtb.to_webpage
    `firefox /tmp/tree3.html`

## Resources

* jstreebuilder https://rubygems.org/gems/jstreebuilder

jstreebuilder tree html gem builder
