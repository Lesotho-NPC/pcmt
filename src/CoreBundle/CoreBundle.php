<?php

declare(strict_types=1);

namespace CoreBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;

class CoreBundle extends Bundle
{
    public function getParent()
    {
        return 'PcmtCoreBundle';
    }
}
