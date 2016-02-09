<?php

namespace tests\unit\ACDH\FCSSRU\mysqlonsru;

use ACDH\FCSSRU\mysqlonsru\GlossaryOnSRU,
    ACDH\FCSSRU\SRUWithFCSParameters,
    ACDH\FCSSRU\IndentDomDocument;

$runner = true;

require_once __DIR__ . '/GlossaryTestBase.php';
require_once __DIR__ . '/../../../../../vendor/autoload.php';
// this is not autoload enabled yet. There are to many magic global constants that need to be set when loading.
require_once __DIR__ . '/../../../../../modules/mysqlonsru/GlossaryOnSRU.php';

class GlossaryOnSRUTest extends GlossaryTestBase {
    
    protected $ndxAndCondiction = array(        
        '' => '',
        'serverChoice' => '',
        'cql.serverChoice' => '',
        'entry' => '',
        'sense' => "(ndx.xpath LIKE '%-quote-')",
        'sense-en' => "//cit[@xml:lang=\"en\"]//text()",
        'sense-de' => "//cit[@xml:lang=\"de\"]//text()",
        'sense-es' => "//cit[@xml:lang=\"es\"]//text()",
        'sense-fr' => "//cit[@xml:lang=\"fr\"]//text()",
        'unit' => "(ndx.xpath LIKE '%-bibl-%Course-')",
        'xmlid' => "(ndx.xpath LIKE '%-xml:id')"        
    );
    protected $onlyExactMatches = array('unit');
    protected $columnBased = array('xmlid', 'rfpid'); 
    protected $columnForIndex = array(
       'rfpid' => 'id',
       'xmlid' => 'sid',
    );

    public function __construct($name = null, array $data = array(), $dataName = '') {
        parent::__construct($name, $data, $dataName);
        $this->context = 'arz_eng_06';
    }
    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp() {
        parent::setUp();
        $this->t = new GlossaryOnSRU($this->params);
        
        $ref = new \ReflectionProperty('ACDH\FCSSRU\mysqlonsru\GlossaryOnSRU', 'db');
        $ref->setAccessible(true);
        $ref->setValue($this->t, $this->dbMock);
    }

