<?php

namespace Tests\Common;

use \PHPUnit_Framework_TestCase;

abstract class XPathTestCase extends PHPUnit_Framework_TestCase {
    
    /**
     * uri => prefix used in xpath asserts.
     * 
     * @var array
     */
    protected $namespaces;
    
    /**
     * 
     * @param string $expected
     * @param \DOMDocument|false $xmlDoc
     * @param string $xpathForActual
     * @param string $message
     */
    protected function assertXPath($expected, $xmlDoc, $xpathForActual, $message) {
        $this->assertNotFalse($xmlDoc, 'XML document didn\'t load: ' . $message);
        $this->assertInstanceOf('\DOMDocument', $xmlDoc, 'XML document is no DOMDocument: ' . $message);
        foreach ($this->namespaces as $uri => $prefix) {
            // forcebly register
            $xmlDoc->createAttributeNS($uri, $prefix . ':create-ns');
        }
        $xpath = new \DOMXPath($xmlDoc);
        if (is_string($expected)) {
           $nodeList = $xpath->query($xpathForActual);
           $this->assertEquals(1, $nodeList->length, 'Can\'t compare more or less than one value: ' . $message);
           $actual = $nodeList->item(0)->nodeValue;
           $this->assertEquals($expected, $actual, 'XPath ' . $xpathForActual . ' should match expected value: ' . $message);
        } else {
           self::assertFalse(true, 'Needs to be handled: ' . $message); 
        }
    }
}

