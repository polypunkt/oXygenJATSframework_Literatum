<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all"
  version="2.0">
  
  <xsl:output indent="yes"/>

  <xsl:template name="toc">
    <toc>
      <xsl:variable name="sorted-by-fpage" as="element(article)*">
        <xsl:perform-sort select="//article[front/article-meta/article-categories/subj-group[@subj-group-type = 'toc-heading']]">
          <xsl:sort select="front/article-meta/fpage"/>
        </xsl:perform-sort>
      </xsl:variable>
      <xsl:for-each-group select="$sorted-by-fpage" 
        group-adjacent="front/article-meta/article-categories/subj-group[@subj-group-type = 'toc-heading']/subject">
        <issue-subject-group>
          <issue-subject-title>
            <subject>
              <xsl:value-of select="current-grouping-key()"/>
            </subject>
          </issue-subject-title>
          <xsl:apply-templates select="current-group()" mode="toc"/>
        </issue-subject-group>
      </xsl:for-each-group>
    </toc>
  </xsl:template>
  
  <xsl:template match="article" mode="toc">
    <issue-article-meta>
      <xsl:comment select="'fpage', front/article-meta/fpage"/>
      <xsl:copy-of select="front/article-meta/article-id[@pub-id-type = 'doi']"/>  
    </issue-article-meta>
  </xsl:template>

  <xsl:template match="fn" mode="toc"/>
  
</xsl:stylesheet>