<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  exclude-result-prefixes="c xs xlink"
  version="2.0">

  <xsl:param name="dest-uri" as="xs:string"/>
  <xsl:variable name="source-uri" as="xs:string" select="/c:directory/@xml:base"/>
  <xsl:variable name="source-uri-length" as="xs:integer" select="string-length($source-uri) + 1"/>

  <xsl:template match="* | @*">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/c:directory">
    <xsl:sequence select="c:determine-action(.)"/>
  </xsl:template>

  <xsl:function name="c:determine-action" as="element(*)*">
    <xsl:param name="elts" as="element(*)*"/>
    <xsl:for-each select="$elts">
      <xsl:variable name="process-subs" as="element(*)*" 
        select="if (self::c:directory) then c:determine-action(*) else *"/>
      <xsl:copy>
        <xsl:attribute name="target-href" select="concat($dest-uri, substring(@xlink:href, $source-uri-length))"/>
        <xsl:choose>
          <xsl:when test="self::c:directory and exists($process-subs/@action)">
            <xsl:attribute name="action" select="'mkdir'"/>
          </xsl:when>
          <xsl:when test="exists(self::c:file[not(@ignore = 'true')]/(article | submission | issue))">
            <xsl:attribute name="action" select="'serialize'"/>
          </xsl:when>
          <xsl:when test="exists(self::c:file[not(@ignore = 'true')])">
            <xsl:attribute name="action" select="'copy'"/>
          </xsl:when>
        </xsl:choose>  
        <xsl:apply-templates select="@*, $process-subs"/>
      </xsl:copy>
    </xsl:for-each>
  </xsl:function>
  
</xsl:stylesheet>