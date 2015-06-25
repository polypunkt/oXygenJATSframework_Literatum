<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="file:/C:/cygwin/home/gerrit/Hogrefe/BookTagSet/repo/schema/iso-schematron/iso-schematron.rng" schematypens="http://relaxng.org/ns/structure/1.0"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink"/>
  
  <let name="jid-from-filename" value="replace(base-uri(), '^.+/(.+?)\..+$', '$1')"/>
  <let name="contrib-article-types" value="('article-commentary', 'brief-report', 'case-report', 'discussion', 
    'research-article', 'review-article')"/>
  <let name="article-types" value="('abstract', 'addendum', 'announcement', 'article-commentary', 'back-matter', 
    'bibliography', 'book-review', 'books-received', 'brief-report', 'calendar', 'case-report', 'collection', 
    'correction', 'discussion', 'dissertation', 'editorial', 'front-matter', 'in-brief', 'index', 'instructions', 
    'introduction', 'letter', 'meeting-report', 'news', 'note', 'obituary', 'opinion', 'oration', 'other', 
    'partial-retraction', 'product-review', 'rapid-communication', 'reply', 'reprint', 'research-article', 
    'retraction', 'review-article', 'translation')"/>
  <let name="abstract-required-en" value="('Brief Report', 'Case Report', 'Research Article')"/>

  <pattern id="no-empty">
    <rule context="*[empty(node())]">
      <assert test="true()">No empty elements.</assert>
    </rule>
  </pattern>
  
  <pattern id="types">
    <rule context="article">
      <assert test="@article-type = $article-types">article-type must be one of <value-of 
        select="string-join(for $t in $article-types return concat('''', $t, ''''), ', ')"/>.</assert>
    </rule>
  </pattern>

  <pattern id="issn">
    <rule context="journal-meta[count(issn) gt 1]/issn">
      <assert test="exists(@pub-type)" id="issn_multi_no-pub-type">If there are multiple ISSNs, each must have a pub-type attribute.</assert>
      <report test="exists(@epub-type) and not(@pub-type = ('ppub', 'epub'))" id="issn_multi_invalid-pub-type">pub-type must be 'epub' or 'ppub'.</report>
    </rule>
  </pattern>
  <pattern id="journal-id">
    <rule context="journal-meta">
      <assert test="normalize-space(journal-id[@journal-id-type = 'publisher'])">The publisher-specific journal-id must be present and it must not be empty.</assert>
    </rule>
  </pattern>
  <pattern id="issue">
    <rule context="article-meta">
      <assert test="normalize-space(volume)">The volume element must be present and it must not be empty.</assert>
      <assert test="normalize-space(issue)">The issue element must be present and it must not be empty.</assert>
      <assert test="normalize-space(fpage)">The fpage element must be present and it must not be empty (or page-range for single-page articles).</assert>
    </rule>
    <rule context="article-meta/volume">
      <report test="italic | bold">No italic or bold in article-meta/volume</report>
    </rule>
  </pattern>
  
  <pattern id="pdf-self-uri">
    <rule context="article-meta[not(contains(ancestor::article/@article-type, 'header'))]">
      <assert test="self-uri[@content-type = 'pdf']">There must be a self-uri[@content-type = 'pdf']</assert>
    </rule>
    <rule context="self-uri[@content-type = 'pdf']">
      <assert test="@xlink:href = concat($jid-from-filename, '.pdf')">The PDF self-uri base name should match the current XML file base name (<value-of select="$jid-from-filename"/>).</assert>
    </rule>
  </pattern>
  
  <pattern id="doi">
    <rule context="article-meta[not(contains(ancestor::article/@article-type, 'header'))]">
      <assert test="exists(article-id[@pub-id-type = 'doi'])" id="article-id-doi">There must be an article-id with pub-id-type="doi".</assert>
    </rule>
    <rule context="article-id[@pub-id-type = 'doi']">
      <assert test="matches(., '^10\.\d+/')" id="doi-prefix-regex" role="warning">The DOI prefix must start with '10.', followed by digits and a slash.</assert>
      <!--<assert test="matches(., '^[^/]+/[-a-z0-9.]+$', 'i')" id="doi-suffix-regex" role="warning">Because the DOI will be re-used for several file naming purposes, 
        you should avoid characters other than digits, A-Z letters of any case, dots, and dashes. This does not apply to the first slash, which separates the publisher part from the DOI suffix.</assert>-->
    </rule>
  </pattern>

  <pattern id="apa-id-1">
    <rule context="article-meta">
      <assert test="exists(article-id[@pub-id-type = 'apaID'])" id="article-id-apaID">There must be an article-id with pub-id-type="apaID".</assert>
    </rule>
  </pattern>

  <pattern id="apa-id-2">
    <rule context="article-id[@pub-id-type = 'apaID'][not(../volume = '-1')]">
      <assert test=". = string-join((../../journal-meta/journal-id[@journal-id-type = 'publisher'],
                                     ../volume, ../issue, ../fpage), '_')">The apaID must consist of the journal-id of journal-id-type="publisher",
      volume, issue, and fpage, all joined by underscores. Example: foo_44_3_891</assert>
    </rule>
    <rule context="article-id[@pub-id-type = 'apaID'][../volume = '-1']">
      <assert test=". = string-join((../../journal-meta/journal-id[@journal-id-type = 'publisher'],
                                     for $d in ../article-id[@pub-id-type = 'doi'] return replace($d, '^.+/', ''),
                                     '-1', '1'), '_')">The apaID for advance articles must consist of the journal-id of journal-id-type="publisher",
      an underscore, the part of the doi after the last slash, and the string '_-1_1'. Example: foo_a000381_-1_1</assert>
    </rule>
  </pattern>

  <pattern id="lang">
    <rule abstract="true" id="main-lang">
      <assert test="exists(@xml:lang)">This element must have an xml:lang attribute.</assert>
      <assert test="matches(@xml:lang, '^\p{Ll}{2}$')" role="warning">The language attribute should be a 2-digit ISO 639-1 language code.</assert>
      <assert test="matches(@xml:lang, '^\p{Ll}{2,3}$')">The language attribute must be a 2- or 3-digit ISO 639 language code.</assert>
    </rule>
    <rule context="abstract|article|trans-abstract|kwd-group">
      <extends rule="main-lang"/>
    </rule>
  </pattern>
  
  <pattern id="common-langs">
    <rule context="*[@xml:lang]">
      <assert test="@xml:lang = ('en', 'de')" role="warning">The article language of this publisher is typically 'en' or 'de'.</assert>
    </rule>
  </pattern>
  
  <pattern id="abstract-first-word-bold">
    <rule context="abstract | trans-abstract">
      <assert test="p[1]/node()[normalize-space()][1]/self::bold" role="warning">First word should be boldface</assert>
    </rule>
  </pattern>
  <pattern id="abstract-first-word">
    <rule context="abstract[@xml:lang = 'en'] | trans-abstract[@xml:lang = 'en']/p[1]">
      <assert test="matches(., '^\s*Abstract\.\s')" role="warning">Abstract should start with 'Abstract. '</assert>
    </rule>
    <rule context="abstract[@xml:lang = 'de'] | trans-abstract[@xml:lang = 'de']/p[1]">
      <assert test="matches(., '^\s*Zusammenfassung\.\s')" role="warning">German abstract should start with 'Zusammenfassung. '</assert>
    </rule>
    <rule context="abstract[@xml:lang = 'en']/p[1]/node()[normalize-space()][1] | trans-abstract[@xml:lang = 'en']/p[1]/node()[normalize-space()][1]">
      <assert test="matches(., '^Abstract\.$')" role="warning">The boldface text should be 'Abstract.'</assert>
    </rule>
    <rule context="abstract[@xml:lang = 'de']/p[1]/node()[normalize-space()][1] | trans-abstract[@xml:lang = 'de']/p[1]/node()[normalize-space()][1]">
      <assert test="matches(., '^Zusammenfassung\.$')" role="warning">The boldface text should be 'Zusammenfassung.'</assert>
    </rule>
  </pattern>
  
  <pattern id="one-abstract">
    <rule context="article-meta">
      <report test="count(abstract) gt 1">There must only be one abstract. Translations need to be tagged as trans-abstract.</report>
      <assert test="not(abstract/@xml:lang = trans-abstract/@xml-lang)">The trans-abstract language must differ from the main abstract language.</assert>
    </rule>
  </pattern>
  
  <pattern id="one-abstract-for-certain-types">
    <rule context="article[@xml:lang = 'en']
                    /front
                      /article-meta[article-categories/subj-group[@subj-group-type = 'toc-heading']/subject = $abstract-required-en]">
      <assert test="exists(abstract)">Articles of type '<value-of 
        select="article-categories/subj-group[@subj-group-type = 'toc-heading']/subject"/>' must have an abstract.</assert>
    </rule>
  </pattern>

  <pattern id="kwd-x">
    <rule context="kwd-group/x">
      <report test="matches(., '\s')">An x element in kwd-group must not contain whitespace.</report>
      <assert test=". = ','">An x element in kwd-group must only contain the string ','.</assert>
      <assert test="preceding-sibling::node()[1]/self::kwd" role="warning">Don’t insert whitespace before the separator.</assert>
      <assert test="following-sibling::kwd">If there is a separator, there must be a following kwd.</assert>
    </rule>
    <rule context="kwd[preceding-sibling::*[1]/self::x][following-sibling::*]">
      <assert test="following-sibling::*[1]/self::x" role="warning">If there is a preceding x element, why isn’t there a following?</assert>
    </rule>
  </pattern>
  
  <pattern id="issns">
    <rule context="journal-meta">
      <assert test="exists(issn[@pub-type = 'ppub'])" role="warning">An issn element with pub-type="ppub" should be present.</assert>
      <assert test="exists(issn[@pub-type = 'epub'])" role="warning">An issn element with pub-type="epub" should be present.</assert>
      <assert test="exists(issn-l)" role="warning">A linking ISSN (issn-l) should be present.</assert>
    </rule>
  </pattern>
 
  <pattern id="category">
    <rule context="article-meta[not(contains(ancestor::article/@article-type, 'header'))]">
      <assert test="article-categories/subj-group[@subj-group-type = 'toc-heading']">There must be an
      article-categories/subj-group[@subj-group-type = 'toc-heading'] category.</assert>
    </rule>
  </pattern>

  <pattern id="contrib">
    <rule context="contrib">
      <assert test="exists(xref[@ref-type = 'aff'])" role="warning">Each contrib should have an affiliation (xref ref-type="aff" rid="…").</assert>
      <report test=".//degrees">Don’t include degrees in the contrib names.</report>
    </rule>
    <rule context="contrib/xref[@ref-type = 'aff']">
      <assert test="preceding-sibling::node()[1]/(self::string-name | self::xref | self::x)" role="warning">Affiliation xref should follow string-name immediately, without whitespace in between.</assert>
      <assert test="exists(sup)">The affiliation should be in a sup element.</assert>
      <assert test="exists(../following-sibling::aff[@id = current()/@rid])">The corresponding aff element should follow after the contrib elements.</assert>
      <assert test="deep-equal(../../aff[@id = current()/@rid]/label/node(), node())" role="warning">Affiliation label should match this reference.</assert>
    </rule>
    <rule context="aff">
      <report test="following-sibling::contrib" role="warning">aff elements should appear after contrib elements.</report>
      <assert test="exists(label)" role="warning">Affiliations should have a label.</assert>
    </rule>
  </pattern> 

  <pattern id="string-names">
    <rule context="string-name">
      <assert test="count(surname) = 1" role="warning">There should be exactly one surname.</assert>
      <assert test="count(given-names) = 1" role="warning">There should be exactly one given-names.</assert>
      <report test="text()[matches(., '\S')][not(. = '†')]" role="warning">There should only be whitespace text nodes in string-name
        (with the exception of text nodes that consist of a single dagger, '†'). Found: <value-of 
        select="string-join(for $t in text()[matches(., '\S')] return concat('''', $t, ''''), ', ')"/></report>
    </rule>
    <rule context="contrib/string-name/surname">
      <report test="following-sibling::given-names" role="warning">Given names should appear before the surname.</report>
    </rule>
    <rule context="contrib/string-name/given-names">
      <assert test="following-sibling::node()[1]/self::text()[matches(., '^\s+$')]" role="warning">Given names should be followed by whitespace.</assert>
    </rule>
  </pattern>

  <pattern id="email-address">
    <let name="email-regex-x" value="'^[-a-z0-9~!$%*_=+]+
                                       (\.[-a-z0-9~!$%^*_=+]+)*@
                                       [a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*
                                       \.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])$'"/>
    <rule context="email">
      <assert test="matches(., $email-regex-x, 'xi')">The email seems to be incorrect. Note that this element must only contain an email
      address, no 'mailto:' and no 'E-Mail: ', etc.</assert>
    </rule>
  </pattern>
  
  <pattern id="lowercase-email-preferred">
    <rule context="email">
      <report test="matches(., '\p{Lu}')" role="warning">Email addresses should be all lowercase. Found: '<value-of select="."/>'.</report>
    </rule>
  </pattern>

  <pattern id="contrib-sep-comma" abstract="true">
    <rule context="contrib-group[count(contrib) gt 2]/contrib[position() lt last() - 1]">
      <assert test="following-sibling::*[1]/self::x[. = ', ']">These contribs must be separated by an x element with the content ', '.</assert>
    </rule>
  </pattern>
  <pattern id="contrib-sep-and">
    <rule context="contrib-group[count(contrib) gt 2]/contrib[position() = last()]">
      <let name="and" value="if (ancestor::article/@xml:lang = 'de') then ' und ' else ', and '"/>
      <assert test="preceding-sibling::*[1]/self::x[replace(., '\s+', ' ') = $and]">This contrib must be preceded by an x element with the content '<value-of select="$and"/>'.</assert>
    </rule>
    <rule context="contrib-group[count(contrib) = 2]/contrib[position() = last()]">
      <let name="and" value="if (ancestor::article/@xml:lang = 'de') then ' und ' else ' and '"/>
      <assert test="preceding-sibling::*[1]/self::x[replace(., '\s+', ' ') = $and]">This contrib must be preceded by an x element with the content '<value-of select="$and"/>'.</assert>
    </rule>
  </pattern>

  <pattern id="must-have-corresponding">
    <rule context="article[@article-type = $contrib-article-types]
                    /front
                      /article-meta">
      <assert test="exists(contrib-group/contrib[@corresp = 'yes'])" role="warning">In all articles of type <value-of 
        select="string-join(for $c in $contrib-article-types return concat('''', $c, ''''), ', ')"/>, there should be at least one
        contrib with corresp="yes".</assert>
      <assert test="count(author-notes/corresp) = 1" role="warning">If there is a corresponding author, article-meta 
        should include at least one element author-notes/corresp.</assert>
    </rule>
  </pattern>  

  <pattern id="corresp">
    <rule context="corresp">
      <let name="non-conforming" value="text()[normalize-space()][not(matches(., '^,(\s+(Tel\.|E-mail|Fax))?\s+$'))]"/>
      <report test="exists($non-conforming)">If there is plain text here, it 
        should be one of the following (separated by ; to decrease confusion): 
        ', '; ', E-mail '; ', Fax '; or ', Tel. '. Found: <value-of 
          select="string-join(for $t in $non-conforming return concat('''', $t, ''''), '; ')"/></report>
    </rule>
    <rule context="corresp[count(*) gt 1]/email">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., '^\s*(E-mail\s+)$')]">The text preceding the email
      element must be ' E-mail '.</assert>
    </rule>
    <rule context="corresp[count(*) = 1]/email">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., '^\s*(E-mail\s+)?$')]">The text preceding the email
      element must be ' E-mail '.</assert>
    </rule>
    <rule context="corresp/fax">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., '^\s*(Fax\s+)$')]">The text preceding the fax
      element must be ' Fax '.</assert>
    </rule>
    <rule context="corresp/phone">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., '^\s*(Tel\.\s+)$')]">The text preceding the phone
      element must be ' Tel. '.</assert>
    </rule>
    <rule context="corresp/*[preceding-sibling::node()[1]/self::text()[matches(., '\s*Tel\.\s+')]]">
      <assert test="self::phone">There must be a phone element after ' Tel. '.</assert>
    </rule>
    <rule context="corresp/*[preceding-sibling::node()[1]/self::text()[matches(., '\s*Fax\s+')]]">
      <assert test="self::fax">There must be a fax element after ' Fax '.</assert>
    </rule>
    <rule context="corresp/*[preceding-sibling::node()[1]/self::text()[matches(., '\s*E-mail\s+')]]">
      <assert test="self::email">There must be an email element after ' E-mail '.</assert>
    </rule>
  </pattern>  

  
  <pattern id="bio-fig">
    <rule context="bio">
      <report test="graphic">Use fig.</report>
      <report test="count(fig) gt 1">More than one bio figure?</report>
    </rule>
    <rule context="bio/fig">
      <assert test="count(graphic) = 1">Should contain exactly one graphic.</assert>
    </rule>
    <rule context="bio/fig/graphic">
      <assert test="starts-with(@id, 'au-')">Bio figure graphic ID must start with 'au-'.</assert>
    </rule>
  </pattern>
  
  <pattern id="graphic">
    <rule context="graphic">
      <let name="ext" value="replace(@xlink:href, '^.+?([^.]+)$', '$1')"/>
      <let name="basename" value="replace(@xlink:href, '^(.+/)?([^/.]+)\..+$', '$2')"/>
      <let name="candidates" value="for $i in (@id(:, ../@id:)) return string-join(($jid-from-filename, $i), '_')"/>
      <assert test="$basename = $candidates">The file’s base name 
      should be <value-of select="string-join($candidates, ' or ')"/></assert>
      <assert test="if (exists(ancestor::fig | ancestor::table-wrap)) 
        then $ext = 'tif' else $ext='gif'">File extension must be <value-of select="$ext"/>.</assert>
    </rule>
  </pattern>
  
  <pattern id="sec">
    <rule context="sec[not(ancestor::sec | ancestor::boxed-text)]">
      <report test="@disp-level" role="warning">disp-level should only be given for subsections.</report>
    </rule>
    <rule context="sec[ancestor::sec][not(ancestor::boxed-text)]">
      <let name="subsect" value="string-join(('subsect', string(count(ancestor::sec))), '')"/>
      <assert test="@disp-level = $subsect" role="warning">disp-level should be <value-of select="$subsect"/>.</assert>
    </rule>
  </pattern>
  
  <!--
    Sect. 2.12 probably tells us: If a rendered label is included in the text, it must be put inside a label element.
    Automatically rendered labels are ok. -->
  <pattern id="label">
    <let name="label-regex" 
      value="'^((Abb(\.|ildung)|Fig(\.|ure)|Abschn(\.|itt)|Sec(\.|t\.|tion)|Anh(\.|ang)|App(\.|endix))[\p{Zs}\s]+)?[\(\[]?(([ivx]+|[IVX]+|[a-z]|[A-Z]|&#x2007;*[0-9]+)(\.\d+)*)[.:]?[\)\]]?[\p{Zs}\s]+'"/>
    <rule context="*[('fig', 'table-wrap') = name()][matches(title, $label-regex)]"><!-- excluded 'sec', 'app' from check on Hogrefe’s request -->
      <assert test="exists(label)" id="must-have-label" role="warning">According to Sect. 2.12 of the Literatum Content Tagging Guide, this item must have an explicit label.</assert>
    </rule>
    <rule context="fn[matches(p[1], $label-regex)] | list-item[matches(p[1], $label-regex)]">
      <assert test="exists(label)" id="fn-must-have-label" role="warning">According to Sect. 2.12 of the Literatum Content Tagging Guide, this item must have an explicit label.</assert>
    </rule>
  </pattern>
 
  <pattern id="closing-german-quotes">
    <rule context="*[(ancestor-or-self::*/@xml:lang)[last()] = 'de'][some $t in text() satisfies (matches($t, '”'))]">
      <report test="true()" role="warning">The character '”' (U+201D) is uncommon in German texts. Did you mean the German closing quote, '&#x201c;' (U+201C)?</report>
    </rule>
  </pattern>

  <pattern id="fn-in-head">
    <rule context="fn">
      <report test="ancestor::contrib-group">No footnote in contrib-group!</report>
      <report test="ancestor::title-group/parent::article-meta">No footnote in title-group!</report>
    </rule>
  </pattern>
  
  <pattern id="fig">
    <let name="lang" value="ancestor::*[@xml:lang][1]/@xml:lang"/>
    <rule context="fig[not(ancestor::bio)] | table-wrap">
      <assert test="label"><name/> must have label.</assert>
    </rule>
    <rule context="*[name() = ('fig', 'table-wrap')]/label">
      <report test="matches(., '[\.:]')">Label should not contain any dots or colons.</report>
    </rule>
  </pattern>
  
  <pattern id="table-alternatives">
    <rule context="table-wrap">
      <assert test="alternatives">There must be an alternatives element that contains a graphic and a table element.</assert>
    </rule>
    <rule context="table-wrap/graphic | table-wrap/table">
      <report test="true()"><name/> must be included in alternatives.</report>
    </rule>
    <rule context="table-wrap/alternatives">
      <assert test="graphic">There must be a graphic within alternatives.</assert>
      <assert test="table">There must be a table within alternatives.</assert>
    </rule>
  </pattern>
  
  <pattern id="floatref">
    <rule context="xref[@ref-type = 'fig']">
      <let name="matching-fig" value="//fig[@id = current()/@rid]"/>
      <assert test="if ($matching-fig/label) 
                    then normalize-space(.) = $matching-fig/label/normalize-space()
                    else true()" role="warning">Link text should match figure’s label.</assert>
    </rule>
    <rule context="xref[@ref-type = 'table']">
      <let name="matching-table" value="//table-wrap[@id = current()/@rid]"/>
      <assert test="if ($matching-table/label) 
                    then normalize-space(.) = $matching-table/label/normalize-space()
                    else true()" role="warning">Link text should match table’s label.</assert>
    </rule>
    <rule context="*[name() = ('fig', 'table-wrap')][not(ancestor::front)]">
      <assert test="preceding-sibling::p" role="warning"><name/> should come after p (outside of p).</assert>
    </rule>
  </pattern>
  
  <pattern id="inline-graphic">
    <rule context="article">
      <report test="exists(//inline-graphic | //disp-formula//graphic | //chem-struct//graphic)" role="info">Do the graphics files have the correct size?</report>
    </rule>
  </pattern>
  
  <pattern id="purported-equation">
    <rule context="*[graphic[starts-with(@id, 'eq')]]">
      <assert test="self::disp-formula" role="warning">The graphic id '<value-of select="graphic/@id[starts-with(., 'eq')]"/>' suggests that this should be a disp-formula.</assert>
    </rule>
  </pattern>
  
  <pattern id="boxed-text">
    <rule context="boxed-text">
      <assert test="@id"><name/> must have an id attribute.</assert>
    </rule>
  </pattern>

  <!--<pattern id="in-text-citations">
    <rule context="xref[not(ancestor::front)][@ref-type = ('fn', 'aff', 'fig', 'table')]">
      <report test="normalize-space()">Do not number the occurrences of in-text footnotes, affiliations, and figures and tables.</report>
    </rule>
    <rule context="xref[not(ancestor::front)][@ref-type = ('bibr')]">
      <report test="matches(., '^\[?\d+\]$')">Do not number the occurrences of in-text citations.</report>
    </rule>
  </pattern>-->

  <pattern id="ref">
    <rule context="ref//unpublished">
      <report test="true()">Do not use unpublished tag anymore in reference items that are unpublished, instead use year.</report>
    </rule>
  </pattern>


  <pattern id="person-sep-comma" abstract="true">
    <rule context="person-group[count(string-name) gt 2][count(string-name) le 7]/string-name[if (following-sibling::etal) 
                                                                                              then position() lt last() - 1
                                                                                              else position() lt last()]">
      <assert test="following-sibling::node()[1]/self::text()[matches(., ',\s+')]">These <name/>s must be separated by ', '.</assert>
    </rule>
  </pattern>
  <pattern id="person-sep-and">
    <rule context="person-group[count(string-name) gt 1][count(string-name) lt 7]/string-name[position() = last()][not(following-sibling::etal)]">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., '\s+&amp;\s+')]">This last <name/> must be preceded by ' &amp; '.</assert>
    </rule>
  </pattern>
  <pattern id="person-ellipsis">
    <rule context="person-group[count(string-name) gt 7]/string-name[position() = last()][not(following-sibling::etal)]">
      <assert test="preceding-sibling::node()[1]/self::text()[matches(., ',\s+…,\s+')]">In case of 8 or more
       authors only list the first six followed by an ellipsis (', …, ') and the last
        author’s name. The 6th author is '<value-of select="../string-name[6]"/>'</assert>
    </rule>
  </pattern>
  <pattern id="no-text-in-person-group">
    <rule context="person-group">
      <let name="regex-list" value="(if (ancestor::article/@xml:lang = 'en') then ',?\s+&amp;\s+' else '\s+&amp;\s+', 
                                     ',\s+', ',\s+…,\s+', '\s+\(', '\)')"/>
      <let name="non-conforming" value="text()[normalize-space()]
                                              [not(matches(., concat('^(', string-join($regex-list, '|'), ')$')))]"/>
      <report test="exists($non-conforming)" role="warning">Text in person-group should be one of the following 
        (separated by ; to decrease confusion): ', '; 
        <value-of select="if (ancestor::article/@xml:lang = 'en') then ''', &amp; ''; ' else ''"/> ' &amp; '; ', …, '; ' ('; or ')'.
      Found: <value-of select="string-join(for $t in $non-conforming return concat('''', $t, ''''), '; ')"/>.
      Please note that whitespace matters in <name/>.</report>
    </rule>
    <rule context="person-group/string-name[not(. is ../string-name[6])]">
      <report test="following-sibling::node()[1]/self::text()[matches(., '…')]">An ellipsis is only allowed after
      the 6th string-name. This is string-name #<value-of select="index-of(for $s in ../string-name return generate-id($s), generate-id(.))"/>.</report>
    </rule>
  </pattern>
  <pattern id="string-name">
    <rule context="string-name">
      <report test="node()[1]/self::text()[matches(., '^\s+')]">Remove whitespace at the beginning of string-name.</report>
      <report test="node()[last()]/self::text()[matches(., '\s+$')]">Remove whitespace at the end of string-name.</report>
    </rule>
  </pattern>

  <pattern id="ref-list">
    <rule context="back/ref-list">
      <assert test="exists(@specific-use[. = 'use-in-PI'])">There must be specific-use="use-in-PI".</assert>
    </rule>
    <rule context="ref">
      <assert test="mixed-citation">There must be mixed-citations.</assert>
    </rule>
    <rule context="mixed-citation">
      <let name="ref-pub-types" value="('book', 'book-chapter', 'conference', 'journal', 'thesis', 'other')"/>
      <assert test="@publication-type = $ref-pub-types">publication-type="<value-of 
        select="string-join($ref-pub-types, '|')"/>" required.</assert>
    </rule>
  </pattern>
  
  <pattern id="book-chapter-ref">
    <rule context="mixed-citation[@publication-type = 'book-chapter']">
      <report test="article-title">Please use chapter-title instead of article-title for book chapters.</report>
      <assert test="chapter-title">Missing element chapter-title in book chapter.</assert>
      <assert test="person-group[@person-group-type = 'editor']">There must be a person-group of person-group-type = 'editor' in book chapters.</assert>
    </rule>
  </pattern>

  <pattern id="given-surnames">
    <rule context="given-names[following-sibling::*[1]/self::surname]">
      <assert test="following-sibling::node()[1]/self::text()[matches(., '^[\s\p{Zs}]+$')]">There must be whitespace between
      given-names and surname.</assert>
    </rule>
  </pattern>

  <pattern id="single-page-citation">
    <rule context="mixed-citation//fpage">
      <report test="ancestor::mixed-citation//lpage[. = current()]">Single-page citations should have their page number in a page-range element, rather than fpage/lpage.</report>
    </rule>
  </pattern>

  <pattern id="subsup">
    <rule context="sub | sup">
      <report test="preceding-sibling::node()[1]/self::text()[matches(., '^\s+$')]" role="warning">There is whitespace text before <name/>. Is this intended? 
      If this is a text formula, please check that there is no unwanted whitespace (including line breaks).</report>
      <report test="node()[position() = (1, last())]/self::text()[matches(., '^\s+$')]" role="warning">There is whitespace text in <name/>. Is this intended? 
      If this is a text formula, please check that there is no unwanted whitespace (including line breaks).</report>
    </rule>
    <rule context="italic | bold">
      <report test="node()[position() = (1, last())]/self::text()[matches(., '^\s+$')]" role="warning">There is whitespace text in <name/>. Is this intended? 
      If this is a text formula, please check that there is no unwanted whitespace (including line breaks).</report>
    </rule>
  </pattern>

</schema>