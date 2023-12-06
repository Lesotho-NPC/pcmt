<?php
namespace CISBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;

class CISBundle extends Bundle
{
    public function getParent()
    {
        return 'PcmtCISBundle';
    }
}