<?php

namespace tests\unit\ACDH\FCSSRU\switchAggregator;

use Tests\Common\XPathTestCase,
    Tests\Common\FCSSwitchParts,
    ACDH\FCSSRU\SRUWithFCSParameters,
    ACDH\FCSSRU\IndentDomDocument;

$runner = true;

require_once __DIR__ . '/../../../../../vendor/autoload.php';
require_once __DIR__ . '/../../../../common/XPathTestCase.php';
require_once __DIR__ . '/../../../../common/switchParts.php';

class FCSSwitchTest extends XPathTestCase {
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
     * @var ACDH\FCSSRU\IndentDomDocument
     */
    protected $df;

    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp() {
        global $sru_fcs_params;
        global $vlibPath;

        $this->pr = __DIR__ . '/../../../../../';
        $vlibPath = $this->pr . 'modules/utils-php/vlib/vlibTemplate.php';
        $sru_fcs_params = new SRUWithFCSParameters('lax');
        $sru_fcs_params->xformat = 'html';
        $sru_fcs_params->recordPacking = 'raw';
        $sru_fcs_params->operation = 'explain';
        $sru_fcs_params->xcontext = 'arz_eng_006';
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
     * @test
     */
    public function it_should_be_able_to_load_the_arz_eng_006_config() {
        global $sru_fcs_params;
        
        $configItem = $this->t->GetConfig($sru_fcs_params->xcontext);
        
        $this->assertNotFalse($configItem, 'It should be able to load the config.');
        $this->assertArrayHasKey('name', $configItem, 'It should be a valid config (no name?!).');
        $this->assertEquals('arz_eng_006', $configItem['name'], 'It should be the config for arz_eng_006.');
        $this->assertArrayHasKey('explain', $configItem, 'It should have an explain configuration available.');
    }
    
    /**
     * @test
     */
    public function it_should_be_able_to_load_the_arz_eng_006_glossary_explain_input() {
        $xmlDoc = $this->t->GetDomDocument($this->pr . 'xsl/tests/input/fcs/vicav_glossary_explain.xml');
        $this->assertNotFalse($xmlDoc, 'It should be able to load the input document.');
        $this->assertXPath('arz_eng_006',
                $xmlDoc, '/sru:explainResponse/sru:record/sru:recordData/zr:explain/zr:serverInfo/zr:database',
                'Input should explain arz_eng_006.');
    }
    /**
     * @test
     */
    public function it_should_be_able_transform_an_explain_input_for_arz_eng_006() {
        global $sru_fcs_params;

        $expectedFilename = $this->pr . 'xsl/tests/output-expected/fcs/vicav_glossary_explain.html';
        $expectedfile = fopen($expectedFilename, 'r');
        $this->assertNotFalse($expectedfile, 'A working expected file has to exist.');
        $this->df->loadXML(fread($expectedfile , filesize($expectedFilename)));
        fclose($expectedfile);
        $this->df->xmlIndent();
        $expected = $this->df->saveXML();   
        
        $configItem = $this->t->GetConfig($sru_fcs_params->xcontext);
        $xmlDoc = $this->t->GetDomDocument($this->pr . 'xsl/tests/input/fcs/vicav_glossary_explain.xml');
        $xslDoc = $this->t->GetXslStyleDomDocument($sru_fcs_params->operation, $configItem);
        $this->df->loadXML($this->t->ReturnXslT($xmlDoc, $xslDoc, true, false));
        $this->df->xmlIndent();
        $return = $this->df->saveXML();
  
        $this->assertXmlStringEqualsXmlString($expected, $return, 'it should run.');
    }
}