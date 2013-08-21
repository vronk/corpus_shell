
/**
 * @fileOverview a default version of the params-file for instance specific configuration.
 * Makes things work just pointing a CORS compatible Browser (non-IE, IE >= 10) at the
 * local copy. The switch URL is a temporary reverse proxy solution.
 */

/**
 * @module corpus_shell 
 */

/** Base url or where do we live. Does not make much sense on a locally downloaded copy.
 * @type {path|url}  
 */
var baseURL = ".";
/** The place where the php scripts for user data management live (see the modules/userdata sub directory). It's assumend this is a path which needs to be added to baseUrl.
 * @type {path}
 */
var userData = "/modules/userdata/";
/** The url of the switch script. May be anywhere on the internet if cross-origin resource shareing (CORS, see enable-cors.org) is properly set up.
 * @type {url} 
 */
var switchURL = "http://corpus3.aac.ac.at/switch";
