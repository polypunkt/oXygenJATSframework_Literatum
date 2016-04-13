<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:l="http://xproc.org/library" 
  xmlns:pxp="http://exproc.org/proposed/steps"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:tr="http://transpect.io"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jats="http://jats.nlm.nih.gov"
  version="1.0"
  type="jats:process-manifest"
  name="process-manifest">

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>An Atypon manifest file. We’re currently supporting version 4.1 and 4.2; 4.0 may work, too.</p>
      <p>Its name must be <code>manifest.xml</code>.</p>
      <p>The part after the slash in /submission/@group-doi corresponds to the folder name where the 
      articles reside. manifest.xml must be stored in the same parent folder where this folder resides.</p>
      <p>Example: group-doi="10.000/med.2015.11.issue-1" ⇒ A folder named med.2015.11.issue-1 must exist,
      containing the article directories and the issue-files directory.</p>
    </p:documentation>
  </p:input>

  <p:input port="schematron">
    <p:document href="../schematron/literatum_package.sch"/>
  </p:input>
  <p:input port="article-schematron">
    <p:document href="../schematron/literatum_JATS.sch"/>
  </p:input>

  <p:output port="validation-input" primary="true">
    <p:documentation>Particularly for RNG validation. Schematron has been done already.</p:documentation>
    <p:pipe step="main" port="denote-actions"/>
  </p:output>

  <p:output port="report" sequence="true">
    <p:pipe port="report" step="main"/>
  </p:output>

  <p:output port="tmpdir-uri">
    <p:pipe port="result" step="tmpdir-uri"/>
  </p:output>

  <p:option name="tmpdir" required="false" select="''">
    <p:documentation>URI or file system path. If not given, will be calculated.</p:documentation>
  </p:option>
  
  <p:option name="transpect" select="'false'">
    <p:documentation>Whether it is invoked from within transpect (true) or oXygen (false). 
      transpect means:
      – insert srcpaths into the source documents
      – patch srcpath inclusion into the Schematrons
      – do not validate against the DTD when reading articles
      </p:documentation>
  </p:option>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="rng.xpl"/>
  <p:import href="recursive-delete.xpl"/>

  <p:declare-step name="remove-ns-decl-and-xml-base" type="tr:remove-ns-decl-and-xml-base">
    <p:documentation>The purpose of this identity transformation is to remove all namespace declarations.</p:documentation>
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>
    <p:xslt>
      <p:input port="parameters"><p:empty/></p:input>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
            <xsl:template match="* | @*">
              <xsl:copy copy-namespaces="no">
                <xsl:apply-templates select="@*, node()"/>
              </xsl:copy>
            </xsl:template>
            <xsl:template match="@xml:base | @srcpath"/>
          </xsl:stylesheet>
        </p:inline>
      </p:input>
    </p:xslt> 
  </p:declare-step>
  
  <p:declare-step name="add-srcpath-to-schematron" type="tr:add-srcpath-to-schematron">
    <p:documentation>Add span[@class = 'srcpath'] to Schematron assert and report instructions.
    This is only needed for transpect.</p:documentation>
    <p:option name="transpect"/>
    <p:input port="source" primary="true"/>
    <p:output port="result" primary="true"/>
    <p:choose>
      <p:when test="$transpect = 'true'">
        <p:xslt>
          <p:input port="parameters"><p:empty/></p:input>
          <p:input port="stylesheet">
            <p:inline>
              <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xso="xsloutputnamespace" version="2.0">
                <xsl:namespace-alias stylesheet-prefix="xso" result-prefix="xsl"/>
                <xsl:template match="* | @*">
                  <xsl:copy>
                    <xsl:apply-templates select="@*, node()"/>
                  </xsl:copy>
                </xsl:template>
                <xsl:template match="/s:schema/@queryBinding">
                  <xsl:copy/>
                  <xsl:attribute name="tr:rule-family" select="replace(base-uri(), '^.+/([^.]+)\..+$', '$1')"/>
                  <xsl:attribute name="tr:step-name" select="'schematron-validation'"/>
                  <xsl:attribute name="tr:include-location-in-msg" select="'true'"/>
                </xsl:template>
                <xsl:template match="s:assert | s:report">
                  <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:if test="not(@id)">
                      <xsl:attribute name="id" select="string-join((ancestor::s:pattern/@id, string(position())), '_')"/>
                    </xsl:if>
                    <xsl:if test="not(@role)">
                      <xsl:attribute name="role" select="'error'"/>
                    </xsl:if>
                    <xsl:if test="not(exists(s:span[@class eq 'srcpath']))">
                      <span class="srcpath" xmlns="http://purl.oclc.org/dsdl/schematron">
                        <xso:value-of select="ancestor-or-self::*[@srcpath][1]/@srcpath"/>
                      </span>
                    </xsl:if>
                    <xsl:apply-templates/>
                  </xsl:copy>
                </xsl:template>
              </xsl:stylesheet>
            </p:inline>
          </p:input>
        </p:xslt>    
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>
  </p:declare-step>

  <p:variable name="exclude-regex" select="concat('(/(__MACOSX|thumbs\.db)|\.(', 
                                                  if ($transpect = 'true') then '' else 'tmp|', 
                                                  'debug)/|~$)')"/>
  <p:variable name="timestamp" select="substring(replace(string(current-dateTime()), '\D', ''), 1, 14)"/>
  <p:variable name="subdir" select="(for $d in /submission/@group-doi
                                    return replace($d, '^.+/', ''), 'not.specified')[1]"/>
  <p:variable name="basedir" select="replace(base-uri(), '^(.+/).+$', '$1')"/>
  
  <tr:file-uri name="tmpdir-uri">
    <p:with-option name="filename" select="($tmpdir[normalize-space()], replace(base-uri(), '^(.+)/.+$', '$1/package.tmp/'))[1]"/>
  </tr:file-uri>
  
  <!--<tr:store-debug active="true" pipeline-step="manifest-source" 
    base-uri="file:/C:/cygwin/home/gerrit/Hogrefe/Literatum_JATS/input/cri_cri.2015.36.issue-6_20151208122500.tmp/tmp/package.debug"/>-->

  <p:sink/>

  <tr:file-uri name="zip-uri">
    <p:with-option name="filename"
      select="concat(
                $basedir, 
                replace(
                  $subdir, 
                  '^(([^.]+)\..+)$',
                  concat(
                    '$2_$1_',
                    $timestamp,
                    '.zip'
                  )
                )
              )">
      <p:pipe port="source" step="process-manifest"/>
    </p:with-option>
  </tr:file-uri>

  <p:sink/>

  <tr:add-srcpath-to-schematron name="patch-article-schematron">
    <p:with-option name="transpect" select="$transpect"/>
    <p:input port="source">
      <p:pipe port="article-schematron" step="process-manifest"/>
    </p:input>
  </tr:add-srcpath-to-schematron>
  
  <p:sink/>
  
  <tr:add-srcpath-to-schematron name="patch-schematron">
    <p:with-option name="transpect" select="$transpect"/>
    <p:input port="source">
      <p:pipe port="schematron" step="process-manifest"/>
    </p:input>
  </tr:add-srcpath-to-schematron>
  
  <p:sink/>

  <tr:recursive-directory-list name="recursive-directory-list">
    <p:with-option name="path" select="$basedir"/>
  </tr:recursive-directory-list>

  <p:delete>
    <p:with-option name="match" 
      select="concat('/c:directory/c:file[not(@name = ''manifest.xml'')] | /c:directory/c:directory[not(@name = ''', $subdir, ''')]')"/>
  </p:delete>

  <p:group name="main">
    <p:output port="denote-actions" primary="true">
      <p:pipe port="result" step="denote-actions"/>
    </p:output>
    <p:output port="report" sequence="true">
      <p:pipe port="result" step="add-rule-family"/>
      <p:pipe port="result" step="conditionally-zip"/>
      <p:pipe port="report" step="sch-article"/>
    </p:output>
    <p:variable name="tmpdir-uri" select="/*/@local-href">
      <p:pipe port="result" step="tmpdir-uri"/>
    </p:variable>
    <p:variable name="issue-dir" select="concat($basedir, $subdir)"/>
    <p:variable name="debug-dir-uri" select="replace($tmpdir-uri, '\.tmp/*$', '.debug/')"/>
    <p:variable name="zip-uri" select="/*/@local-href">
      <p:pipe port="result" step="zip-uri"/>
    </p:variable>
    <tr:store-debug pipeline-step="0.dirlist" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
    <p:viewport match="c:file" name="load-xml">
      <p:choose>
        <p:when test="matches(resolve-uri(/*/@name, base-uri(/*)), $exclude-regex, 'i')">
          <p:add-attribute match="/c:file" attribute-name="ignore" attribute-value="true"/>
        </p:when>
        <p:when test="matches(/*/@name, '\.xml$')">
          <p:try name="load">
            <p:group>
              <p:output port="result" primary="true"/>
              <p:load>
                <p:with-option name="dtd-validate" select="if ($transpect = 'false') then 'true' else 'false'"/>
                <p:with-option name="href" select="resolve-uri(/*/@name, base-uri())"/>
              </p:load>
              <p:add-attribute attribute-name="xml:base" match="/*">
                <p:with-option name="attribute-value" select="base-uri()"/>
              </p:add-attribute>
            </p:group>
            <p:catch name="catch-load">
              <p:output port="result" primary="true"/>
              <p:identity>
                <p:input port="source">
                  <p:pipe port="error" step="catch-load"/>
                </p:input>
              </p:identity>
            </p:catch>
          </p:try>
          <p:insert match="/*" position="last-child">
            <p:input port="source">
              <p:pipe port="current" step="load-xml"/>
            </p:input>
            <p:input port="insertion">
              <p:pipe port="result" step="load"/>
            </p:input>
          </p:insert>
        </p:when>
        <p:otherwise>
          <p:identity/>
        </p:otherwise>
      </p:choose>
    </p:viewport>

    <tr:store-debug pipeline-step="1.load-xml" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:viewport match="/c:directory/c:file[not(@ignore = 'true')][not(c:errors)]" name="validate-manifest">
      <p:output port="result" primary="true"/>
      <p:delete match="/*/@xml:base | @srcpath">
        <p:input port="source" select="/c:file/*[not(self::c:*)]">
          <p:pipe port="current" step="validate-manifest"/>
        </p:input>
      </p:delete>
      <tr:validate-with-rng name="val">
        <p:input port="schema">
          <p:document href="http://hogrefe.com/JATS/schema/submissionmanifest/manifest.4.2.rng"/>
        </p:input>
      </tr:validate-with-rng>
      <p:sink/>
      <p:insert match="/*" position="last-child">
        <p:input port="source">
          <p:pipe port="current" step="validate-manifest"/>
        </p:input>
        <p:input port="insertion">
          <p:pipe port="report" step="val"/>
        </p:input>
      </p:insert>
    </p:viewport>

    <p:viewport match="issue-xml[empty(journal-meta)]" name="insert-issue-journal-meta">
      <p:documentation>Grab journal-meta from first article and insert it into issue-xml.
      It might be a better approach to do it the other way round: Leave out journal-meta in each 
      article and pull it from issue-xml.</p:documentation>
      <p:output port="result" primary="true"/>
      <p:insert match="/*" position="first-child">
        <p:input port="source">
          <p:pipe port="current" step="insert-issue-journal-meta"/>
        </p:input>
        <p:input port="insertion" select="(//article[front/journal-meta])[1]/front/journal-meta">
          <p:pipe port="result" step="validate-manifest"/>
        </p:input>
      </p:insert>
    </p:viewport>

    <p:viewport match="issue-xml[empty(toc)]" name="insert-toc">
      <p:xslt name="create-toc" template-name="toc">
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet">
          <p:document href="add-toc.xsl"/>
        </p:input>
        <p:input port="source">
          <p:pipe port="result" step="insert-issue-journal-meta"/>
        </p:input>
      </p:xslt>
      <p:insert match="/*" position="last-child">
        <p:input port="source">
          <p:pipe port="current" step="insert-toc"/>
        </p:input>
        <p:input port="insertion">
          <p:pipe port="result" step="create-toc"/>
        </p:input>
      </p:insert>
    </p:viewport>

    <p:xslt name="referenced-files">
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="referenced-files.xsl"/>
      </p:input>
    </p:xslt>

    <p:choose>
      <p:when test="$transpect = 'true'">
        <p:label-elements match="*[not(ancestor::c:errors)]" attribute="srcpath"/>    
      </p:when>
      <p:otherwise>
        <p:identity/>
      </p:otherwise>
    </p:choose>

    <tr:store-debug pipeline-step="2.referenced-files" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:xslt name="denote-actions">
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="actions.xsl"/>
      </p:input>
      <p:with-param name="dest-uri" select="$tmpdir-uri"/>
    </p:xslt>

    <tr:store-debug pipeline-step="3.denote-actions" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:for-each name="clone">
      <p:iteration-source select="//*[@action]"/>
      <p:choose>
        <p:when test="/*/@action = 'mkdir'">
          <cxf:mkdir>
            <p:with-option name="href" select="/*/@target-href"/>
          </cxf:mkdir>
        </p:when>
        <p:when test="/*/@action = 'copy'">
          <cxf:copy>
            <p:with-option name="target" select="/*/@target-href"/>
            <p:with-option name="href" select="/*/@xlink:href"/>
          </cxf:copy>
        </p:when>
        <p:when test="/*/@action = 'serialize' and /*/*/self::article">
          <tr:remove-ns-decl-and-xml-base>
            <p:input port="source" select="/*/article">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </tr:remove-ns-decl-and-xml-base>
          <p:store doctype-public="-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.0 20120330//EN"
            doctype-system="JATS-archivearticle1.dtd" omit-xml-declaration="false">
            <p:with-option name="href" select="/*/@target-href">
              <p:pipe port="current" step="clone"/>
            </p:with-option>
          </p:store>
        </p:when>
        <p:when test="/*/@action = 'serialize' and /*/*/self::submission">
          <tr:remove-ns-decl-and-xml-base>
            <p:input port="source" select="/*/submission">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </tr:remove-ns-decl-and-xml-base>
          <p:store doctype-public="-//Atypon//DTD Literatum Content Submission Manifest DTD v4.1 20100405//EN"
            doctype-system="submissionmanifest.4.1.dtd" omit-xml-declaration="false">
            <p:with-option name="href" select="/*/@target-href">
              <p:pipe port="current" step="clone"/>
            </p:with-option>
          </p:store>
        </p:when>
        <p:when test="/*/@action = 'serialize' and /*/*/self::issue-xml">
          <tr:remove-ns-decl-and-xml-base>
            <p:input port="source" select="/*/issue-xml">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </tr:remove-ns-decl-and-xml-base>
          <p:store doctype-public="-//Atypon//DTD Atypon JATS Journal Archiving and Interchange Issue XML DTD v1.0 20120831//EN"
            doctype-system="JATS-1.0/Atypon-Issue-Xml.dtd" omit-xml-declaration="false" indent="true">
            <p:with-option name="href" select="/*/@target-href">
              <p:pipe port="current" step="clone"/>
            </p:with-option>
          </p:store>
        </p:when>
        <p:otherwise>
          <p:sink/>
        </p:otherwise>
      </p:choose>
      <p:identity>
        <p:input port="source">
          <p:pipe port="current" step="clone"/>
        </p:input>
      </p:identity>
    </p:for-each>

    <p:sink/>

    <p:for-each name="sch-article" cx:depends-on="clone">
      <p:iteration-source select="//c:file/article">
        <p:pipe port="result" step="denote-actions"/>
      </p:iteration-source>
      <p:output port="report" primary="true"/>
      <p:validate-with-schematron assert-valid="false" name="sch-article1">
        <p:input port="parameters">
          <p:empty/>
        </p:input>
        <p:input port="schema">
          <p:pipe port="result" step="patch-article-schematron"/>
        </p:input>
        <p:with-param name="allow-foreign" select="'true'"/>
        <p:with-param name="full-path-notation" select="'2'"/>
      </p:validate-with-schematron>
      <p:sink/>
      <tr:store-debug pipeline-step="patched-article-schematron" active="yes">
        <p:input port="source">
          <p:pipe port="result" step="patch-article-schematron"/>
        </p:input>
        <p:with-option name="base-uri" select="$debug-dir-uri"/>
      </tr:store-debug>
      <p:sink/>
      <p:identity>
        <p:input port="source">
          <p:pipe port="report" step="sch-article1"/>
        </p:input>
      </p:identity>
      <p:choose>
        <p:when test="$transpect = 'true'">
          <p:set-attributes match="/*">
            <p:input port="attributes">
              <p:pipe port="result" step="patch-article-schematron"/>
            </p:input>
          </p:set-attributes>
          <p:add-attribute attribute-name="tr:rule-family" match="/*" name="rename-family">
            <p:with-option name="attribute-value" select="replace(base-uri(/*), '^.+/', 'article schematron ')">
              <p:pipe port="current" step="sch-article"/>
            </p:with-option>
          </p:add-attribute>
        </p:when>
        <p:otherwise>
          <p:identity/>
        </p:otherwise>              
      </p:choose>
    </p:for-each>
    
    <p:sink/>

    <p:xslt name="zip-manifest">
      <p:input port="source">
        <p:pipe port="result" step="denote-actions"/>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="zip-manifest.xsl"/>
      </p:input>
    </p:xslt>

    <tr:store-debug pipeline-step="4.zip-manifest" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:sink/>

    <p:validate-with-schematron assert-valid="false" name="sch">
      <p:input port="source">
        <p:pipe port="result" step="denote-actions"/>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="schema">
        <p:pipe port="result" step="patch-schematron"/>
      </p:input>
      <p:with-param name="allow-foreign" select="'true'"/>
      <p:with-param name="full-path-notation" select="'2'"/>
    </p:validate-with-schematron>

    <p:sink/>
    
    <p:add-attribute attribute-name="tr:rule-family" match="/*" name="add-rule-family" attribute-value="whole_submission">
      <p:input port="source">
        <p:pipe port="report" step="sch"/>
      </p:input>
    </p:add-attribute>

    <p:sink/>

    <p:wrap-sequence wrapper="c:documents" name="svrls">
      <p:input port="source">
        <p:pipe port="result" step="add-rule-family"/>
        <p:pipe port="report" step="sch-article"/>
      </p:input>
    </p:wrap-sequence>

    <tr:store-debug pipeline-step="5.svrl" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>

    <p:sink/>
    
    <p:identity>
      <p:input port="source">
        <p:pipe port="result" step="add-rule-family"/>
      </p:input>
    </p:identity>

    <p:choose name="conditionally-zip">
      <p:when test="not(exists(/*/(svrl:failed-assert | svrl:successful-report)/@role[. = 'fatal']))">
        <p:output port="result" primary="true">
          <p:pipe port="result" step="zip"/>
        </p:output>
        <pxp:zip name="zip" compression-method="deflated" command="create">
          <p:with-option name="href" select="$zip-uri"/>
          <p:input port="manifest">
            <p:pipe port="result" step="zip-manifest"/>
          </p:input>
          <p:input port="source">
            <p:empty/>
          </p:input>
        </pxp:zip>
        <tr:recursive-delete name="del" cx:depends-on="zip">
          <p:with-option name="href" select="$tmpdir-uri"/>
        </tr:recursive-delete>
        <p:sink/>
        <!--<cxf:delete recursive="true" fail-on-error="true" name="del" cx:depends-on="zip">
          <p:with-option name="href" select="$tmpdir-uri"/>
        </cxf:delete>-->
      </p:when>
      <p:otherwise>
        <p:output port="result" primary="true"/>
        <p:identity>
          <p:input port="source">
            <p:inline><c:errors><c:error>No Zip output because there were fatal errors.</c:error></c:errors></p:inline>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>

    <p:sink/>

  </p:group>

</p:declare-step>