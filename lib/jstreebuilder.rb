#!/usr/bin/env ruby

# file: jstreebuilder.rb

require 'nokogiri'
require 'polyrex-xslt'
require 'polyrex'
require 'kramdown'


XSLT = %q[
<xsl:stylesheet xmlns:xsl='http://www.w3.org/1999/XSL/Transform' version='1.0'>
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />

  <xsl:template match='entries'>

    <xsl:element name='ul'>
      <xsl:attribute name='id'>myUL</xsl:attribute>
      <xsl:apply-templates select='records/entry' />
    </xsl:element>

  </xsl:template>

  <xsl:template match='entry'>

    <xsl:choose>
      <xsl:when test='records/entry'>

        <xsl:element name='li'>

          <xsl:element name='span'>      
            <xsl:attribute name="class">caret</xsl:attribute>
            <xsl:choose>
              <xsl:when test='summary/url != ""'>
              <xsl:element name='a'>
                <xsl:attribute name='href'><xsl:value-of select='summary/url'/></xsl:attribute>
                <xsl:value-of select='summary/title'/>      
              </xsl:element>
              </xsl:when>
              <xsl:otherwise>
            <xsl:value-of select='summary/title'/>      
              </xsl:otherwise>
            </xsl:choose>
          </xsl:element>
          <ul class='nested'>
            <xsl:apply-templates select='records/entry' />
          </ul>
        </xsl:element>

      </xsl:when>
      <xsl:otherwise>
        <xsl:element name='li'>      
          <xsl:choose>
            <xsl:when test='summary/url != ""'>
            <xsl:element name='a'>
              <xsl:attribute name='href'><xsl:value-of select='summary/url'/></xsl:attribute>
              <xsl:value-of select='summary/title'/>      
            </xsl:element>
            </xsl:when>
            <xsl:otherwise>
          <xsl:value-of select='summary/title'/>      
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:otherwise>
      </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
]


class JsTreeBuilder
  using ColouredText

TREE_CSS = %q[
/* Remove default bullets */
ul, #myUL {
  list-style-type: none;
}

/* Remove margins and padding from the parent ul */
#myUL {
  margin: 0;
  padding: 0;
}

/* Style the caret/arrow */
.caret {
  cursor: pointer; 
  user-select: none; /* Prevent text selection */
}

/* Create the caret/arrow with a unicode, and style it */
.caret::before {
  content: "\25B6";
  color: black;
  display: inline-block;
  margin-right: 6px;
}

/* Rotate the caret/arrow icon when clicked on (using JavaScript) */
.caret-down::before {
  transform: rotate(90deg); 
}

/* Hide the nested list */
.nested {
  display: none;
}

/* Show the nested list when the user clicks on the caret/arrow (with JavaScript) */
.active {
  display: block;
}
]

SIDEBAR_CSS = TREE_CSS + %q[
  
body {
  font-family: "Lato", sans-serif;
}

.sidenav {
  width: 25%;
  position: fixed;
  z-index: 1;
  top: 20px;
  left: 10px;
  background: #eee;
  overflow-x: hidden;
  padding: 12px 0;
}

.sidenav a {
  padding: 2px 8px 2px 6px;
  text-decoration: none;
  font-size: 23px;
  color: #2166F3;

}

.sidenav a:hover {
  color: #064579;
}

.main {
  margin-left: 25%; /* Same width as the sidebar + left position in px */
  font-size: 26px; /* Increased text to enable scrolling */
  padding: 0px 10px;
}

@media screen and (max-height: 450px) {
  .sidenav {padding-top: 15px;}
  .sidenav a {font-size: 19 px;}
}
]

TREE_JS =<<EOF
var toggler = document.getElementsByClassName("caret");
var i;

for (i = 0; i < toggler.length; i++) {
  toggler[i].addEventListener("click", function() {
    this.parentElement.querySelector(".nested").classList.toggle("active");
    this.classList.toggle("caret-down");
  });
}
EOF

