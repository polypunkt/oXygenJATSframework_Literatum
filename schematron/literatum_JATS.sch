<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
  <pattern id="issn">
    <rule context="journal-meta[count(issn) gt 1]/issn">
      <assert test="exists(@pub-type)" id="issn_multi_no-pub-type">If there are multiple ISSNs, each must have a pub-type attribute.</assert>
      <report test="exists(@epub-type) and not(@pub-type = ('ppub', 'epub'))" id="issn_multi_invalid-pub-type">pub-type must be 'epub' or 'ppub'.</report>
    </rule>
  </pattern>
  <pattern id="label">
    <rule context="fn | list-item | sec | app | fig | table-wrap">
      <assert test="exists(label)" id="must-have-label" role="warn">According to Sect. 2.10 of the Literatum Content Tagging Guide, this item must have an explicit label.</assert>
    </rule>
  </pattern>
  <pattern id="doi">
    <rule context="article-id[@pub-id-type = 'doi']">
      <assert test="matches(., '^10\.\d+/')" id="doi-prefix-regex" role="warn">The DOI prefix must start with '10.', followed by digits and a slash.</assert>
      <assert test="matches(., '^[^/]+/[-a-z0-9.]+$', 'i')" id="doi-suffix-regex" role="warn">Because the DOI will be re-used for several file naming purposes, 
        you should avoid characters other than digits, A-Z letters of any case, dots, and dashes. This does not apply to the first slash, which separates the publisher part from the DOI suffix.</assert>
    </rule>
  </pattern>
  <pattern id="closing-german-quotes">
    <rule context="*[(ancestor-or-self::*/@xml:lang)[last()] = 'de'][some $t in text() satisfies (matches($t, '”'))]">
      <report test="true()" role="warn">The character '”' (U+201D) is uncommon in German texts. Did you mean the German closing quote, '&#x201c;' (U+201C)?</report>
    </rule>
  </pattern>
</schema>