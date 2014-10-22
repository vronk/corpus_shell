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
    
    /**
     * @test
     */
    public function it_should_transform_a_vicav_profile_explain() {
        $this->doAssertTransformEqualsExpectedIndented("vicav_profile_explain",
                'vicav_profiles_001', 'explain');
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
        $expected = $this->getExpectedFile("$filename.html");
        $actual = $this->getActualTransform("$filename.xml",
                $context, $operation, $searchOrScanClaus, $baseurl);
        $expected->xmlIndent();
        $actual->xmlIndent();
        $this->assertEquals($expected->saveXML(), $actual->saveXML());    }
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
     * 
     * @param string $filename
     * @return ACDH\FCSSRU\IndentDomDocument
     */
    protected function getExpectedFile($filename) {
        $ret = new IndentDomDocument();
        $ret->setWhiteSpaceForIndentation(' ');
        $expectedFilename = $this->pr . "xsl/tests/output-expected/fcs/$filename";
        $expectedfile = fopen($expectedFilename, 'r');
        $this->assertNotFalse($expectedfile, "A working expected file $filename has to exist.");
        $ret->loadXML(fread($expectedfile , filesize($expectedFilename)));
        fclose($expectedfile);
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
     * @return ACDH\FCSSRU\IndentDomDocument
     */
    protected function getActualTransform($inputFilename, $xcontext, $operation, $queryOrScanClause = null, $baseUrl = null) {
        global $sru_fcs_params;
        global $switchUrl;
        
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
        $savedSwitchUrl = $switchUrl;
        if (isset($baseUrl)) {
            $switchUrl = $baseUrl;
        }
        $ret = new IndentDomDocument();
        $ret->setWhiteSpaceForIndentation(' ');
        $configItem = $this->t->GetConfig($sru_fcs_params->xcontext);
        $this->assertTrue(is_array($configItem), "Couldn't load config for context $xcontext!");
        $xmlDoc = $this->t->GetDomDocument($this->pr . "xsl/tests/input/fcs/$inputFilename");
        $this->assertNotFalse($xmlDoc, "$inputFilename not found!");
        $xslDoc = $this->t->GetXslStyleDomDocument($sru_fcs_params->operation, $configItem);
        $this->assertNotFalse($xslDoc, "XSL for " . $sru_fcs_params->operation . " not found!");
        $ret->loadXML($this->t->ReturnXslT($xmlDoc, $xslDoc, true, false));
        $switchUrl = $savedSwitchUrl;
        return $ret;
    }
}

