<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:html="http://www.w3.org/1999/xhtml"
  queryBinding="xslt2">
  
  <pattern id="submission">
    <rule context="/submission[not(matches(@group-doi, '(\.ahead-of-print|dummy)$'))]">
      <let name="subdir" value="replace((@group-doi, '')[1], '^.+/', '')"/>
      <let name="issue-file" value="concat($subdir, '/issue-files/', $subdir, '.xml')"/>
      <assert test="doc-available(resolve-uri($issue-file, base-uri(/*)))" role="error">Expecting an issue file '<value-of select="$issue-file"/>'.</assert>
      <report test="@group-doi = '10.000/dummy'" role="error">Please fill in the 'group-doi' attribute in the manifest.</report>
      <assert test="@submission-type = 'full'" role="error">Only full submissions are currently supported.</assert>
      <assert test="@dtd-version = '4.2'" role="warning">This should be a DTD version 4.2 submission manifest (public identifier
        "-//Atypon//DTD Literatum Content Submission Manifest DTD v4.2 20140519//EN", system identifier "manifest.4.2.dtd").
      It should have an attribute dtd-version="4.2".</assert>
      <assert test="exists(callback/email[normalize-space()])" role="warning">At least one mail address must be given if you want to receive a submission report.</assert>
    </rule>
  </pattern>
  
</schema>