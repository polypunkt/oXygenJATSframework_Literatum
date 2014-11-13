<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:pxp="http://exproc.org/proposed/steps"
  version="1.0" name="build-issue">

  <p:input port="source" primary="true">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Atypon issue-xml document</p>
    </p:documentation>
  </p:input>

  <p:output port="result" primary="true" sequence="true">
    <p:pipe port="secondary" step="add-toc"/>
<!--    <p:pipe port="result" step="zip"/>-->
  </p:output>
  <p:serialization port="result" indent="true"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

  <p:directory-list include-filter="^.+\.xml" name="list-input-files">
    <p:with-option name="path" select="replace(base-uri(), '^(.+/).+$', '$1')"/>
  </p:directory-list>

  <p:for-each name="xml-iteration">
    <p:output port="result" primary="true"/>
    <p:iteration-source select="/c:directory/c:file"/>
    <p:load>
      <p:with-option name="href" select="concat(base-uri(/*), /*/@name)"/>
    </p:load>
  </p:for-each>

  <p:identity name="filter">
    <p:input port="source" select="/article[@dtd-version = '1.0']"/>
  </p:identity>

  <p:sink/>

  <p:xslt name="add-toc">
    <p:input port="source">
      <p:pipe port="source" step="build-issue"/>
      <p:pipe port="result" step="filter"/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="add-toc.xsl"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
  </p:xslt>

  <p:store name="store-patched-issue-xml">
    <p:with-option name="href" select="concat(base-uri(), '.tmp')">
      <p:pipe port="source" step="build-issue"/>
    </p:with-option>
  </p:store>

  <pxp:zip name="zip" compression-method="deflated" command="create" cx:depends-on="store-patched-issue-xml">
    <p:with-option name="href" select="replace(base-uri(/*), '\.xml$', concat('_', substring(replace(string(current-dateTime()), '\D', ''), 1, 14), '.zip'))">
      <p:pipe port="source" step="build-issue"/>
    </p:with-option>
    <p:input port="manifest">
      <p:pipe port="secondary" step="add-toc"/>
    </p:input>
    <p:input port="source">
      <p:empty/>
    </p:input>
  </pxp:zip>

  <p:sink/>

</p:declare-step>