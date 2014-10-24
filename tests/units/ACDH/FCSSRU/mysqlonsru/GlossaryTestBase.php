<?php

namespace tests\unit\ACDH\FCSSRU\mysqlonsru;

use Tests\Common\XPathTestCase,
    ACDH\FCSSRU\SRUWithFCSParameters,
    ACDH\FCSSRU\IndentDomDocument;

$runner = true;

require_once __DIR__ . '/../../../../../modules/utils-php/common.php';
require_once __DIR__ . '/../../../../../vendor/autoload.php';
require_once __DIR__ . '/../../../../common/XPathTestCase.php';

abstract class GlossaryTestBase extends XPathTestCase {

    /**
     * @var FilteredGlossaryOnSRU
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
    
    protected $dbMock;
    protected $lineMock;
    
    protected $context = 'aeb_eng_001__v001';
    protected $params;
    
    protected function setUp() {
        global $vlibPath;
        
        $this->pr = __DIR__ . '/../../../../../';
        $vlibPath = $this->pr . 'modules/utils-php/vlib/vlibTemplate.php';
        
        $this->params = new SRUWithFCSParameters('lax');
        $this->params->recordPacking = 'raw';
        $this->params->operation = 'explain';
        $this->params->xcontext = $this->context;
        $this->params->context = array($this->context);
        
//        $this->dbMock = $this->getMock('mysqli',
        $this->dbMock = $this->getMock('NoRealClass',
                array('query', 'escape_string'));
        
        $this->df = new IndentDomDocument();
        $this->namespaces = array(
            'http://www.tei-c.org/ns/1.0' => 'tei',
            'http://clarin.eu/fcs/1.0' => 'fcs',
            'http://explain.z3950.org/dtd/2.0/' => 'zr',
        );
    }
            
    protected function setupDBMockForSqlScan($prefilter, $completeSql = null) {
        if (isset($completeSql)) {
            $this->expectedSqls = array(
                $completeSql
            );
        } else {
            $this->expectedSqls = array(
            "SELECT ndx.txt, base.entry, base.sid, COUNT(*) FROM $this->context AS base ".
            "INNER JOIN ".
                "(SELECT ndx.id, ndx.txt FROM ".
                $prefilter .
                "WHERE ndx.txt LIKE '%%' GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id  GROUP BY ndx.txt ORDER BY ndx.txt",            
            );
        }
        $this->dbMock->expects($this->exactly(1))->method('query')
                ->with($this->expectedSqls[0])
                ->willReturn(false);        
    }
    
    protected $expectedSqls = array();
    
    protected function setupDBMockForSqlSearch($prefilter) {
        $query = $this->params->query;
        $this->dbMock->expects($this->at(0))->method('escape_string')
                ->with($this->params->query)
                ->willReturn($this->params->query);
        $this->expectedSqls = array(
            "SELECT entry FROM $this->context WHERE id = 1",
            "SELECT COUNT(*)  FROM $this->context AS base ".
            "INNER JOIN ".
                "(SELECT ndx.id, ndx.txt FROM ".
                $prefilter .
                "WHERE ndx.txt LIKE '%$query%' GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id ",
            "SELECT ndx.txt, base.entry, base.sid, COUNT(*) FROM $this->context AS base ".
                "INNER JOIN ".
                "(SELECT ndx.id, ndx.txt FROM ".
                $prefilter .
                "WHERE ndx.txt LIKE '%$query%' GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id  GROUP BY base.sid LIMIT 0, 10"
        );
        $this->dbMock->expects($this->at(1))->method('query')
                ->with($this->expectedSqls[0])
                ->willReturn(false);
        $this->dbMock->expects($this->at(2))->method('query')
                ->with($this->expectedSqls[1])
                ->willReturn(false);
        $this->dbMock->expects($this->at(3))->method('query')
                ->with($this->expectedSqls[2])
                ->willReturn(false);      
    }
    

}

