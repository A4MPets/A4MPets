<?php

declare(strict_types=1);

$backendRoot = dirname(__DIR__);
$outputDir = $backendRoot . DIRECTORY_SEPARATOR . 'docs';
$pngOutput = $outputDir . DIRECTORY_SEPARATOR . 'mer_actual.png';
$dotOutput = $outputDir . DIRECTORY_SEPARATOR . 'mer_actual.dot';

if (! is_dir($outputDir) && ! mkdir($outputDir, 0777, true) && ! is_dir($outputDir)) {
    fwrite(STDERR, "No se pudo crear el directorio de salida: {$outputDir}" . PHP_EOL);
    exit(1);
}

$dotVersionCommand = 'dot -V';
$dotVersionOutput = [];
$dotVersionExitCode = 0;
exec($dotVersionCommand . ' 2>&1', $dotVersionOutput, $dotVersionExitCode);

if ($dotVersionExitCode !== 0) {
    fwrite(STDERR, 'Graphviz/dot no esta disponible en PATH.' . PHP_EOL);
    fwrite(STDERR, 'Instala Graphviz o agrega dot al PATH antes de generar el MER.' . PHP_EOL);
    exit($dotVersionExitCode);
}

echo implode(PHP_EOL, $dotVersionOutput) . PHP_EOL;

$commands = [
    sprintf(
        'php artisan generate:erd %s --format=png --no-interaction',
        escapeshellarg('docs/mer_actual.png'),
    ),
    sprintf(
        'php artisan generate:erd %s --text-output --no-interaction',
        escapeshellarg('docs/mer_actual.dot'),
    ),
];

chdir($backendRoot);

foreach ($commands as $command) {
    echo PHP_EOL . '> ' . $command . PHP_EOL;
    passthru($command, $exitCode);

    if ($exitCode !== 0) {
        fwrite(STDERR, "Fallo la generacion del MER con codigo {$exitCode}." . PHP_EOL);
        exit($exitCode);
    }
}

echo PHP_EOL . "MER generado:" . PHP_EOL;
echo "- {$pngOutput}" . PHP_EOL;
echo "- {$dotOutput}" . PHP_EOL;

