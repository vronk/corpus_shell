<?php

namespace Tests\Common;

require __DIR__ . '/../../modules/fcs-aggregator/switch.php';

use ACDH\FCSSRU\switchAggregator\FCSSwitch;

// used to make protected methods accessible for test purpose.
class FCSSwitchParts extends FCSSwitch {
    protected $pr;
            
    public function __construct($pr) {
        $this->pr = $pr;
    }
    public function GetDefaultStyles() {
        parent::GetDefaultStyles();
    }
    public function ReturnXslT($xmlDoc, $xslDoc, $useParams, $useCallback = true) {
        return parent::ReturnXslT($xmlDoc, $xslDoc, $useParams, $useCallback);
    }
    public function GetConfig($context) {
        return parent::GetConfig($context);
    }
    public function GetDomDocument($url) {
        return parent::GetDomDocument($url);
    }
    public function GetXslStyleDomDocument($operation, $configItem) {
        return parent::GetXslStyleDomDocument($operation, $configItem);
    }
    protected function GetXslStyle($operation, $configItem) {
        $pathOnly = str_replace(array('http://localhost/', 'http://127.0.0.1/'), '../../../', parent::GetXslStyle($operation, $configItem));
        return $this->pr . 'modules/fcs-aggregator/' . $pathOnly;
    }
}

