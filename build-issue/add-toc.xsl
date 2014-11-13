<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="@* | *" mode="#default">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="/issue-xml">
    <xsl:copy>
      <xsl:apply-templates select="@*, * except toc"/>
      <toc>
        <xsl:apply-templates select="collection()[position() gt 1]" mode="toc"/>
      </toc>
    </xsl:copy>
    <xsl:variable name="issue-doi" as="xs:string" select="issue-meta/issue-id"/>
    <xsl:result-document href="zip-manifest.xml">
      <zip-manifest xmlns="http://www.w3.org/ns/xproc-step">
        <entry name="{concat($issue-doi, '/issue-files/', $issue-doi, '.xml')}" 
          href="{concat(base-uri(), '.tmp')}" />
        <xsl:apply-templates select="collection()[position() gt 1]" mode="zip">
          <xsl:with-param name="base-dir" select="concat($issue-doi, '/')"/>
        </xsl:apply-templates>
      </zip-manifest>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="/article" mode="toc">
    <xsl:apply-templates select="front/article-meta/title-group/article-title" mode="toc"/>
  </xsl:template>

  <xsl:template match="article-title" mode="toc">
    <p>
      <xsl:apply-templates mode="#current"/>
    </p>
  </xsl:template>
  
  <xsl:template match="fn" mode="toc"/>
  
  <xsl:template match="/article" mode="zip">
    <xsl:param name="base-dir" as="xs:string"/>
    <entry xmlns="http://www.w3.org/ns/xproc-step" href="{base-uri()}"
      name="{concat($base-dir, replace(replace(front/article-meta/article-id[@pub-id-type='doi'], '^[^/]+/', ''), '[/;:]', '_'), replace(base-uri(), '^.+/', '/'))}"/>    
  </xsl:template>
  
</xsl:stylesheet>