SIDEBAR_JS = TREE_JS

  class TreeBuilder
    using ColouredText

    attr_reader :to_tree

    def initialize(s, debug: false)

      @debug = debug
      html = Kramdown::Document.new(s).to_html
      puts ('html: ' + html.inspect) if @debug
      a = scan_headings(html)
      puts ('a: ' + a.inspect) if @debug
      
      s2 = make_tree(a)
      puts ('s2: ' + s2.inspect) if @debug
      tree = LineTree.new(s2).to_tree
      
      puts ('tree: ' + tree.inspect).debug if @debug
      
      doc = Rexle.new(tree)
      doc.root.each_recursive do |node|
        
        h = node.attributes        
        puts ('h: ' + h.inspect).debug if @debug
        h[:url] = '#' + h[:title].strip.downcase.gsub(' ', '-')
        
      end
      puts ('doc.xml: ' + doc.xml.inspect) if @debug
      
      @to_tree = doc.xml pretty: true

    end
    
    def make_tree(a, indent=0, hn=1)
      
      if @debug then
        puts 'inside make_tree'.debug 
        puts ('a: ' + a.inspect).debug
      end
      
      a.map.with_index do |x, i|
        
        puts ('x: ' + x.inspect).debug if @debug
        
        if x.is_a? Array then

          puts 'before make_tree()'.info if @debug
          
          make_tree(x, indent+1, hn)

        else

          next unless x =~ /<h[#{hn}-4]/
          space = i == 0 ? indent-1 : indent
          heading = ('  ' * space) + x[/(?<=\>)[^<]+/]
          puts ('heading: ' + heading.inspect).debug if @debug
          heading

        end

      end.compact.join("\n")

    end    

    def scan_headings(s, n=1)
      
      s.split(/(?=<h#{n})/).map do |x| 
        x.include?('<h' + (n+1).to_s) ? scan_headings(x, n+1) : x
      end

    end

  end


  attr_reader :html, :css, :js

  def initialize(unknown=nil, options={})
    
    if unknown.is_a? String or unknown.is_a? Symbol then
      type = unknown.to_sym
    elsif unknown.is_a? Hash
      options = {type: :tree}.merge(unknown)
      type = options[:type]
    end
    
    @debug = options[:debug]

    @types = %i(tree sidebar)
    
    build(type, options) if type

  end
  
  def to_css()
    @css
  end
  
  def to_html()
    @html
  end
  
  def to_js()
    @js
  end
  
  def to_ul()
    @ul
  end
  
  def to_webpage()

    a = RexleBuilder.build do |xml|
      xml.html do 
        xml.head do
          xml.meta name: "viewport", content: \
              "width=device-width, initial-scale=1"
          xml.style "\nbody {font-family: Arial;}\n\n" + @css
        end
        xml.body @ul
      end
    end

    doc = Rexle.new(a)    
    
    doc.root.element('body').add \
        Rexle::Element.new('script').add_text "\n" + 
        @js.gsub(/^ +\/\/[^\n]+\n/,'')
    
    "<!DOCTYPE html>\n" + doc.xml(pretty: true, declaration: false)\
        .gsub(/<\/div>/,'\0' + "\n").gsub(/\n *<!--[^>]+>/,'')
    
  end
  
  def to_xml()
    @xml
  end
  
  
  private
  
  def build(type, options)
    
    puts 'inside build'.info if @debug
    puts "type: %s\noptions: %s".debug % [type, options] if @debug    
    
    return unless @types.include? type.to_sym
    
    s = method(type.to_sym).call(options)
    
    @html = s.gsub(/<\/div>/,'\0' + "\n").strip.lines[1..-2]\
      .map {|x| x.sub(/^  /,'') }.join
    
    @css = Object.const_get 'JsTreeBuilder::' + type.to_s.upcase + '_CSS'
    @js = Object.const_get 'JsTreeBuilder::' + type.to_s.upcase + '_JS'        
  
  end
  
  def build_px(tree)
    
    schema = 'entries/entry[title, url]'
    xslt_schema = 'tree/item[@title:title, @url:url]'

    # transform the tree xml into a polyrex document
    pxsl = PolyrexXSLT.new(schema: schema, xslt_schema: xslt_schema).to_xslt
    puts 'pxsl: ' + pxsl if @debug
    Rexslt.new(pxsl, tree).to_s    
    
  end
  

  def tree(opt={})

    src = opt[:src]  
    
    s = if src =~ /<tree>/ then
      
      build_px(src)
      
    elsif src =~ /<?polyrex / 
      src
    else
      build_px(TreeBuilder.new(src, debug: @debug).to_tree)
    end
    
    puts ('s: ' + s.inspect).debug if @debug
    px = Polyrex.new(s)

    # transform the polyrex xml into a nested HTML list
    #@ul = Rexslt.new(px.to_xml, XSLT).to_xml
    puts ('px: ' + px.inspect).debug if @debug
    puts ('px.to_xml: ' + px.to_xml.inspect).debug if @debug
    doc   = Nokogiri::XML(px.to_xml)
    xslt  = Nokogiri::XSLT(XSLT)

    @ul = xslt.transform(doc).to_s.lines[1..-1].join

  end
  
  def sidebar(opt={})
    doc = Rexle.new(tree(opt))
    doc.root.attributes[:class] = 'sidenav'
    @ul = doc.xml(declaration: false)
  end

end