    /**
     * Tears down the fixture, for example, closes a network connection.
     * This method is called after a test is executed.
     */
    protected function tearDown() {
        $this->params = null;      
    }

    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_explain() {
        $this->dbMock->expects($this->exactly(1))->method('query')
                ->with("SELECT entry FROM $this->context WHERE id = 1")
                ->willReturn(false);
        $ret = $this->t->explain();
        $this->assertInstanceOf('ACDH\\FCSSRU\\Http\\Response', $ret);
        $this->assertNotEquals('', $ret->getBody());
    }

    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_scan() {
       $this->it_should_use_the_right_sql_for_scan_with_an_index(''); 
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_use_the_right_sql_for_scan_with_an_index($index) {
        $this->params->operation = 'scan';
        $this->params->scanClause = $index;
        if ($index === 'rfpid') { # expected it to be in_array($index, $this->columnBased)
            $this->setupDBMockForSqlScan('', '', "SELECT id, entry, sid FROM $this->context ORDER BY CAST(id AS SIGNED)");
        } elseif (($this->ndxAndCondiction[$index] !== '') && ($this->ndxAndCondiction[$index][0] === '/')) {//[.=\"a car\"]
            $this->setupDBMockForSqlScan($this->getXPathPrefilter($index), $this->ndxAndCondiction[$index]);
        } else {
            $this->setupDBMockForSqlScan("$this->context"."_ndx AS ndx ", $index === '' ? '' : $this->ndxAndCondiction[$index]);
        }
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, 'it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
       
    protected function getPrefilter($innerPart) {
        return "(SELECT tab.id, tab.xpath, prefid.txt FROM $this->context"."_ndx AS tab ".
                     "INNER JOIN ".
                     $innerPart.
                     "ON tab.id = prefid.id WHERE tab.txt != '-') AS ndx ";
    }
    
    protected function getXPathPrefilter($index, $query = '', $exact = null) {
        if ($exact === null) {
            $predicate = '';
        } else {
            $predicate = '['.($exact === true ? ".=\"$query\"" : "contains(., \"$query\")").']';
        }
        $xPathInnerPart =
        "(SELECT base.id, ExtractValue(base.entry, '".$this->ndxAndCondiction[$index].$predicate."') AS 'txt' ".
        "FROM $this->context AS base GROUP BY base.id HAVING txt != '') AS ndx ";
        return $xPathInnerPart;
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_not_accept_any_operator_for_scan($index) {
        if ($index === '') { return; } // this doesn't work, is according to spec.       
        $this->params->operation = 'scan';
        $this->params->scanClause = $index.'<=error';
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, '<=: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 4, '<=: it should report an unsupported operation!');       
        $this->params->operation = 'scan';
        $this->params->scanClause = $index.' someop error';
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, 'someop: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 4, 'someop: it should report an unsupported operation!');           
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_not_accept_invalid_indexes_for_scan($index) {       
        $this->params->operation = 'scan';
        $this->params->scanClause = $index.'Invaliddate';
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, $index.'Invaliddate: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 51, $index.'Invaliddate: it should report result set does not exist!');
        $this->params->scanClause = $index.'Invaliddate==something';
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, $index.'Invaliddate==something: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 51, $index.'Invaliddate==something: it should report result set does not exist!');  
        $this->params->scanClause = $index.'Invaliddate exact something';
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, $index.'Invaliddate exact something: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 51, $index.'Invaliddate exact something: it should report result set does not exist!');             
    }    
    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_search() {
        $this->params->operation = 'searchRetrieve';
        $query = 'waer';
        $this->params->query = $query;
        $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ");
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
    
    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_search_with_unicode_characters() {
        $this->params->operation = 'searchRetrieve';
        $query = 'ṃāžžix';
        $this->params->query = $query;
        $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ");
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
       
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_use_the_right_sql_for_wildcard_searching_some_index($index) {
        $this->params->operation = 'searchRetrieve';
        $searchTerm = "Öl";
        $query = $index.($index === '' ? '' : '=').$searchTerm;
        $this->params->query = $query;
        if (in_array($index, $this->columnBased)) {
            $this->setupDBMockForColumnBasedSqlSearch($this->columnForIndex[$index]);
        } elseif (($this->ndxAndCondiction[$index] !== '') && ($this->ndxAndCondiction[$index][0] === '/')) {
        $this->setupDBMockForSqlSearch($this->getXPathPrefilter($index, $searchTerm, false),
            $this->ndxAndCondiction[$index], in_array($index, $this->onlyExactMatches));
        } else {
            $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ", $this->ndxAndCondiction[$index], in_array($index, $this->onlyExactMatches));
        }
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_use_the_right_sql_for_exact_searching_complex_cql($index) {
        if ($index === '') { return; } // this doesn't work, is according to spec.
        $searchTerm = 'a car';
        $this->params->operation = 'searchRetrieve';
        $query = $index." == \"$searchTerm\"";
        $this->params->query = $query;
        if (in_array($index, $this->columnBased)) {
            $this->setupDBMockForColumnBasedSqlSearch($this->columnForIndex[$index]);
        } elseif (($this->ndxAndCondiction[$index] !== '') && ($this->ndxAndCondiction[$index][0] === '/')) {//[.=\"a car\"]
        $this->setupDBMockForSqlSearch($this->getXPathPrefilter($index, $searchTerm, true),
            $this->ndxAndCondiction[$index], in_array($index, $this->onlyExactMatches));
        } else {
            $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ", $this->ndxAndCondiction[$index], true);
        }
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
    
    /**
     * @xtest
     */
    public function it_should_use_the_right_sql_for_search_complex_cql_2() {
        $this->params->operation = 'searchRetrieve';
        $query = 'entry exact "a car"';
        $this->params->query = $query;
        $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ", '', true);
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
        $this->assertEquals($ret->getDiagnosticId(), 1, 'it should report an genreal system error because the mock does not return data!');
    }
        
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_not_accept_any_operator_for_search($index) {
        if ($index === '') { return; } // this doesn't work, is according to spec.  
        $this->params->operation = 'searchRetrieve';
        $this->params->query = $index.' someop error';
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, 'someop: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 4, 'someop: it should report an unsupported operation!');           
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_not_accept_invalid_indexes_for_search($index) {       
        $this->params->operation = 'searchRetrieve';
        $this->params->scanClause = $index.'Invaliddate==something';
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, $index.'Invaliddate==something: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 51, $index.'Invaliddate==something: it should report result set does not exist!');  
        $this->params->scanClause = $index.'Invaliddate exact something';
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret, $index.'Invaliddate exact something: it should return a diagnostics object!');
        $this->assertEquals($ret->getDiagnosticId(), 51, $index.'Invaliddate exact something: it should report result set does not exist!');             
    } 
    
    protected function changeContext($anotherContext) {
        $this->context = $anotherContext;
        $this->params->xcontext = $anotherContext;
        $this->params->context[0] = $anotherContext;
    }
    
    protected function getReleasedPrefilter() {
        $releasedInnerPart = "(SELECT inner.id, inner.txt FROM $this->context"."_ndx AS `inner` ".
                        "WHERE inner.txt = 'released' ".
                        "AND inner.xpath LIKE '%-change-f-status-') AS prefid ";
        return $this->getPrefilter($releasedInnerPart);                        
    }

    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_restricted_scan() {
        $this->params->operation = 'scan';
        $restrictedContext = 'aeb_eng_001__v001';
        $this->changeContext($restrictedContext);
        $this->setupDBMockForSqlScan($this->getReleasedPrefilter());
        
        $ret = $this->t->scan();
        
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
    }
        
    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_restricted_search() {
        $this->params->operation = 'searchRetrieve';
        $query = 'waer';
        $this->params->query = $query;
        $restrictedContext = 'aeb_eng_001__v001';
        $this->changeContext($restrictedContext);
        $this->setupDBMockForSqlSearch($this->getReleasedPrefilter());
        
        $ret = $this->t->search();
        
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
    }
}
