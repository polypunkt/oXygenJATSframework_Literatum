<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:l="http://xproc.org/library" 
  xmlns:letex="http://www.le-tex.de/namespace"
  xmlns:pxp="http://exproc.org/proposed/steps"
  xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  version="1.0" 
  name="process-manifest">

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>An Atypon manifest file. We’re currently supporting version 4.1; 4.0 and 4.2 may work, too.</p>
    </p:documentation>
  </p:input>

  <p:input port="schematron">
    <p:document href="../schematron/literatum_package.sch"/>
  </p:input>
  <p:input port="svrl2html">
    <p:document href="../schematron/svrl2html.xsl"/>
  </p:input>

  <p:output port="result" primary="true">
    <!--<p:pipe port="result" step="build-issue"/>-->
  </p:output>
  <p:serialization port="result" indent="true" omit-xml-declaration="false" method="xhtml"/>

  <p:option name="tmpdir" required="false" select="''">
    <p:documentation>URI or file system path. If not given, will be calculated.</p:documentation>
  </p:option>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/file-uri/file-uri.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/xproc.org/library/recursive-directory-list.xpl"/>
  <p:import href="http://transpect.le-tex.de/xproc-util/store-debug/store-debug.xpl"/>
  <p:import href="rng.xpl"/>
  <p:import href="recursive-delete.xpl"/>

  <p:variable name="exclude-regex" select="'(/(__MACOSX|thumbs\.db)|\.(tmp|debug)/|~$)'"/>

  <transpect:file-uri name="tmpdir-uri">
    <p:with-option name="filename" select="($tmpdir[normalize-space()], replace(base-uri(), '^(.+)/.+$', '$1.tmp/'))[1]"/>
  </transpect:file-uri>

  <p:sink/>

  <transpect:file-uri name="zip-uri">
    <p:with-option name="filename" select="(replace(base-uri(), '^(.+)/((([^.]+)\.)?([^/]+))/([^/]+)$', '$1/$4_$2.zip'))[1]">
      <p:pipe port="source" step="process-manifest"/>
    </p:with-option>
  </transpect:file-uri>
  
  <p:sink/>

  <l:recursive-directory-list name="recursive-directory-list">
    <p:with-option name="path" select="replace(base-uri(), '^(.+/).+$', '$1')">
      <p:pipe port="source" step="process-manifest"/>
    </p:with-option>
  </l:recursive-directory-list>

  <p:add-attribute match="/c:directory/c:file[not(@name = 'manifest.xml')]" attribute-name="ignore" attribute-value="true"/>

  <p:group>
    <p:variable name="tmpdir-uri" select="/*/@local-href">
      <p:pipe port="result" step="tmpdir-uri"/>
    </p:variable>
    <p:variable name="debug-dir-uri" select="replace($tmpdir-uri, '\.tmp/*$', '.debug/')"/>
    <p:variable name="zip-uri" select="/*/@local-href">
      <p:pipe port="result" step="zip-uri"/>
    </p:variable>
    <p:viewport match="c:file" name="load-xml">
      <p:choose>
        <p:when test="matches(resolve-uri(/*/@name, base-uri()), $exclude-regex, 'i')">
          <p:add-attribute match="/c:file" attribute-name="ignore" attribute-value="true"/>
        </p:when>
        <p:when test="matches(/*/@name, '\.xml$')">
          <p:try name="load">
            <p:group>
              <p:output port="result" primary="true"/>
              <p:load dtd-validate="true">
                <p:with-option name="href" select="resolve-uri(/*/@name, base-uri())"/>
              </p:load>
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

    <p:viewport match="/c:directory/c:file[not(@ignore = 'true')][not(c:errors)]" name="validate-manifest">
      <letex:validate-with-rng name="val">
        <p:input port="source" select="/c:file/*[not(self::c:*)]">
          <p:pipe port="current" step="validate-manifest"/>
        </p:input>
        <p:input port="schema">
          <p:document href="http://hogrefe.com/JATS/schema/submissionmanifest/submissionmanifest.4.1.rng">
            <p:documentation>If 4.2 is a superset of 4.1, we should use 4.2. If Atypon would be so kind as to provide
              it.</p:documentation>
          </p:document>
        </p:input>
      </letex:validate-with-rng>
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

    <p:xslt name="referenced-files">
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="referenced-files.xsl"/>
      </p:input>
    </p:xslt>

    <letex:store-debug pipeline-step="1.referenced-files" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>

    <p:xslt name="denote-actions">
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:document href="actions.xsl"/>
      </p:input>
      <p:with-param name="dest-uri" select="$tmpdir-uri"/>
    </p:xslt>

    <letex:store-debug pipeline-step="2.denote-actions" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>

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
          <p:identity>
            <p:input port="source" select="/*/article">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </p:identity>
          <p:store doctype-public="-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.0 20120330//EN"
            doctype-system="JATS-archivearticle1.dtd" omit-xml-declaration="false">
            <p:with-option name="href" select="/*/@target-href">
              <p:pipe port="current" step="clone"/>
            </p:with-option>
          </p:store>
        </p:when>
        <p:when test="/*/@action = 'serialize' and /*/*/self::submission">
          <p:identity>
            <p:input port="source" select="/*/submission">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </p:identity>
          <p:store doctype-public="-//Atypon//DTD Literatum Content Submission Manifest DTD v4.1 20100405//EN"
            doctype-system="submissionmanifest.4.1.dtd" omit-xml-declaration="false">
            <p:with-option name="href" select="/*/@target-href">
              <p:pipe port="current" step="clone"/>
            </p:with-option>
          </p:store>
        </p:when>
        <p:when test="/*/@action = 'serialize' and /*/*/self::issue">
          <p:identity>
            <p:input port="source" select="/*/issue">
              <p:pipe port="current" step="clone"/>
            </p:input>
          </p:identity>
          <p:store doctype-public="-//Atypon//DTD Atypon JATS Journal Archiving and Interchange Issue XML DTD v1.0 20120831//EN"
            doctype-system="Atypon-Issue-Xml.dtd" omit-xml-declaration="false">
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

    <letex:store-debug pipeline-step="3.zip-manifest" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </letex:store-debug>

    <p:sink/>

    <p:validate-with-schematron assert-valid="false" name="sch">
      <p:input port="source">
        <p:pipe port="result" step="denote-actions"/>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="schema">
        <p:pipe port="schematron" step="process-manifest"/>
      </p:input>
      <p:with-param name="allow-foreign" select="'true'"/>
      <p:with-param name="full-path-notation" select="'2'"/>
    </p:validate-with-schematron>

    <p:sink/>

    <letex:store-debug pipeline-step="4.svrl" active="yes">
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
      <p:input port="source">
        <p:pipe port="report" step="sch"/>
      </p:input>
    </letex:store-debug>
  
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
        <letex:recursive-delete name="del" cx:depends-on="zip">
          <p:with-option name="href" select="$tmpdir-uri"/>
        </letex:recursive-delete>
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

    <p:xslt name="svrl2html">
      <p:input port="source">
        <p:pipe port="report" step="sch"/>
        <p:pipe port="result" step="conditionally-zip"/>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
      <p:input port="stylesheet">
        <p:pipe port="svrl2html" step="process-manifest"/>
      </p:input>
    </p:xslt>

    <!--<cx:message name="msg" cx:depends-on="conditionally-zip">
      <p:with-option name="message" select="'ZZZZZZZZZZZZZZZ ', $tmpdir-uri, ' ', $zip-uri"/>
    </cx:message>-->

    <p:sink/>

    <p:identity>
      <p:input port="source">
        <p:pipe port="result" step="svrl2html"/>
      </p:input>
    </p:identity>

  </p:group>

  

</p:declare-step>