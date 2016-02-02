<?php

namespace Tests\Common;

require __DIR__ . '/../../modules/mysqlonsru/common.php';

use ACDH\FCSSRU\mysqlonsru\SRUFromMysqlBase,
    ACDH\FCSSRU\SRUWithFCSParameters;
/**
 * Exposes protected parts of SRUFromMysqlBase
 *
 * @author osiam
 */
class SRUFromMysqlParts extends SRUFromMysqlBase {
    
    public function __construct(SRUWithFCSParameters $params = null) {
        parent::__construct($params);
    }
    
    public function encodecharrefs($str) {
        return parent::encodecharrefs($str);
    }
}
