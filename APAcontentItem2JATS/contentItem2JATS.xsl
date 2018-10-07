<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:my="urn:x-my"
  xmlns:saxon="http://saxon.sf.net/"
  exclude-result-prefixes="xs my saxon"
  version="2.0">
  
  <xsl:output method="xml" 
    doctype-public="-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.0 20120330//EN"
    doctype-system="JATS-1.0/JATS-archivearticle1.dtd"
    use-character-maps="validify"/><!-- indent="yes" saxon:suppress-indentation="p title label alt-text private-char"  -->
  
  <xsl:character-map name="validify">
    <xsl:output-character character="" string="&#x2019;"/>
  </xsl:character-map>
  
  <xsl:template match="/" mode="#default">
<!--    <xsl:processing-instruction name="xml-model">href="http://jats.nlm.nih.gov/archiving/1.0/JATS-archivearticle1.dtd" type="application/xml-dtd"</xsl:processing-instruction>-->
    <xsl:processing-instruction name="xml-model">href="http://hogrefe.com/JATS/schematron/literatum_JATS.sch" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
    <xsl:text>&#xa;</xsl:text>    
    <xsl:apply-templates mode="contentItem2JATS"/>
  </xsl:template>
  
  <xsl:template mode="contentItem2JATS contentItem2JATS_anchor" match="@* | *">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- default: rename camelCase elements to hyphenated -->
  <xsl:template match="*[matches(name(), '^\p{Ll}+\p{Lu}\p{Ll}+$')]" mode="contentItem2JATS contentItem2JATS_anchor" priority="-0.25">
    <xsl:element name="{lower-case(replace(name(), '^(\p{Ll}+)(\p{Lu}\p{Ll}+)$', concat('$1', '-', '$2')))}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="contentItem[@contentItemType = 'article']" mode="contentItem2JATS">
    <article dtd-version="1.0">
      <xsl:namespace name="mml">http://www.w3.org/1998/Math/MathML</xsl:namespace>
      <xsl:namespace name="xlink">http://www.w3.org/1999/xlink</xsl:namespace>
      <xsl:sequence select="my:language2lang(.)"/>
      <xsl:apply-templates select="@* except (@contentItemType, @language), node()" mode="#current"/>
    </article>
  </xsl:template>

  <xsl:template match="@language" mode="contentItem2JATS">
    <xsl:sequence select="my:language2lang(..)"/>
  </xsl:template>
  
  <xsl:function name="my:language2lang" as="attribute(xml:lang)?">
    <xsl:param name="elt" as="element(*)?"/>
    <xsl:choose>
      <xsl:when test="not($elt/@language)"/>
      <xsl:when test="($elt/ancestor::*/@language)[last()] = $elt/@language"/>
      <xsl:when test="$elt/@language = 'inherit'"/>
      <xsl:when test="$elt/@language = 'english'">
        <xsl:attribute name="xml:lang" select="'en'"/>
      </xsl:when>
      <xsl:when test="$elt/@language = 'german'">
        <xsl:attribute name="xml:lang" select="'de'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="my:language2lang(($elt//*[@language])[1])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  

  <xsl:template match="frontMatter" mode="contentItem2JATS">
    <front>
      <xsl:apply-templates select="@*, journalMeta, itemMeta, itemMeta/bios" mode="#current"/>
    </front>
  </xsl:template>
  
  <xsl:template match="journalMeta" mode="contentItem2JATS">
    <journal-meta>
      <xsl:variable name="known-elts" select="journalTitle, issn, eISSN, publisherName" as="element(*)*"/>
      <xsl:apply-templates select="@*, $known-elts, * except $known-elts" mode="#current"/>
    </journal-meta>
  </xsl:template>
  
  <xsl:template match="journalTitle" mode="contentItem2JATS">
    <journal-title-group>
      <journal-title>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </journal-title>
    </journal-title-group>
  </xsl:template>

  <xsl:template match="issn" mode="contentItem2JATS">
    <issn>
      <xsl:if test="../eISSN">
        <xsl:attribute name="pub-type" select="'ppub'"/>
      </xsl:if>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </issn>
  </xsl:template>
  
  <xsl:template match="eISSN" mode="contentItem2JATS">
    <issn pub-type="epub">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </issn>
  </xsl:template>
  
  <xsl:template match="journalMeta/publisherName" mode="contentItem2JATS">
    <publisher>
      <publisher-name>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </publisher-name>
    </publisher>
  </xsl:template>

  <xsl:template match="itemMeta" mode="contentItem2JATS">
    <article-meta>
      <xsl:variable name="known-elts1" select="apaID, doi, piCN, categories, titleGroup, authorGroup" as="element(*)*"/>
      <xsl:variable name="known-elts2" select="firstPage, lastPage, supplementaryMaterial, history, copyright, abs" as="element(*)*"/>
      <xsl:apply-templates select="@*, $known-elts1" mode="#current"/>
      <xsl:if test="corr">
        <author-notes>
          <xsl:apply-templates select="corr" mode="contentItem2JATS"/>
        </author-notes>    
      </xsl:if>
      <xsl:apply-templates select="@*, $known-elts2" mode="#current"/>
      <xsl:if test="keyWord | keyPhrase">
        <xsl:for-each-group select="keyWord | keyPhrase" group-by="@language">
          <kwd-group>
            <xsl:apply-templates select="@language, current-group()" mode="contentItem2JATS"/>
          </kwd-group>
        </xsl:for-each-group>
        <xsl:if test="keyPhrase">
          <xsl:processing-instruction name="mapping-question">both keyPhrase and keyWord are converted to kwd </xsl:processing-instruction>
        </xsl:if>
      </xsl:if>
      <xsl:apply-templates select="* except (keyWord, keyPhrase, $known-elts1, corr, $known-elts2, bios)" mode="#current"/>
    </article-meta>
  </xsl:template>

  <xsl:template match="keyWord | keyPhrase" mode="contentItem2JATS">
    <kwd>
      <xsl:apply-templates select="@* except @language, node()" mode="#current"/>
    </kwd>
  </xsl:template>

  <xsl:template match="apaID" mode="contentItem2JATS">
    <article-id pub-id-type="apa">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:processing-instruction name="mapping-question">pub-id-type="apa" ok? 'apa' not among the recommended values on http://jatspan.org/niso/archiving-1.0/#p=attr-pub-id-type </xsl:processing-instruction>
    </article-id>
  </xsl:template>
  
  <xsl:template match="doi" mode="contentItem2JATS">
    <article-id pub-id-type="doi">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </article-id>
  </xsl:template>
  
  <xsl:template match="piCN[not(node())]" mode="contentItem2JATS">
    <xsl:processing-instruction name="mapping-question">An empty piCN element was dropped. </xsl:processing-instruction>
  </xsl:template>
  
  <xsl:template match="categories" mode="contentItem2JATS">
    <article-categories>
      <xsl:variable name="known-elts" select="contentType, tocTitle" as="element(*)*"/>
      <xsl:apply-templates select="@*, $known-elts, * except $known-elts" mode="#current"/>
    </article-categories>
  </xsl:template>
  
  <xsl:template match="contentType[not(node()) or . = 'article']" mode="contentItem2JATS"/>
  
  <xsl:template match="tocTitle" mode="contentItem2JATS">
    <subj-group subj-group-type="heading">
      <subject>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </subject>
    </subj-group>
  </xsl:template>
  
  <xsl:template match="titleGroup" mode="contentItem2JATS">
    <title-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>  
    </title-group>
  </xsl:template>

  <xsl:template match="titleGroup/title" mode="contentItem2JATS">
    <article-title>
      <xsl:apply-templates select="@*, node()" mode="#current"/>  
    </article-title>
  </xsl:template>
  
  <xsl:template match="subtitle" mode="contentItem2JATS">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>  
    </xsl:element>
  </xsl:template>

  <xsl:template match="firstPage" mode="contentItem2JATS">
    <fpage>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </fpage>
  </xsl:template>
  
  <xsl:template match="lastPage" mode="contentItem2JATS">
    <lpage>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </lpage>
  </xsl:template>

  <xsl:template match="corr" mode="contentItem2JATS">
    <corresp>
      <xsl:apply-templates select="@*, *" mode="#current"/>
    </corresp>
  </xsl:template>
  
  <xsl:template match="corr/address" mode="contentItem2JATS">
    <xsl:apply-templates select="* | text()[normalize-space()]" mode="#current"/>
  </xsl:template>

  <xsl:template match="addressLine" mode="contentItem2JATS">
    <addr-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </addr-line>
  </xsl:template>
  
  <xsl:template match="extLink[@extLinkType = 'email']" mode="contentItem2JATS">
    <email>
      <xsl:apply-templates select="@link"/>
      <xsl:processing-instruction name="mapping-question">There are also ext-link (which resembles the original extLink) and uri that could be used here.
Attributes not converted: everything except @link, for ex. @status="live" </xsl:processing-instruction>
    </email>
  </xsl:template>
  
  <xsl:template match="extLink[@extLinkType = 'url']" mode="contentItem2JATS">
    <ext-link ext-link-type="uri">
      <xsl:apply-templates select="@* except @extLinkType, node()" mode="#current"/>
    </ext-link>
  </xsl:template>
  
  <xsl:template match="extLink/@status[. = 'live']" mode="contentItem2JATS"/>
  
  <xsl:template match="extLink[@extLinkType = 'email']/@link" mode="contentItem2JATS">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="supplementaryMaterial//extLink[@extLinkType = 'file']" mode="contentItem2JATS">
    <inline-supplementary-material>
      <xsl:apply-templates select="@* except @extLinkType, node()" mode="#current"/>
    </inline-supplementary-material>
  </xsl:template>
  
  <xsl:template match="suppText" mode="contentItem2JATS">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="@link" mode="contentItem2JATS">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>

  <xsl:template match="altText//*" mode="contentItem2JATS" priority="2">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="authorGroup" mode="contentItem2JATS">
    <contrib-group>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </contrib-group>
  </xsl:template>
  
  <xsl:template match="author" mode="contentItem2JATS">
    <contrib contrib-type="author">
      <xsl:apply-templates select="@rid" mode="#current"/>
      <string-name>
        <xsl:apply-templates select="@* except @rid, node()" mode="#current"/>  
      </string-name>
    </contrib>
  </xsl:template>

  <xsl:template match="givenNames" mode="contentItem2JATS">
    <given-names>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </given-names>
  </xsl:template>
  
  <xsl:template match="surname" mode="contentItem2JATS">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="location" mode="contentItem2JATS">
    <addr-line>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </addr-line>
  </xsl:template>
  
  <xsl:template match="copyright" mode="contentItem2JATS">
    <permissions>
      <xsl:variable name="known" as="element(*)*" select="copyrightStatus, copyrightDate[year], copyrightHolder"/>
      <xsl:apply-templates select="@*, $known, * except $known" mode="#current"/>
    </permissions>
  </xsl:template>
  
  <xsl:template match="copyrightDate" mode="contentItem2JATS">
    <xsl:variable name="known" as="element(*)*" select="year"/>
    <copyright-year>
      <xsl:apply-templates select="@*, $known/node(), * except $known" mode="#current"/>
    </copyright-year>
  </xsl:template>
  
  <xsl:template match="copyrightHolder" mode="contentItem2JATS">
    <copyright-holder>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </copyright-holder>
  </xsl:template>

  <xsl:template match="acceptDate" mode="contentItem2JATS">
    <xsl:call-template name="date">
      <xsl:with-param name="type" select="'accepted'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="submissionDate" mode="contentItem2JATS">
    <xsl:call-template name="date">
      <xsl:with-param name="type" select="'received'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="date">
    <xsl:param name="type" as="xs:string"/>
    <date date-type="{$type}">
      <xsl:apply-templates select="day, month, year" mode="#current"/>
      <xsl:if test="text()[normalize-space()]">
        <string-date>
          <xsl:value-of select="normalize-space()"/>
        </string-date>
      </xsl:if>
    </date>
  </xsl:template>

  <xsl:template match="month" mode="contentItem2JATS">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="@* except @number" mode="#current"/>
      <xsl:value-of select="if (@number) then @number else ."/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="abs" mode="contentItem2JATS">
    <abstract>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </abstract>
  </xsl:template>

  <xsl:template match="copyrightStatus" mode="contentItem2JATS">
    <xsl:processing-instruction name="mapping-question">copyrightStatus not available in JATS </xsl:processing-instruction>
  </xsl:template>

  <xsl:template match="inlineGraphic" mode="contentItem2JATS">
    <inline-graphic>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </inline-graphic>
  </xsl:template>
  
  <xsl:template match="no" mode="contentItem2JATS">
    <label>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </label>
  </xsl:template>

  <xsl:template match="sp" mode="contentItem2JATS">
    <p>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </p>
  </xsl:template>

  <xsl:template match="p/@align[. = 'left']" mode="contentItem2JATS"/>

  <xsl:key name="by-id" match="*[@id]" use="@id"/>

  <xsl:template match="anchor" mode="contentItem2JATS">
    <xsl:apply-templates select="key('by-id', @rid)" mode="contentItem2JATS_anchor">
      <xsl:with-param name="anchor" select="."/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="figureReference" mode="contentItem2JATS">
    <xref ref-type="fig">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="equationReference" mode="contentItem2JATS">
    <xref ref-type="disp-formula">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="appendixReference" mode="contentItem2JATS">
    <xref ref-type="app">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="tableReference" mode="contentItem2JATS">
    <xref ref-type="table">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="footnoteReference" mode="contentItem2JATS">
    <xsl:apply-templates select="key('by-id', @rid)" mode="contentItem2JATS_anchor">
      <xsl:with-param name="anchor" select="."/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="footnote" mode="contentItem2JATS_anchor">
    <fn>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </fn>
  </xsl:template>

  <xsl:template match="citationReference" mode="contentItem2JATS">
    <xref ref-type="bibr">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xref>
  </xsl:template>
  
  <xsl:template match="citation" mode="contentItem2JATS">
    <ref>
      <xsl:apply-templates select="@id" mode="#current"/>  
      <mixed-citation>
        <xsl:apply-templates select="@* except @id, node()" mode="#current"/>  
      </mixed-citation>
    </ref>
  </xsl:template>
  
  <xsl:template match="@referenceType" mode="contentItem2JATS">
    <xsl:attribute name="publication-type" select="."/>
  </xsl:template>
  
  <xsl:template match="authorList" mode="contentItem2JATS">
    <person-group person-group-type="author">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </person-group>
  </xsl:template>
  
  <xsl:template match="group" mode="contentItem2JATS">
    <collab>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </collab>
  </xsl:template>
  
  <xsl:template match="person" mode="contentItem2JATS">
    <string-name>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </string-name>
  </xsl:template>
  
  <xsl:template match="publisherLocation" mode="contentItem2JATS">
    <publisher-loc>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </publisher-loc>
  </xsl:template>
  
  <xsl:template match="citation/@meta[. = 'no']" mode="contentItem2JATS"/>

  <xsl:template match="unpublished" mode="contentItem2JATS">
    <date-in-citation content-type="unpublished">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:processing-instruction name="mapping-question">Was: unpublished. Correctly mapped</xsl:processing-instruction>
    </date-in-citation>
  </xsl:template>

  <xsl:template match="characterGraphic" mode="contentItem2JATS">
    <private-char>
      <inline-graphic>
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </inline-graphic>
    </private-char>
  </xsl:template>

  <xsl:template match="bios" mode="contentItem2JATS">
    <xsl:apply-templates select="@*, node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="bios/sp" mode="contentItem2JATS">
    <bio>
      <p>
        <xsl:apply-templates select="@*, node()" mode="#current"/>  
      </p>
    </bio>
  </xsl:template>
  
  <xsl:template match="@file" mode="contentItem2JATS">
    <xsl:attribute name="xlink:href" select="."/>
  </xsl:template>

  <xsl:template match="figureGroup" mode="contentItem2JATS_anchor">
    <xsl:param name="anchor" as="element(anchor)"/>
    <fig>
      <xsl:apply-templates select="$anchor/@position, @*, node()" mode="contentItem2JATS"/>
    </fig>
  </xsl:template>

  <xsl:template match="figureGroup | tableGroup | footnote" mode="contentItem2JATS"/>
  
  <xsl:template match="@position[. = 'fixed']" mode="contentItem2JATS">
    <xsl:attribute name="{name()}" select="'anchor'"/>
  </xsl:template>
  
  <xsl:template match="figureGroup/title | tableGroup/title" mode="contentItem2JATS">
    <caption>
      <title>
        <xsl:apply-templates select="@*, node()" mode="#current"/>  
      </title>
    </caption>
  </xsl:template>
  
  <xsl:template match="blockGraphic" mode="contentItem2JATS">
    <graphic>
      <xsl:apply-templates select="@* except @erights, @erights, node()" mode="#current"/>
    </graphic>
  </xsl:template>
  
  <xsl:template match="@copyright[. = 'inherit']" mode="contentItem2JATS"/>

  <xsl:template match="@erights[. = 'yes']" mode="contentItem2JATS">
    <!--<xsl:processing-instruction name="mapping-question"> Attribute erights="yes" ignored. Ok</xsl:processing-instruction>-->
  </xsl:template>

  <xsl:template match="section | subsect1 | subsect2 | subsect3" mode="contentItem2JATS">
    <sec>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </sec>
  </xsl:template>
  
  <xsl:template match="inf" mode="contentItem2JATS">
    <sub>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </sub>
  </xsl:template>

  <xsl:template match="@listType" mode="contentItem2JATS">
    <xsl:attribute name="list-type" select="."/>
  </xsl:template>
  
  <xsl:template match="@listType[. = 'unlabelled']" mode="contentItem2JATS">
    <xsl:attribute name="list-type" select="'simple'"/>
  </xsl:template>

  <xsl:template match="list[@listType = 'unlabelled']/listItem[count(p) = 1]" mode="contentItem2JATS" priority="2">
    <list-item>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </list-item>
  </xsl:template>

  <xsl:template match="list[@listType = 'unlabelled']/listItem[count(p) gt 1]" mode="contentItem2JATS" priority="2">
    <list-item>
      <xsl:apply-templates select="@*" mode="#current"/>
      <label>
        <xsl:apply-templates select="p[1]/node()" mode="#current"/>
      </label>
      <xsl:apply-templates select="* except p[1]" mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template match="listItem[not(no)]" mode="contentItem2JATS">
    <list-item>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:call-template name="label"/>
      <xsl:apply-templates mode="#current"/>
    </list-item>
  </xsl:template>
  
  <xsl:template name="label">
    <xsl:param name="space" select="'&#x2003;'" as="xs:string"/>
    <xsl:variable name="list-type" as="xs:string" select="(../@listType, 'bullet')[1]"/>
    <xsl:variable name="marker" as="xs:string">
      <xsl:choose>
        <xsl:when test="$list-type = 'bullet'">
          <xsl:sequence select="'&#x2022;'"/>
        </xsl:when>
        <xsl:when test="$list-type = 'arabic'">
          <xsl:number format="1."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">list type <xsl:value-of select="$list-type"/> not implemented.</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <label>
      <xsl:value-of select="$marker"/>
      <xsl:if test="not($space = '')">
        <x>
          <xsl:value-of select="$space"/>
          <xsl:processing-instruction name="mapping-question">Do we really need to generate the spacing within the label</xsl:processing-instruction>
        </x>
      </xsl:if>
    </label>
  </xsl:template>

  <xsl:template match="tableGroup" mode="contentItem2JATS_anchor">
    <xsl:param name="anchor" as="element(anchor)"/>
    <table-wrap>
      <xsl:apply-templates select="@*, $anchor/@position, node()" mode="contentItem2JATS"/>
    </table-wrap>
  </xsl:template>

  <xsl:template match="th[count(*) = 1]/p | td[count(*) = 1]/p" mode="contentItem2JATS" priority="2">
    <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
  </xsl:template>
  
  <xsl:template match="backMatter" mode="contentItem2JATS">
    <back>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </back>
  </xsl:template>
  
  <xsl:template match="citationList" mode="contentItem2JATS">
    <ref-list>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </ref-list>
  </xsl:template>
  
  <xsl:template match="appMatter" mode="contentItem2JATS">
    <app-group>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </app-group>
  </xsl:template>
  
  <xsl:template match="appendix" mode="contentItem2JATS">
    <app>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </app>
  </xsl:template>
  
  <xsl:template match="equation" mode="contentItem2JATS">
    <disp-formula>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
      <xsl:processing-instruction name="mapping-question">This has been mapped to a display formula. Is this correct</xsl:processing-instruction>
    </disp-formula>
  </xsl:template>
  
  <xsl:template match="blockQuote" mode="contentItem2JATS">
    <disp-quote>
      <xsl:apply-templates select="@*, node()" mode="contentItem2JATS"/>
    </disp-quote>
  </xsl:template>
  
  
  
  
</xsl:stylesheet>
