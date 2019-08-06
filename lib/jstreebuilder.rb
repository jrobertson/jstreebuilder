#!/usr/bin/env ruby

# file: jstreebuilder.rb

require 'nokogiri'
require 'polyrex-xslt'
require 'polyrex'



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

          <span class="caret"><xsl:value-of select='summary/title'/></span>
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


  attr_reader :html, :css, :js

  def initialize(unknown=nil, options={})
    
    if unknown.is_a? String or unknown.is_a? Symbol then
      type = unknown.to_sym
    elsif unknown.is_a? Hash
      options = unknown
    end
    
    @debug = options[:debug]

    @types = %i(tree)
    
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
  

  def tree(opt={})

    tree = opt[:src]  
    
    s = if tree =~ /<tree>/ then
      
      schema = 'entries/entry[title]'
      xslt_schema = 'tree/item[@title:title]'

      # transform the tree xml into a polyrex document
      pxsl = PolyrexXSLT.new(schema: schema, xslt_schema: xslt_schema).to_xslt
      puts 'pxsl: ' + pxsl if @debug
      Rexslt.new(pxsl, tree).to_s
      
    elsif tree =~ /<?polyrex / 
      tree
    end
    
    px = Polyrex.new(s)

    # transform the polyrex xml into a nested HTML list
    #@ul = Rexslt.new(px.to_xml, XSLT).to_xml

    doc   = Nokogiri::XML(px.to_xml)
    xslt  = Nokogiri::XSLT(XSLT)

    @ul = xslt.transform(doc).to_s.lines[1..-1].join

  end

end
