<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:pxp="http://exproc.org/proposed/steps"
  xmlns:tr="http://transpect.io"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  version="1.0" 
  type="tr:recursive-delete" name="rd">

  <p:documentation>This is a workaround for a Calabash bug between approx. 1.0.17
  and 1.0.20 (the latter is shipped with oXygen 16.1). In oXygen 15.2, recursive="true"
  on cxf:delete did still work because it used Calabash 1.0.16.</p:documentation>

  <p:output port="result" primary="true"/>

  <p:option name="href"/>
  <p:option name="fail-on-error" select="'false'"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/recursive-directory-list/xpl/recursive-directory-list.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <p:try>
    <p:group>
      <tr:recursive-directory-list name="dirlist">
        <p:with-option name="path" select="$href"/>
      </tr:recursive-directory-list>
      <p:viewport match="c:file" name="files">
        <cxf:delete name="del-file">
          <p:with-option name="fail-on-error" select="$fail-on-error"><p:empty/></p:with-option>
          <p:with-option name="href" select="resolve-uri(/*/@name, base-uri(.))"/>
        </cxf:delete>
        <p:identity cx:depends-on="del-file">
          <p:input port="source">
            <p:pipe port="current" step="files"/>
          </p:input>
        </p:identity>
      </p:viewport>
      <p:wrap-sequence wrapper="c:files" name="ws"/>
      <cxf:delete recursive="true" name="del-dir" cx:depends-on="ws">
        <p:with-option name="fail-on-error" select="$fail-on-error"><p:empty/></p:with-option>
        <p:with-option name="href" select="/*/@xml:base">
          <p:pipe port="result" step="dirlist"/>
        </p:with-option>
      </cxf:delete>
      <p:identity cx:depends-on="del-dir">
        <p:input port="source">
          <p:pipe port="result" step="dirlist"/>
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