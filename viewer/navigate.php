<?php
    $thisUrl = "http://corpus3.aac.ac.at/cs2/corpus_shell/viewer/navigate.php";
    $localhost = "corpus3.aac.ac.at";
    $configUrl = "../fcs/aggregator/switch.config";
    $fcsConfig = "../fcs/aggregator/fcs.resource.config.php";
    $fcsConfigFound = false;

    //import fcs configuration cache
    if (file_exists($fcsConfig))
    {
      include $fcsConfig;
      $fcsConfigFound = true;
    }

    //to speed up local queries the local servername ($localhost) is replaced
    //by the term "localhost"
    function ReplaceLocalHost($url)
    {
      global $localhost;
      return str_replace($localhost, "localhost",  $url);
    }

    //like file_exists() but working with urls
    function url_exists($url)
    {
        $handle = @fopen($url,'r');
        return ($handle !== false);
    }

    //returns the node value of the first fitting tag with $tagName
    //processes the descendants of $node only
    function GetNodeValue($node, $tagName)
    {
       $list = $node->getElementsByTagName($tagName);
       if ($list->length != 0)
       {
         $value = $list->item(0);
         return $value->nodeValue;
       }
       return "";
    }

    //opens $configUrl and searches for an <item> with a <name> value that
    //equals $context - returns configuration infos for the found node in
    //an array
    function GetConfig($context)
    {
      global $configUrl;
      $doc = new DOMDocument;
      $doc->Load($configUrl);

      $xpath = new DOMXPath($doc);
      $query = '//item';
      $entries = $xpath->query($query);

      foreach ($entries as $entry)
      {
         $name = GetNodeValue($entry, "name");
         if ($name == $context)
         {
           $type = GetNodeValue($entry, "type");
           $uri = GetNodeValue($entry, "uri");
           $style = GetNodeValue($entry, "style");
           return array("name" => $name, "type" => $type, "uri" => $uri, "style" => $style);
         }
      }

      //context not found in switch.config
      //have a look in fcsConfig - if it does exist!
      global $fcsConfigFound;

      if ($fcsConfigFound)
      {
        global $configName;

        if (array_key_exists($context, $configName))
        {
          $conf = $configName[$context];
          return array("name" => $conf["name"], "type" => $conf["type"], "uri" => $conf["endPoint"], "style" => $conf["style"]);
        }
      }
      print "not found!";
      return false;
    }

    //concats $url with the given $paramName and $paramValue
    function AddParamToUrl($url, $paramName, $paramValue)
    {
      return $url . ($url == "?" ? "" : "&") . "$paramName=$paramValue";
    }

    function GetDomDocument($url)
    {
      $url = ReplaceLocalHost($url);

      if (url_exists($url))
      {
        $xmlDoc = new DOMDocument();
        $xmlDoc->load($url);

        return $xmlDoc;
      }

      return false;
    }

    //get resource
    //eg: x-context=clarin.at:icltt:cr:stb|1879-04-27

    if (isset($_GET['x-context'])) $xcontext = $_GET["x-context"]; else $xcontext = "";

    $fragment = "";
    //look for resource fragment in $xcontext
    $pos = strpos($xcontext, '|');

    if (($xcontext != "") && ($pos !== false))
    {
      $fragment = substr($xcontext, $pos + 1);
      $xcontext = substr($xcontext, 0, $pos);
    }

    //get endpoint from config file

    $configItem = GetConfig($xcontext);

    if ($configItem !== false)
    {
      $endpoint = $configItem["uri"];

      //get explain
      //eg: http://clarin.aac.ac.at/cr?operation=explain&x-context=clarin.at:icltt:cr:stb

      $explainUrl = AddParamToUrl("?","x-context", $xcontext);
      $explainUrl = AddParamToUrl($explainUrl,"operation", "explain");
      $explainUrl = $endpoint . $explainUrl;

      //result should contain:

      //<index search="true" scan="true" sort="false"><title lang="en">diary day</title><title lang="de">Tagebuch Tage</title><map><name set="fcs">diary-day</name></map></index>
      //<configInfo><setting type="naviIndex">diary-day</setting></configInfo>

      $indexName = "";
      $indexDisplayText = "";

      $doc = GetDomDocument($explainUrl);
      if ($doc !== false)
      {
        $xpath = new DOMXpath($doc);
        $elements = $xpath->query("//configInfo/setting[@type='naviIndex']");

        if (!is_null($elements) && $elements->length != 0)
        {
          $element = $elements->item(0);
          $indexName = $element->nodeValue;
        }

        if ($indexName != "")
        {
          $elements = $xpath->query("//index/map/name[.='diary-day']/../../title[@lang='en']");
          if (!is_null($elements) && $elements->length != 0)
          {
            $element = $elements->item(0);
            $indexDisplayText = $element->nodeValue;
          }
          //get scan
          //eg: http://clarin.aac.ac.at/cr?operation=scan&x-context=clarin.at:icltt:cr:stb&scanClause=diary-day=1879-04-27&responsePosition=2&maximumTerms=3

          $scanUrl = AddParamToUrl("?", "x-context", $xcontext);
          $scanUrl = AddParamToUrl($scanUrl, "operation", "scan");
          $scanUrl = AddParamToUrl($scanUrl, "responsePosition", "2");
          $scanUrl = AddParamToUrl($scanUrl, "maximumTerms", "3");
          $scanUrl = AddParamToUrl($scanUrl, "scanClause", "$indexName=$fragment");
          $scanUrl = $endpoint . $scanUrl;

          //result should look like this...
          //<sru:scanResponse><sru:version>1.2</sru:version>
          //<sru:terms>
          //<sru:term><sru:value>1879-04-26</sru:value><sru:numberOfRecords>1</sru:numberOfRecords><extraTermData><fcs:position>1</fcs:position></extraTermData></sru:term>
          //<sru:term><sru:value>1879-04-27</sru:value><sru:numberOfRecords>1</sru:numberOfRecords><extraTermData><fcs:position>1</fcs:position></extraTermData></sru:term>
          //<sru:term><sru:value>1879-04-28</sru:value><sru:numberOfRecords>1</sru:numberOfRecords><extraTermData><fcs:position>1</fcs:position></extraTermData></sru:term>
          //</sru:terms><sru:echoedScanRequest><sru:scanClause>diary-day=1879-04</sru:scanClause><sru:maximumTerms>50</sru:maximumTerms></sru:echoedScanRequest></sru:scanResponse>

          $doc = GetDomDocument($scanUrl);

          if ($doc !== false)
          {
            $xpath = new DOMXpath($doc);
            $elements = $xpath->query("//sru:term/sru:value");

            if (!is_null($elements) && $elements->length == 3)
            {
              //generate xml with next & prior tags
              $xmlResult = '<?xml version="1.0"?>';
              $xmlResult = '<items displayText="' . $indexDisplayText . '">';
              $element1 = $elements->item(0);
              $xmlResult .= '  <item type="prev">' . $element1->nodeValue . '</item>';
              $element2 = $elements->item(1);
              $xmlResult .= '  <item type="current">' . $element2->nodeValue . '</item>';
              $element3 = $elements->item(2);
              $xmlResult .= '  <item type="next">' . $element3->nodeValue . '</item>';
              $xmlResult .= '</items>';

              $htmlResult = "<div>";
              $htmlResult .= "  <div class=\"nav\">";
              $htmlResult .= '    <a class="navi" href="' . $thisUrl . '?x-context='. $xcontext. "|" . $element1->nodeValue . '">&lt;' . $element1->nodeValue . '</a>';
              $htmlResult .= '    <span class="item">' . $element2->nodeValue . '</a>';
              $htmlResult .= '    <a class="navi" href="' . $thisUrl . '?x-context='. $xcontext. "|" . $element3->nodeValue . '">' . $element3->nodeValue . '&gt;</a>';
              $htmlResult .= "  </div>";
              $htmlResult .= "  <div class=\"content\">";

              $searchUrl = AddParamToUrl("?", "x-context", $xcontext);
              $searchUrl = AddParamToUrl($searchUrl, "operation", "searchRetrieve");
              $searchUrl = AddParamToUrl($searchUrl, "maximumRecords", "1");
              $searchUrl = AddParamToUrl($searchUrl, "x-format", "htmldetail");
              $searchUrl = AddParamToUrl($searchUrl, "query", $indexName."=".$element2->nodeValue);
              $searchUrl = AddParamToUrl($searchUrl, "x-dataview", "full");
              $searchUrl = $endpoint . $searchUrl;
              //$htmlResult .= $searchUrl;

              $lines = file($searchUrl);
              foreach ($lines as $line)
              {
                $htmlResult .= $line;
              }

              $htmlResult .= "  </div>";
              $htmlResult .= "</div>";
            }
          }

          //depending on an optional param, return xml ...

          if ($resultType=="xml")
          {
            header("content-type: text/xml; charset=UTF-8");
            print $xmlResult;
          }
          else
          // ... or html (default)
          {
            header("content-type: text/html; charset=UTF-8");
            print $htmlResult;
          }
        }
      }
    }
?>