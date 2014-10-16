<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

namespace tests\unit\ACDH\FCSSRU\switchAggregator;

// not found by autoload ?!
require __DIR__ . '/../../../../../modules/fcs-aggregator/switch.php';
require __DIR__ . '/../../../../../vendor/autoload.php';

use atoum;

/**
 * Test class for switch.
 *
 * @author osiam
 */
class FCSSwitch extends atoum {

// put your code here

public function testSkipped() {
$this->skip('This test was skipped');
}

}
