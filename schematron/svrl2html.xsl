<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0"
  exclude-result-prefixes="svrl s xs html"
  >

  <xsl:template match="/" mode="#default">
    <xsl:variable name="doc-uri" select="distinct-values(//svrl:active-pattern/@document)"/>

    <xsl:variable name="content" as="element(html:tr)*">
      <xsl:variable name="msgs" as="element(*)*" select="collection()//svrl:failed-assert | collection()//svrl:successful-report"/>
      <xsl:if test="$msgs">
        <xsl:for-each-group select="$msgs" group-by="preceding-sibling::svrl:active-pattern[1]/@id">
          <xsl:variable name="active-pattern" select="//svrl:active-pattern[@id = current-grouping-key()]" as="node()"/>
          <xsl:for-each select="current-group()">
            <tr xmlns="http://www.w3.org/1999/xhtml" id="{generate-id()}">
              <xsl:if test="position() = 1">
                <xsl:attribute name="class" select="'sep'" />
              </xsl:if>
              <td xmlns="http://www.w3.org/1999/xhtml" class="pattern-id">
                <xsl:value-of select="$active-pattern/@id" />
              </td>
              <td xmlns="http://www.w3.org/1999/xhtml" class="path">
                <xsl:if test="not(matches($active-pattern/@document, '\.xpl$'))">
                  <p>
                    <a href="{$active-pattern/@document}">
                      <xsl:value-of select="replace($active-pattern/@document, '^.+/', '')"/>
                    </a>
                  </p>
                </xsl:if>
                <p><xsl:value-of select="@location"/></p>
                <p><xsl:value-of select="@test"/></p>
              </td>
              <td xmlns="http://www.w3.org/1999/xhtml" class="impact {(@role, 'error')[1]}">
                <xsl:value-of select="(@role, 'error')[1]"/>
              </td>
              <td xmlns="http://www.w3.org/1999/xhtml" class="message">
                <xsl:apply-templates select="svrl:text" mode="#current"/>
              </td>
            </tr>
          </xsl:for-each>
        </xsl:for-each-group>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="ok" as="element(html:tr)+">
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td class="Status" colspan="4"><p class="ok">Ok</p></td>
      </tr>
    </xsl:variable>

    <xsl:variable name="zip" as="element(html:p)">
      <xsl:choose>
        <xsl:when test="collection()[2]/c:zipfile">
          <xsl:variable name="highest-impact" as="xs:string*">
            <xsl:for-each-group select="$content/html:td[contains(@class, 'impact')]" group-by="@class">
              <xsl:sort select="html:impact-sortkey(.)" data-type="number" order="descending"/>
              <xsl:sequence select="replace(@class, '\s*impact\s*', '')"/>
            </xsl:for-each-group>
          </xsl:variable>
          <p xmlns="http://www.w3.org/1999/xhtml" class="{$highest-impact[1]}">
            <xsl:text>Result: </xsl:text>
            <a>
              <xsl:copy-of select="collection()[2]/c:zipfile/@href"/>
              <xsl:value-of select="replace(collection()[2]/c:zipfile/@href, '^.+/', '')"/>
            </a>
          </p>
        </xsl:when>
        <xsl:otherwise>
          <p xmlns="http://www.w3.org/1999/xhtml" class="fatal">
            <xsl:value-of select="collection()[2]"/>
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="output-table">
      <xsl:with-param name="validated-doc-uri" select="$doc-uri" />
      <xsl:with-param name="pre" select="$zip"/>
      <xsl:with-param name="content" select="if ($content) then $content else $ok" />
    </xsl:call-template>
  </xsl:template>

  <xsl:function name="html:impact-sortkey" as="xs:integer">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="class" select="if($elt/@class) then replace($elt/@class, '\s*impact\s*', '') else ''"/>
    <xsl:choose>
      <xsl:when test="$class = 'fatal'">
        <xsl:sequence select="4"/>
      </xsl:when>
      <xsl:when test="$class = 'error'">
        <xsl:sequence select="3"/>
      </xsl:when>
      <xsl:when test="$class = 'warning'">
        <xsl:sequence select="2"/>
      </xsl:when>
      <xsl:when test="$class = 'info'">
        <xsl:sequence select="1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:template name="statistics">
    <xsl:param name="content" as="element(html:tr)*"/>
    <xsl:param name="td-class" as="xs:string"/>
    <xsl:for-each-group select="$content" group-by="html:td[@class eq $td-class]">
      <xsl:sort select="count(current-group())" order="descending"/>
      <tr xmlns="http://www.w3.org/1999/xhtml">
        <td xmlns="http://www.w3.org/1999/xhtml">
          <xsl:value-of select="current-grouping-key()"/>
        </td>
        <td xmlns="http://www.w3.org/1999/xhtml">
          <a xmlns="http://www.w3.org/1999/xhtml" href="{concat('by-', $td-class)}.html#{current-group()[1]/@id}">
            <xsl:value-of select="count(current-group())"/>
          </a>
        </td>
      </tr>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="output-table">
    <xsl:param name="validated-doc-uri" as="xs:string"/>
    <xsl:param name="pre" as="element(*)*"/>
    <xsl:param name="content" as="element(html:tr)*"/>
    <xsl:if test="$content">
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head xmlns="http://www.w3.org/1999/xhtml">
          <meta charset="UTF-8"/>
          <title xmlns="http://www.w3.org/1999/xhtml"></title>
          <style type="text/css">
            td { vertical-align: top; }
            td p { margin: 0 }
            td.path p { margin-bottom: 0.5em; }
            .ok { background-color: #6d6; }
            .info { background-color: #ddd; }
            .warning { background-color: #ed3; }
            .error { background-color: #f66; }
            .fatal { background-color: #f39; }
          </style>
        </head>
        <body xmlns="http://www.w3.org/1999/xhtml">
          <xsl:sequence select="$pre"/>
          <table xmlns="http://www.w3.org/1999/xhtml" border="1" valign="top">
            <tr xmlns="http://www.w3.org/1999/xhtml">
              <th xmlns="http://www.w3.org/1999/xhtml">pattern-id</th>
              <th xmlns="http://www.w3.org/1999/xhtml">path / test</th>
              <th xmlns="http://www.w3.org/1999/xhtml">severity</th>
              <th xmlns="http://www.w3.org/1999/xhtml">message</th>
            </tr>
            <xsl:sequence select="$content"/>
          </table>
        </body>
      </html>
    </xsl:if>
  </xsl:template>

  <xsl:variable name="block-names" as="xs:string+" select="('dl', 'div', 'ol', 'ul', 'c:errors')"/>

  <xsl:template match="svrl:schematron-output/svrl:text" mode="#default">
    <xsl:for-each-group select="node()" group-adjacent="name() = $block-names">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:apply-templates select="current-group()" mode="#current" />
        </xsl:when>
        <xsl:otherwise>
          <p>
            <xsl:apply-templates select="current-group()" mode="#current" />
          </p>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="c:errors" mode="#default">
    <dl class="errors">
      <xsl:apply-templates mode="#current"/>
    </dl>
  </xsl:template>

  <xsl:template match="c:error" mode="#default">
    <dt>
      <xsl:value-of select="@code"/>
    </dt>
    <dd>
      <xsl:apply-templates select="@line, node()" mode="#current"/>
    </dd>
  </xsl:template>

  <xsl:template match="s:emph" mode="#default">
    <em xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="#current" />
    </em>
  </xsl:template>

  <xsl:template match="* | @*" mode="#default">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>