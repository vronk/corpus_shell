<?php
namespace jmathai\phpMultiCurl;

require_once __DIR__ . '/../../../modules/utils-php/EpiCurl.php';

class EpiCurlTest extends \PHPUnit_Framework_TestCase {
    
    /**
     * @var EpiCurl
     */
    protected $object;

    /**
     * Sets up the fixture, for example, opens a network connection.
     * This method is called before a test is executed.
     */
    protected function setUp() {
        $this->object = EpiCurl::getInstance();
    }

    /**
     * Tears down the fixture, for example, closes a network connection.
     * This method is called after a test is executed.
     */
    protected function tearDown() {
        
    }
    
    /**
     * @covers jmathai\phpMultiCurl\EpiCurl::getInstance
     */
    public function testGetInstance() {
        $this->assertEquals($this->object, EpiCurl::getInstance());
    }

    /**
     * @covers jmathai\phpMultiCurl\EpiCurl::addCurl
     */
    public function testAddCurl() {
        $this->markTestSkipped('Code stops PHPUnit, check!');
        return;
        $epiCurlManager = $this->object->addCurl(curl_init("http://localhost:41337"));
        $exampleOrg200 = $this->object->addCurl(curl_init("http://www.example.org"));
        $exampleOrg404 = $this->object->addCurl(curl_init("http://www.example.org/nonexistent"));
        $this->assertEquals(200, $exampleOrg200->code);
        $this->assertEquals(404, $exampleOrg404->code);
        // www.example.org always shows the same hint on what it's purpose is.
        $this->assertEquals($exampleOrg200->data, $exampleOrg404->data);
        $this->assertNull($epiCurlManager->code);
    }
    
    /**
     * @covers jmathai\phpMultiCurl\EpiCurl::cleanupResponses
     */
    public function testCleanupResponses() {
        $this->markTestSkipped('Code stops PHPUnit, check!');
        return;
        $exampleOrg200 = $this->object->addCurl(curl_init("http://www.example.org"));
        $exampleOrg404 = $this->object->addCurl(curl_init("http://www.example.org/nonexistent"));
        $this->assertInternalType('array', $exampleOrg404->headers);
        $exampleOrg200Headers = $exampleOrg200->headers;
        $this->assertArrayHasKey('Content-Length', $exampleOrg200Headers);
        $this->assertArrayHasKey('Content-Type', $exampleOrg200->headers);
        $this->assertEquals("text/html", $exampleOrg200->headers["Content-Type"]);
        $this->assertEquals(200, $exampleOrg200->code);
        $this->assertEquals(404, $exampleOrg404->code);
        EpiCurl::getInstance()->cleanupResponses();
        $this->assertNull($exampleOrg200->code);
        $this->assertNull($exampleOrg404->code);
        $exampleOrg200 = $this->object->addCurl(curl_init("http://www.example.org"));
        $exampleOrg404 = $this->object->addCurl(curl_init("http://www.example.org/nonexistent"));
        $this->assertEquals(200, $exampleOrg200->code);
        $this->assertEquals(404, $exampleOrg404->code);
    }
}