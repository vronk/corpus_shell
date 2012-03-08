
****************
  corpus_shell
****************


Is a modular framework for publishing (distributed and heterogeneous) language resources.

It consists of self-contained "loosely-coupled" services, with (hopfully) clearly defined tasks and interfaces,
the basic protocol (the linuga franca) being the FCS/SRU-protocol [ http://clarin.eu/fcs ], "FCS" standing for federated content search.

We recognize following basic components to the framework:

Aggregator
    a service that is able to dispatch a query to multiple target repositories, and merge the result back.
    Currently we have a basic php-implementation fcs/aggreagtor/switch.php 
    which however is not yet able to query multiple target repositories at once. 

Wrapper
    services that translate between existing systems and the protocol. Currently we have (in an early dirty version):

      - *php* - implementations accessing MySQL-db for Dictionaries
      - *xquery* implementation for eXist-based content repository
      - *perl* implementation mapping to ddc-api (corpus search engine) 
        allowing to access our (public) corpora (not checked in yet) 

Workspace
    main user-interface allowing to select targets, issues queries, 
    see the results and invoke specialized viewer for the resources.
    [ index.html ]

ResourceViewer
    separate ui-components that are able to display/visualize specific resource types. 
    (Currently we have only the basic XSL-transformed HTML-views of the results returned by the services)
