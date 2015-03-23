<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <pattern id="date">
    <rule context="month">
      <assert test="matches(., '^(0[1-9]|1[12])$')" id="numeric-month" role="warn">Month should be 01, 02, …,12.</assert>
    </rule>
    <rule context="year">
      <assert test="number(.) - abs(year-from-date(current-date())) le 1" id="numeric-year" role="warn">Year should be around the current date.</assert>
    </rule>
  </pattern>
  <pattern id="issue-doi">
    <rule context="issue-id">
      <assert test=". = replace(base-uri(), '^.+/(.+)\.xml', '$1')" id="issue-doi-matches-file-name" role="warn">The issue DOI must match the file name.</assert>
      <!--<assert test="matches(., '^[-a-z0-9.]+$', 'i')" id="issue-id-regex" role="warn">Because the issue ID will be re-used for several file naming purposes, you should avoid characters other than digits, A-Z letters of any case, dots, and dashes.</assert>-->
    </rule>
  </pattern>
</schema>