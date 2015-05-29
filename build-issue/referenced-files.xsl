<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="* | @*">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="c:file/@name">
    <xsl:copy/>
    <xsl:attribute name="xlink:href" select="resolve-uri(., base-uri())"/>
  </xsl:template>

  <xsl:template match="c:directory/@xml:base">
    <xsl:copy/>
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>

  <xsl:template match="c:file[article]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="prelim" as="element(*)*">
        <xsl:apply-templates mode="referenced-files"/>
      </xsl:variable>
      <c:refd-files>
        <xsl:for-each-group select="$prelim" group-by="@xlink:href">
          <xsl:sequence select="." />
        </xsl:for-each-group>
      </c:refd-files>
      <xsl:apply-templates mode="#default"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="c:file/submission/ext-id[not(normalize-space())]"/>
  <xsl:template match="c:file/submission/callback[not(normalize-space())]"/>
  <xsl:template match="c:file/submission/callback/email[not(normalize-space())]"/>
  
  <xsl:template match="text()" mode="referenced-files"/>
  
  <xsl:template match="graphic | media | self-uri" mode="referenced-files">
    <xsl:copy>
      <xsl:copy-of select="@content-type"/>
      <xsl:variable name="prefix" as="xs:string?" select="if (self::self-uri) then () else name()"/>
      <xsl:variable name="rel-href" select="string-join(($prefix, @xlink:href), '/')" as="xs:string"/>
      <xsl:attribute name="rel-href" select="$rel-href"/>
      <xsl:attribute name="orig-href" select="@xlink:href"/>
      <xsl:attribute name="xlink:href" select="resolve-uri($rel-href, base-uri())"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>