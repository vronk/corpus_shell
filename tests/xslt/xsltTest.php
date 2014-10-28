<?php

namespace tests\xslt;

use Tests\Common\XPathTestCase,
    Tests\Common\FCSSwitchParts,
    ACDH\FCSSRU\SRUWithFCSParameters,
    ACDH\FCSSRU\IndentDomDocument;

$runner = true;

require_once __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/../common/XPathTestCase.php';
require_once __DIR__ . '/../common/switchParts.php';

class XSLTTests extends XPathTestCase {
    /// Switch response to HTML
    /**
     * @test
     */
    public function it_should_transform_a_switch_explain() {
        // html of switches explain has no wrapping div, so it's not valid xml.
        // Use the full page version instead.
        global $sru_fcs_params;
        global $scriptsUrl;
        
        $sru_fcs_params->xformat = 'htmlpagetable';
        $scriptsUrl = 'http://corpus3.aac.ac.at/vicav2/corpus_shell/scripts/';
        $this->doAssertTransformEqualsExpectedIndented("switch-explain",
                '', 'explain');
    }
    
    /**
     * @test
     */
    public function it_should_transform_a_switch_resources_scan() {
        $this->doAssertTransformEqualsExpectedIndented("switch-resource-scan",
                '', 'scan', 'fcs.resource');
    }
    
