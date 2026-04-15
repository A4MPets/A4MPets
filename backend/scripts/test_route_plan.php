<?php

$payload = [
    'points' => [
        ['lat' => 4.7110, 'lng' => -74.0721],
        ['lat' => 4.7430, 'lng' => -74.1100],
    ],
    'avoid_hazards' => true,
    'travel_mode' => 'vehicle',
    'trip_config' => new stdClass(),
];

$options = [
    'http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/json\r\n",
        'content' => json_encode($payload, JSON_UNESCAPED_UNICODE),
        'timeout' => 30,
    ],
];

$context = stream_context_create($options);
$response = @file_get_contents('http://127.0.0.1:8000/api/routes/plan', false, $context);

if ($response === false) {
    fwrite(STDERR, "REQUEST_FAILED\n");
    if (isset($http_response_header)) {
        fwrite(STDERR, implode("\n", $http_response_header) . "\n");
    }
    exit(1);
}

echo $response . PHP_EOL;
