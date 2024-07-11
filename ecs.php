<?php

declare(strict_types=1);

use PhpCsFixer\Fixer\Import\NoUnusedImportsFixer;
use Symplify\EasyCodingStandard\Config\ECSConfig;

return ECSConfig::configure()
    ->withPaths([
        __DIR__ . '/scripts',
        __DIR__ . '/src',
    ])

    ->withSkip([
        __DIR__. '/src/Kernel.php',
        ])
    // add a single rule
    ->withRules([
        NoUnusedImportsFixer::class,
    ])

    // add sets - group of rules
    ->withPreparedSets(
        psr12: true,
        common: true,
        symplify: true,
        cleanCode: true,
        strict: true
    )
     
     ;