    /// Language profiles to HTML
    /**
     * @test
     */
    public function it_should_transform_a_vicav_profile_explain() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_profile_explain",
                'vicav_profiles_001', 'explain');
    }
    
    /// Glossary to HTML
    /**
     * @test
     */
    public function it_should_transform_a_vicav_glossary_explain() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_glossary_explain",
                'arz_eng_006', 'explain');
    }
    
    /**
     * @test
     */
    public function it_should_transform_a_single_vicav_glossary_entry_from_arz_eng_006() {
        $this->doAssertTransformEqualsExpectedIndented("vicav-entry", "arz_eng_006",
                "searchRetrieve", "cql.serverChoice==water");
    }
    
    /**
     * @test
     */
    public function it_should_transform_multiple_glossary_entries_from_apc_eng_002() {
       $this->doAssertTransformEqualsExpectedIndented("vicav_glossary_damascus", "apc_eng_002",
               "searchRetrieve", "water"); 
    }
    
    /**
     * @test
     */
    public function it_should_transform_multiple_glossary_entries_from_aeb_eng_001__v001() {
       $this->doAssertTransformEqualsExpectedIndented("vicav_glossary_tunisia", "aeb_eng_001__v001",
               "searchRetrieve", "water"); 
    }
    
    /// Tools texts
    /**
     * @test
     */
    public function it_should_transform_a_vicav_tools_explain() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_tools_explain", "vicav_tools_001", "explain");
    }
    
    /**
     * @test
     */
    public function it_should_transform_a_vicav_tools_scan_to_json() {
        global $sru_fcs_params;
        
        $sru_fcs_params->xformat = 'json';
        $this->t->GetDefaultStyles();
        
        $this->doAssertTransformEqualsExpectedJSON("vicav_tools_scan", "vicav_tools_001",
                "scan", "toolsText");
    }
    /**
     * @test
     */
    public function it_should_transform_vicav_tools_guidelines() {
       $this->doAssertTransformEqualsExpectedIndented("vicav_tools_guidelines", "vicav_tools_001",
               "searchRetrieve", "toolsText=Dictionary"); 
    }    
    /// Bibliography
    /**
     * @test
     */
    public function it_should_transform_a_vicav_bibliography_explain() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_bibliography_explain",
                'vicav_bibl_002', 'explain');
    }
    
    /**
     * @test
     */
    public function it_should_transform_a_vicav_bibliography_sousse() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_bibliography",
                'vicav_bibl_002', 'searchRetrieve', 'vicavTaxonomy=Sousse');
    }
    
    protected function doAssertTransformEqualsExpectedIndented($filename, $context, $operation, $searchOrScanClaus = null, $baseurl = null) {
        if (!isset($baseurl)) {
            $baseurl = 'http://corpus3.aac.ac.at/vicav2/corpus_shell//modules/fcs-aggregator/switch.php';
        }
        $expected = $this->getExpectedFileXML("$filename.html");
        $actual = $this->getActualTransformXML("$filename.xml",
                $context, $operation, $searchOrScanClaus, $baseurl);
        $expected->xmlIndent();
        $actual->xmlIndent();
        $this->assertEquals($expected->saveXML(), $actual->saveXML());        
    }
    
    protected function doAssertTransformEqualsExpectedJSON($filename, $context, $operation, $searchOrScanClaus = null, $baseurl = null) {
        if (!isset($baseurl)) {
            $baseurl = 'http://corpus3.aac.ac.at/vicav2/corpus_shell//modules/fcs-aggregator/switch.php';
        }
        $expected = $this->getExpectedFileJSON("$filename.json");
        $actual = $this->getActualTransformJSON("$filename.xml",
                $context, $operation, $searchOrScanClaus, $baseurl);
        $this->assertEquals($expected, $actual);
    }
    /**
     * @var FCSSwitchParts
     */
    protected $t;
    /**
     * Project root directory
     * @var string
     */
    protected $pr;
    /**
     *
     * @var array 
     */
    protected $xsltProcess;

    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp() {
        global $sru_fcs_params;
        global $vlibPath;

        $this->pr = __DIR__ . '/../../';
        $vlibPath = $this->pr . 'modules/utils-php/vlib/vlibTemplate.php';
        $sru_fcs_params = new SRUWithFCSParameters('lax');
        $sru_fcs_params->xformat = 'html';
        $sru_fcs_params->recordPacking = 'raw';
        $this->t = new FCSSwitchParts($this->pr);
        $this->t->GetDefaultStyles();
        $this->df = new IndentDomDocument();
        $this->namespaces = array(
            'http://www.tei-c.org/ns/1.0' => 'tei',
            'http://clarin.eu/fcs/1.0' => 'fcs',
            'http://explain.z3950.org/dtd/2.0/' => 'zr',
        );
    }

    /**
     * Tears down the fixture, for example, closes a network connection.
     * This method is called after a test is executed.
     */
    protected function tearDown() {
        global $sru_fcs_params;
        $sru_fcs_params = null;        
    }
    
    /**
     * @param string $filename
     * @return string
     */
    private function getExpectedFile($filename) {
        $expectedFilename = $this->pr . "xsl/tests/output-expected/fcs/$filename";
        $expectedfile = fopen($expectedFilename, 'r');
        $this->assertNotFalse($expectedfile, "A working expected file $expectedFilename has to exist.");
        $ret = fread($expectedfile , filesize($expectedFilename));
        fclose($expectedfile);
        return $ret;
    }
    
    /**
     * 
     * @param string $filename
     * @return ACDH\FCSSRU\IndentDomDocument
     */
    protected function getExpectedFileXML($filename) {
        $ret = new IndentDomDocument();
        $ret->setWhiteSpaceForIndentation(' ');
        $ret->loadXML($this->getExpectedFile($filename));
        return $ret;
    }

    /**
     * @param string $filename
     * @return array
     */
    protected function getExpectedFileJSON($filename) {
        $ret = json_decode($this->getExpectedFile($filename), true);
        $this->assertNotNull($ret, "Can not decode JSON in $filename.");
        return $ret;
    }
    
    /**
     * 
     * @global type $sru_fcs_params
     * @param string $inputFilename
     * @param string $xcontext
     * @param string $operation
     * @param string $queryOrScanClause
     * @param string $baseUrl
     * @return string The result of the transformation as a string or <b>FALSE</b> on error.
     */
    private function getActualTransform($inputFilename, $xcontext, $operation, $queryOrScanClause = null, $baseUrl = null) {
        global $sru_fcs_params;
        global $switchUrl;
        
        $savedSwitchUrl = $switchUrl;
        if (isset($baseUrl)) {
            $switchUrl = $baseUrl;
        }
        
        $sru_fcs_params->operation = $operation;
        $sru_fcs_params->xcontext = $xcontext;
        if (isset($queryOrScanClause)) {
            if ($operation === 'scan') {
                $sru_fcs_params->scanClause = $queryOrScanClause;
            }
            else {
                $sru_fcs_params->query = $queryOrScanClause;
            }
        }
        $configItem = $this->t->GetConfig($sru_fcs_params->xcontext);
        $this->assertTrue(is_array($configItem), "Couldn't load config for context $xcontext!");
        $xmlDoc = $this->t->GetDomDocument($this->pr . "xsl/tests/input/fcs/$inputFilename");
        $this->assertNotFalse($xmlDoc, "$inputFilename not found!");
        $xslDoc = $this->t->GetXslStyleDomDocument($sru_fcs_params->operation, $configItem);
        $this->assertNotFalse($xslDoc, "XSL for " . $sru_fcs_params->operation . " not found!");
        $ret = $this->t->ReturnXslT($xmlDoc, $xslDoc, true, false);
        $switchUrl = $savedSwitchUrl;
        return $ret;
    }

    /**
     * 
     * @global type $sru_fcs_params
     * @param string $inputFilename
     * @param string $xcontext
     * @param string $operation
     * @param string $queryOrScanClause
     * @param string $baseUrl
     * @return string The result of the transformation as a string or <b>FALSE</b> on error.
     * 
     */
    protected function getActualTransformXML($inputFilename, $xcontext, $operation, $queryOrScanClause = null, $baseUrl = null) {        
        $ret = new IndentDomDocument();
        $ret->setWhiteSpaceForIndentation(' ');
        $ret->loadXML($this->getActualTransform($inputFilename, $xcontext, $operation, $queryOrScanClause, $baseUrl));
        return $ret;        
    }

    /**
     * 
     * @global type $sru_fcs_params
     * @param string $inputFilename
     * @param string $xcontext
     * @param string $operation
     * @param string $queryOrScanClause
     * @param string $baseUrl
     * @return array
     * 
     */
    protected function getActualTransformJSON($inputFilename, $xcontext, $operation, $queryOrScanClause = null, $baseUrl = null) {
        $ret = json_decode($this->getActualTransform($inputFilename, $xcontext, $operation, $queryOrScanClause, $baseUrl), true);
        $this->assertNotNull($ret, "Transformed XML from $inputFilename should be valid JSON.");
        return $ret; 
    }
}

