=====
cr-xq
=====

XQuery scripts for a content repository 
providing an FCS/SRU-interface 
for searching in data in a XMLDB.

FCS = Federated Content Search
more: http://clarin.eu/fcs

Part of corpus_shell
https://github.com/vronk/corpus_shell/


Content of the project
----------------------

- cr.xql - starting script (only sets the configuration-file and passes to the main module's fcs:repo()
- fcs.xqm - main module
- repo-utils.xqm - module with helper functions (store resources in the db ...)
- writer.xml  - necessary for the scripts being able to write into the database (cache) even when called via REST-interface
							you need to setup a user and put its credentials into this file.
- index.xsl - used for aggregating and selecting a subset in the scan-request

- /etc/config.xml - main configuration used by the scripts/modules
- /etc/mappings.xml - configuration mapping
- /etc - alternative configurations can be stored here


+ docs - growing documentation about the project
+ modules/ - for encapsulating specific parts of the funcitonality in separate modules
	following modules are required:
	diagnostics, cmd, cqlparser
	
+ modules/testing - a xquery-module for testing fcs-endpoints (or uri-requests in general)

Requirements
------------

fcs-xsl
  expects the fcs-xsl files in the database (by default in: /db/cr/xsl)
	in the corpus_shell repository they are at the top level: https://github.com/vronk/corpus_shell/tree/master/xsl

cqlparser
  the FCS/SRU/CQL protocol expects the search-queries to be encoded in CQL (Context Query Language).
  cr-xq uses a java-parser for parsing the query http://zing.z3950.org/cql/java/  
  See the module: cqlparser for more details.
  
  