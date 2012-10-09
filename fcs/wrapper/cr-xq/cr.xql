xquery version "1.0";

import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "fcs.xqm";

let $config := 'etc/config.xml'

return fcs:repo($config) 
