<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
  
  <pattern id="date">
    <rule context="month">
      <assert test="matches(., '^(0[1-9]|1[12])$')" id="numeric-month" role="warning">Month should be 01, 02, …,12.</assert>
    </rule>
    <rule context="year">
      <assert test="abs(number(.) - year-from-date(current-date())) le 1" id="numeric-year" role="warning">Year should be around the current date.</assert>
    </rule>
  </pattern>
  <pattern id="issue-doi">
    <rule context="issue-id">
      <let name="base" value="replace(base-uri(), '^.+/(.+)\.xml', '$1')"/>
      <let name="pdf-filename" value="string-join(($base, 'pdf'), '.')"/>
      <assert test="@pub-id-type = 'doi'">issue-id should have a pub-id-type of 'doi'.</assert>
      <assert test="replace(., '^.+/', '') = $base" id="issue-doi-matches-file-name">The part after the slash of the issue DOI must match the file name.</assert>
      <!--<assert test="matches(., '^[-a-z0-9.]+$', 'i')" id="issue-id-regex" role="warning">Because the issue ID will be re-used for several file naming purposes, you should avoid characters other than digits, A-Z letters of any case, dots, and dashes.</assert>-->
      <assert test="../self-uri[@content-type = 'pdf'][@xlink:href = $pdf-filename]" role="warning">There should be a self-uri 
        with content-type='pdf' whose xlink:href matches this file’s final base name (i.e., the after-slash part of issue-id, plus the '.pdf' extension).</assert>
    </rule>
  </pattern>
</schema>