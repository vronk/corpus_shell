=========================
cr-xq - special issues
=========================


CQL to XPath
-------------

Examples of queries in lucene-ft-search:
http://en.wikibooks.org/wiki/XQuery/Lucene_Search#Legacy_Full_Text_Search_Vs._Lucene_XML_Search



Keyword Highlighting
--------------------

Basically index-searches in eXist return the matched pattern (word, element) wrapped with a ``exist:match``-element
(This is achieved by applying ``util:expand()`` on the resultset. A further function - ``kwic:summarize`` can make use of such marked data 
to create a kwic-line.)
However these functionality is not really working when matching on attributes.

See:
http://markmail.org/message/tnfeduzdyvaedmdd
http://sourceforge.net/tracker/index.php?func=detail&aid=3204156&group_id=17691&atid=117691
http://sourceforge.net/mailarchive/message.php?msg_id=28148705

Therefore, there is a custom function in ``fcs.xqm``, that highlights (with ``<exist:match>``) the element, 
of which attribute matched.
This can be rather costly depending on the size of the (returned) result-set, as it recursively traverses all the elements.
E.g. it takes a few seconds for a resultset with 100 records.
Of course, it is only applied on the subsequence of the result, that is returned to the user (determined by $startRecord and $maximumRecords)


Related: http://rvdb.wordpress.com/2011/07/20/from-kwic-display-to-kwicer-processing-with-exist/