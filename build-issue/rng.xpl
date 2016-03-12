<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:l="http://xproc.org/library" 
  xmlns:tr="http://transpect.io"
  xmlns:pxp="http://exproc.org/proposed/steps"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  version="1.0" 
  type="tr:validate-with-rng" name="validate-with-rng">

  <p:input port="source" primary="true"/>
  <p:input port="schema"/>
  <p:output port="report" primary="true"/>
  
  <p:try>
    <p:group>
      <p:validate-with-relax-ng assert-valid="true">
        <p:input port="schema">
          <p:pipe port="schema" step="validate-with-rng"/>
        </p:input>
      </p:validate-with-relax-ng>
      <p:sink/>
      <p:identity>
        <p:input port="source">
          <p:inline><c:ok/></p:inline>
        </p:input>
      </p:identity>
    </p:group>
    <p:catch name="catch">
      <p:identity>
        <p:input port="source">
          <p:pipe port="error" step="catch"/>
        </p:input>
      </p:identity>
    </p:catch>
  </p:try>
  
</p:declare-step>