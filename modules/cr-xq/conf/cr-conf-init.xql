xquery version "3.0";

import module namespace repo-utils = "http://aac.ac.at/content_repository/utils" at  "/db/cr/repo-utils.xqm";


declare variable $base-dir := "/db/cr";
declare variable $conf-dir :=  concat($base-dir,"/conf");
declare variable $static-dir :=  "/_static";


(: TODO: move *.xconf to system-conf :)


(: generate collections and scripts for all available configurations :)
declare function local:run-configs() {
	
	let $child-colls := xmldb:get-child-collections($conf-dir)
	for $conf-coll in $child-colls 	
		return (local:main-entry-script($conf-coll),
							local:create-colls($conf-coll))
};

(: generate a conf-customized enter-point :)
declare function local:main-entry-script($conf as xs:string) {

		let $code := 
		<script-code>
xquery version "1.0";
import module namespace fcs  = "http://clarin.eu/fcs/1.0" at "fcs.xqm";

let $config := '{$conf-dir}/{$conf}/config.xml'
						
return fcs:repo($config)						
</script-code>
			
return xmldb:store($base-dir, concat($conf,'.xql'),$code/text())
			 
};

declare function local:create-colls($conf as xs:string) {
	
	let $config-file := concat($conf-dir, '/', $conf, '/config.xml'),
    $config := doc($config-file),
    $data-path := repo-utils:config-value($config,'data.path'),
    $metadata-path := repo-utils:config-value($config,'metadata.path'),
    $cache-path := repo-utils:config-value($config,'cache.path'),
    $static-path := repo-utils:config-value($config,'static.path')

return (xmldb:create-collection("/", $data-path),
        xmldb:create-collection("/", $metadata-path),
        xmldb:create-collection("/", $cache-path),
      	xmldb:copy(concat($conf-dir, '/', $conf, $static-dir), $data-path))
};

local:run-configs() 


