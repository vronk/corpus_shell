=========================
Overview of cr-xq
=========================

Configuration
-------------

Dynamic aspects of the processing (which data is accessed etc.)
is determined by the configuration, which is stored in the config file.
This is picked up by the starting script (by default ``/db/cr/cr.xql``)
and is by default: ``/db/cr/etc/config.xml``.

There can be multiple starting scripts, with different configuration,
that would constitute a separate ("virtual") repository.
So all it needs for a separate repository is a separate starting script and a separate config-file.


Configuration refers to a specific ``mappings``-file, which serves for mapping
a ``$x-context`` parameter onto a db-collection
and indexes to xpaths.

So, all relevant functions are parametrized with ``x-context`` and ``config``,
that determine the interpretation of the request.

Mappings 
--------

Mappings serve translating between a (public) index-key, which the user is served and will use in the request
and the internal xpaths into the data. They are used by the ``scan``- and ``searchRetrieve``-operation.
	
 <map key="clarin-at:aac-test-corpus" path="/db/mdrepo-data/aac-test-corpus" base_elem="CMD">
	<index key="dce:publisher">
    <path>teiHeader.fileDesc.publicationStmt.publisher</path>
    <path>teiHeader.fileDesc.sourceDesc.biblStruct.monogr.imprint.publisher</path>
  </index>
  ...

Multiple map elements can be in one mapping-file. They are identified by ``@key``-atribute.
The correct mapping is selected based on the ``x-context``-parameter, if none is given or none matches, 
the ``<map@key=default>`` is applied.

The ``@base_elem``-attribute of the <map>-element determines, which element is to be seen as one unit 
and will be for example returned as one record in a searc-Retrieve response.
