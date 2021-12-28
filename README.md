# Building an HTML tree using the JsTreeBuilder gem

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
        <item title='melon' url='http://a0.jamesrobertson.me.uk'/>
        <item title='cheese burger'/>
        <item title='milk shake'/>
      </item>
      

    </tree>
    "

    ## or

    tree ="
    <?polyrex schema='entries[title]/link[title,url]' delimiter=' # '?>
    title: Links to Foo

    foo bar # http://someexamplewebsite.com/do/fun/rrr
      foo2 # http://someexamplewebsite.com/do/fun2/rrr
      foo3 # http://someexamplewebsite.com/do/fun3/rrr
    doo # http://someexamplewebsite.com/do/dun/eee
    "

    #jtb = JsTreeBuilder.new :tree, {src: tree, debug: true}
    jtb = JsTreeBuilder.new({src: tree, debug: true})
    File.write '/tmp/tree4.html',  jtb.to_webpage
    `firefox /tmp/tree4.html`

## Output

Screenshot as observed from the browser window:

![](http://www.jamesrobertson.me.uk/r/images/2019/sep/15/jstree.png)

jstreebuilder tree
