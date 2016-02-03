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
        'entry' => "",
        'sense' => "(ndx.xpath LIKE '%-quote-')",
        'unit' => "(ndx.xpath LIKE '%-bibl-%Course-')",
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
        $this->params->operation = 'scan';
        $this->setupDBMockForSqlScan("$this->context"."_ndx AS ndx ");
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
    }
    
    /**
     * @test
     */
    public function it_should_use_the_right_sql_for_rfpid_scan() {
        $this->params->operation = 'scan';
        $this->params->scanClause = 'rfpid';
        $this->setupDBMockForSqlScan('', "SELECT id, entry, sid FROM $this->context ORDER BY CAST(id AS SIGNED)");
        $ret = $this->t->scan();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
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
    }
       
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_use_the_right_sql_for_search_sense_index($index) {
        $this->params->operation = 'searchRetrieve';
        $query = "$index=Öl";
        $this->params->query = $query;
        if (in_array($index, $this->columnBased)) {
            $this->setupDBMockForColumnBasedSqlSearch($this->columnForIndex[$index]);
        } else {
            $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ", $this->ndxAndCondiction[$index], in_array($index, $this->onlyExactMatches));
        }
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
    }
    
    /**
     * @test
     * @dataProvider searchableIndexesProvider
     */
    public function it_should_use_the_right_sql_for_search_complex_cql($index) {
        $this->params->operation = 'searchRetrieve';
        $query = $index.' == "a car"';
        $this->params->query = $query;
        if (in_array($index, $this->columnBased)) {
            $this->setupDBMockForColumnBasedSqlSearch($this->columnForIndex[$index]);
        } else {
            $this->setupDBMockForSqlSearch("$this->context"."_ndx AS ndx ", $this->ndxAndCondiction[$index], true);
        }
        $ret = $this->t->search();
        $this->assertInstanceOf('ACDH\FCSSRU\SRUDiagnostics', $ret);
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
    }
    
    protected function changeContext($anotherContext) {
        $this->context = $anotherContext;
        $this->params->xcontext = $anotherContext;
        $this->params->context[0] = $anotherContext;
    }
    
    protected function getReleasedPrefilter() {
        return "(SELECT tab.id, tab.xpath, tab.txt FROM $this->context"."_ndx AS tab ".
                     "INNER JOIN ".
                        "(SELECT inner.id FROM $this->context"."_ndx AS `inner` ".
                        "WHERE inner.txt = 'released' ".
                        "AND inner.xpath LIKE '%-change-f-status-') AS prefid ".
                     "ON tab.id = prefid.id WHERE tab.txt != '-') AS ndx ";
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
