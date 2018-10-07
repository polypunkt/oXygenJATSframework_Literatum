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
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jats="http://jats.nlm.nih.gov"
  version="1.0" 
  name="process-manifest-oxygen">

  <p:documentation>This is a front-end for oXygen to process-manifest.xpl. See the corresponding documentation there.</p:documentation>

  <p:input port="source" primary="true"/>

  <p:input port="schematron">
    <p:document href="../schematron/literatum_package.sch"/>
  </p:input>
  <p:input port="article-schematron">
    <p:document href="../schematron/literatum_JATS.sch"/>
  </p:input>
  <p:input port="svrl2html">
    <p:document href="../schematron/svrl2html.xsl"/>
  </p:input>

  <p:output port="result" primary="true"/>
  <p:serialization port="result" indent="true" omit-xml-declaration="false" method="xhtml"/>

  <p:option name="tmpdir" required="false" select="''">
    <p:documentation>URI or file system path. If not given, will be calculated.</p:documentation>
  </p:option>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="process-manifest.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <jats:process-manifest name="process-manifest" transpect="false">
    <p:input port="schematron">
      <p:pipe port="schematron" step="process-manifest-oxygen"/>
    </p:input>
    <p:input port="article-schematron">
      <p:pipe port="article-schematron" step="process-manifest-oxygen"/>
    </p:input>
    <p:with-option name="tmpdir" select="$tmpdir"/>
  </jats:process-manifest>

  <p:sink/>

  <p:xslt name="svrl2html">
    <p:input port="source">
      <p:pipe port="report" step="process-manifest"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="svrl2html" step="process-manifest-oxygen"/>
    </p:input>
  </p:xslt>

</p:declare-step>