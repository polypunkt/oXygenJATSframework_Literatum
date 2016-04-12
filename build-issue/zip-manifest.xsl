<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns="http://www.w3.org/ns/xproc-step"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="/">
    <c:zip-manifest>
      <xsl:variable name="prelim" as="element(c:entry)*">
        <xsl:apply-templates mode="zip"/>  
      </xsl:variable>
      <xsl:sequence select="reverse($prelim)"/>
    </c:zip-manifest>
  </xsl:template>
  
  <xsl:template match="text()" mode="zip"/>
  
  <xsl:template match="c:file[@action]" mode="zip">
    <c:entry href="{@target-href}" name="{string-join(ancestor-or-self::*[position() lt last()]/@name, '/')}"/>
    <xsl:apply-templates select="c:file[@action]" mode="#current"></xsl:apply-templates>    
  </xsl:template>
  
</xsl:stylesheet>