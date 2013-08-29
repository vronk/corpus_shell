<?php
/**
 * 
 * 
 * @package config
 */

  /**
   * Loads the common configuration file
   */
  include "config.php";

  /**
   * Array containing all SRU diagnostic message texts
   * 
   * Using this array error numbers can be mapped to (english) messages.
   * @global array $errorMessages
   */
  $errorMessages = array (1   => "General system error",
                          2   => "System temporarily unavailable",
                          3   => "Authentication error",
                          4   => "Unsupported operation",
                          5   => "Unsupported version",
                          6   => "Unsupported parameter value",
                          7   => "Mandatory parameter not supplied",
                          8   => "Unsupported Parameter",
                          10  => "Query syntax error",
                          12  => "Too many characters in query",
                          13  => "Invalid or unsupported use of parentheses",
                          14  => "Invalid or unsupported use of quotes",
                          15  => "Unsupported context set",
                          16  => "Unsupported index",
                          18  => "Unsupported combination of indexes",
                          19  => "Unsupported relation",
                          20  => "Unsupported relation modifier",
                          21  => "Unsupported combination of relation modifers",
                          22  => "Unsupported combination of relation and index",
                          23  => "Too many characters in term",
                          24  => "Unsupported combination of relation and term",
                          26  => "Non special character escaped in term",
                          27  => "Empty term unsupported",
                          28  => "Masking character not supported",
                          29  => "Masked words too short",
                          30  => "Too many masking characters in term",
                          31  => "Anchoring character not supported",
                          32  => "Anchoring character in unsupported position",
                          33  => "Combination of proximity/adjacency and masking characters not supported",
                          34  => "Combination of proximity/adjacency and anchoring characters not supported",
                          35  => "Term contains only stopwords",
                          36  => "Term in invalid format for index or relation",
                          37  => "Unsupported boolean operator",
                          38  => "Too many boolean operators in query",
                          39  => "Proximity not supported",
                          40  => "Unsupported proximity relation",
                          41  => "Unsupported proximity distance",
                          42  => "Unsupported proximity unit",
                          43  => "Unsupported proximity ordering",
                          44  => "Unsupported combination of proximity modifiers",
                          46  => "Unsupported boolean modifier",
                          47  => "Cannot process query; reason unknown",
                          48  => "Query feature unsupported",
                          49  => "Masking character in unsupported position",
                          50  => "Result sets not supported",
                          51  => "Result set does not exist",
                          52  => "Result set temporarily unavailable",
                          53  => "Result sets only supported for retrieval",
                          55  => "Combination of result sets with search terms not supported",
                          58  => "Result set created with unpredictable partial results available",
                          59  => "Result set created with valid partial results available",
                          60  => "Result set not created: too many matching records",
                          61  => "First record position out of range",
                          64  => "Record temporarily unavailable",
                          65  => "Record does not exist",
                          66  => "Unknown schema for retrieval",
                          67  => "Record not available in this schema",
                          68  => "Not authorised to send record",
                          69  => "Not authorised to send record in this schema",
                          70  => "Record too large to send",
                          71  => "Unsupported record packing",
                          72  => "XPath retrieval unsupported",
                          73  => "XPath expression contains unsupported feature",
                          74  => "Unable to evaluate XPath expression",
                          80  => "Sort not supported",
                          82  => "Unsupported sort sequence",
                          83  => "Too many records to sort",
                          84  => "Too many sort keys to sort",
                          86  => "Cannot sort: incompatible record formats",
                          87  => "Unsupported schema for sort",
                          88  => "Unsupported path for sort",
                          89  => "Path unsupported for schema",
                          90  => "Unsupported direction",
                          91  => "Unsupported case",
                          92  => "Unsupported missing value action",
                          93  => "Sort ended due to missing value",
                          110 => "Stylesheets not supported",
                          111 => "Unsupported stylesheet",
                          120 => "Response position out of range",
                          121 => "Too many terms requested");
  
  
  /**
   * Returns a standard conform XML diagnostic messsage to the client
   *
   * Fills the diagnostic template with the selected error message and 
   * $diagnosticDetails and returns it to the client.
   * See alos: {@link http://www.loc.gov/standards/sru/specs/diagnostics.html}
   * @uses $version
   * @uses $vlibPath
   * @uses $diagnosticsTemplate
   * @uses $errorMessages
   * @param $diagnosticId
   * @param $diagnosticDetails
   */
  function Diagnostics($diagnosticId, $diagnosticDetails)
  {
    global $diagnosticsTemplate;
    global $version;
    global $vlibPath;

    global $errorMessages; 
    $diagnosticMessage = $errorMessages[$diagnosticId];

    require_once $vlibPath;

    header ("content-type: text/xml; charset=UTF-8");
    $tmpl = new vlibTemplate($diagnosticsTemplate);

    $tmpl->setvar('version', $version);
    $tmpl->setvar('diagnosticId', $diagnosticId);
    $tmpl->setvar('diagnosticMessage', $diagnosticMessage);
    $tmpl->setvar('diagnosticDetails', $diagnosticDetails);

    $tmpl->pparse();
  }
?>