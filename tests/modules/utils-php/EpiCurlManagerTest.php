<?php

namespace jmathai\phpMultiCurl;

require_once __DIR__ . '/../../../modules/utils-php/EpiCurl.php';

/**
 * Test class for EpiCurlManager
 */

class EpiCurlManagerTest extends \PHPUnit_Framework_TestCase {

    /**
     * @var EpiCurlManager
     */
    protected $object;
    protected $epiCurlMock;
    protected $testKey = "T3stK3y";
    protected $realInst;

    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp() {
        $this->object = new EpiCurlManager($this->testKey);
        $this->epiCurlMock = $this->getMock(
               'EpiCurl',
               array("getResult"),
               array(),
               '',
               false);
        
        $this->epiCurlMock->expects($this->any())
                          ->method('getResult')
                          ->with($this->equalTo($this->testKey))
                          ->will($this->returnValue(array(                              
                            'data' => 'testData',
                            'headers' => array(),
                            'code' => 220,
                            'time' => CURLINFO_TOTAL_TIME,
                            'length' => CURLINFO_CONTENT_LENGTH_DOWNLOAD,
                            'type' => 'text/plain',
                            'url' => 'http://www.example.org'
        )));
        
        // Replace protected $inst reference with mock object
        $ref = new \ReflectionProperty('\jmathai\phpMultiCurl\EpiCurl', 'inst');
        $ref->setAccessible(true);
        $this->realInst = $ref->getValue();
        $ref->setValue(null, $this->epiCurlMock);
    }

    /**
     * Tears down the fixture, for example, closes a network connection.
     * This method is called after a test is executed.
     */
    protected function tearDown() {
        // undo replace protected $inst
        $ref = new \ReflectionProperty('\jmathai\phpMultiCurl\EpiCurl', 'inst');
        $ref->setAccessible(true);
        $ref->setValue(null, $this->realInst);
    }

    /**
     * @covers jmathai\phpMultiCurl\EpiCurlManager::__get
     * @todo   Implement test__get().
     */
    public function test__get() {
        $this->assertEquals('testData', $this->object->data);
        $this->assertInternalType('array', $this->object->headers);
        $this->assertEquals(220, $this->object->code);
        $this->assertEquals(CURLINFO_TOTAL_TIME, $this->object->time);
        $this->assertEquals(CURLINFO_CONTENT_LENGTH_DOWNLOAD, $this->object->length);
        $this->assertEquals('text/plain', $this->object->type);
        $this->assertEquals('http://www.example.org', $this->object->url);
    }

    /**
     * @covers jmathai\phpMultiCurl\EpiCurlManager::__isset
     * @todo   Implement test__isset().
     */
    public function test__isset() {
        $this->assertNotEmpty($this->object->data);
        $this->assertNotEmpty($this->object->code);
        $this->assertNotEmpty($this->object->time);
        $this->assertNotEmpty($this->object->type);
        $this->assertNotEmpty($this->object->url);
    }

}

