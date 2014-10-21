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

        $this->pr = __DIR__ . '/../../';
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
    public function it_should_run() {
        
    }    
}

