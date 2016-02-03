<?php

namespace tests\unit\ACDH\FCSSRU\mysqlonsru;

use Tests\Common\XPathTestCase,
    Tests\Common\SRUFromMysqlParts,
    ACDH\FCSSRU\SRUWithFCSParameters,
    ACDH\FCSSRU\IndentDomDocument,
    ACDH\FCSSRU\mysqlonsru\GlossaryOnSRU;

$runner = true;

require_once __DIR__ . '/../../../../../modules/utils-php/common.php';
require_once __DIR__ . '/../../../../../vendor/autoload.php';
require_once __DIR__ . '/../../../../common/XPathTestCase.php';
require_once __DIR__ . '/../../../../common/SRUFromMysqlParts.php';

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
    protected $protectedSRUFromMysql;
    
    protected function setUp() {
        global $vlibPath;
        
        $this->pr = __DIR__ . '/../../../../../';
        $vlibPath = $this->pr . 'modules/utils-php/vlib/vlibTemplate.php';
        
        $this->params = new SRUWithFCSParameters('lax');
        $this->params->recordPacking = 'raw';
        $this->params->operation = 'explain';
        $this->params->xcontext = $this->context;
        $this->params->context = array($this->context);
        
        $this->protectedSRUFromMysql = new SRUFromMysqlParts($this->params);
        
//        $this->dbMock = $this->getMock('mysqli',
        $this->dbMock = $this->getMock('NoRealClass',
                array('query', 'escape_string'));
        $this->dbMock->error = 'Mock: no error.';
        
        $this->df = new IndentDomDocument();
        $this->namespaces = array(
            'http://www.tei-c.org/ns/1.0' => 'tei',
            'http://clarin.eu/fcs/1.0' => 'fcs',
            'http://explain.z3950.org/dtd/2.0/' => 'zr',
        );
    }
            
    protected function setupDBMockForSqlScan($prefilter, $ndxAndCondition = '', $completeSql = null) {
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
                "WHERE ".$this->protectedSRUFromMysql->_and("ndx.txt LIKE '%' ", $ndxAndCondition)."GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id WHERE ndx.id > 700 GROUP BY ndx.txt ORDER BY ndx.txt",            
            );
        }
        $this->dbMock->expects($this->exactly(1))->method('query')
                ->with($this->expectedSqls[0])
                ->willReturn(false);        
    }
    
    protected $expectedSqls = array();
    
    protected function setupMockAndGetDBQueryString() {
        $splitted = $this->findCQLParts();
        $dbquery = preg_replace('/"([^"]*)"/', '$1', $splitted['searchClause'] !== '' ? $splitted['searchClause'] : $this->params->query);
        $this->dbMock->expects($this->at(0))->method('escape_string')
                ->with($dbquery)
                ->willReturn($dbquery);
        return $dbquery;
    }
    
    protected function setupExpectedMockSql($search) {       
        $this->expectedSqls = $search;
        for ($i = 0; $i < count($this->expectedSqls); $i++) {
            $this->dbMock->expects($this->at($i + 1))->method('query')
                         ->with($this->expectedSqls[$i])
                         ->willReturn(false);
        }
    }
    
    protected function setupDBMockForSqlSearch($prefilter, $ndxAndCondition = '', $exact = false) {
        $dbquery = $this->setupMockAndGetDBQueryString();
        $qEnc = $this->protectedSRUFromMysql->encodecharrefs($dbquery); 
        $anyWhere = "(ndx.txt LIKE '%$dbquery%' OR ndx.txt LIKE '%$qEnc%') ";        
        $exactWhere = "(ndx.txt = '$dbquery' OR ndx.txt = '$qEnc') ";
        $search = array(
            "SELECT entry FROM $this->context WHERE id = 1",
            "SELECT COUNT(*)  FROM $this->context AS base ".
            "INNER JOIN ".
                "(SELECT ndx.id, ndx.txt FROM ".
                $prefilter .
                "WHERE ". $this->protectedSRUFromMysql->_and($exact ? $exactWhere : $anyWhere, $ndxAndCondition).
                "GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id WHERE ndx.id > 700",
            "SELECT ndx.txt, base.entry, base.sid, COUNT(*) FROM $this->context AS base ".
                "INNER JOIN ".
                "(SELECT ndx.id, ndx.txt FROM ".
                $prefilter .
                "WHERE ". $this->protectedSRUFromMysql->_and($exact ? $exactWhere : $anyWhere, $ndxAndCondition).
                "GROUP BY ndx.id) AS ndx ".
            "ON base.id = ndx.id WHERE ndx.id > 700 GROUP BY base.sid LIMIT 0, 10"
        );
        $this->setupExpectedMockSql($search);
    }
    
    protected function setupDBMockForColumnBasedSqlSearch($column) {
        $dbquery = $this->setupMockAndGetDBQueryString();
        $search = array(
            "SELECT entry FROM $this->context WHERE id = 1",
            "SELECT $column, entry, ".($column === 'id' ? 'sid' : 'id').", 1 FROM $this->context WHERE $column='$dbquery'"
            );
        $this->setupExpectedMockSql($search);        
    }
    
    protected function findCQLParts() {
        $cqlIdentifier = '("([^"])*")|([^\s()=<>"\/]*)';
        $matches = array();
        $regexp = '/(?<index>'.$cqlIdentifier.') *(?<operator>(==?)|(>=?)|(<=?)|('.$cqlIdentifier.')) *(?<searchClause>'.$cqlIdentifier.')/';
        preg_match($regexp, $this->params->query, $matches);
        return $matches;
    }
    
    protected function getAllIndexes($typeOfIndex) {
        $params = new SRUWithFCSParameters('explain');
        $context = 'dummy_dummy';
        $params->context[0] = $context;
        $glossary = new GlossaryOnSRU($params);
        $dbMock = $this->getMock('NoRealClass',
                array('query', 'escape_string'));
        $dbMock->error = 'Mock: no error.';
        $dbMock->expects($this->exactly(1))->method('query')
                ->with("SELECT entry FROM $context WHERE id = 1")
                ->willReturn(false);       
        $ref = new \ReflectionProperty('ACDH\FCSSRU\mysqlonsru\GlossaryOnSRU', 'db');
        $ref->setAccessible(true);
        $ref->setValue($glossary, $dbMock);
        $explain = $glossary->explain();
        $xml = new \DOMDocument();
        $xml->loadXML($explain->getBody());
        try {
            $xml->createAttributeNS('http://explain.z3950.org/dtd/2.0/', 'zr:create-ns');    
        } catch (\DOMException $exc) {}
        $xmlSearcher = new \DOMXPath($xml);
        $indexes = $xmlSearcher->query('//zr:index[@'.$typeOfIndex.'="true"]/zr:map/zr:name[@set="fcs"]/text()');
        $ret = array();
        foreach ($indexes as $index) {
            $ret['index '.$index->textContent] = array($index->textContent);
        }
        return $ret;
    }
        
    public function searchableIndexesProvider() {
        return $this->getAllIndexes('search');        
    }
        
    public function scanableIndexesProvider() {
        return $this->getAllIndexes('scan');        
    }
    
    public function sortableIndexesProvider() {
        return $this->getAllIndexes('sort');        
    }
    
    public function nativeIndexesProvider() {
        return $this->getAllIndexes('native');        
    }
}

