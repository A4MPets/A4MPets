#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const input = process.argv[2];

if (!input) {
  console.error('Uso: node scripts/f7-postman-summary.js <postman-runner-export.json>');
  process.exit(1);
}

const absolutePath = path.resolve(input);
const raw = fs.readFileSync(absolutePath, 'utf8');
const json = JSON.parse(raw);

const executions = json.run?.executions || json.executions || [];

if (!Array.isArray(executions) || executions.length === 0) {
  console.error('No se encontraron ejecuciones en el JSON exportado.');
  process.exit(1);
}

const groups = new Map();

for (const execution of executions) {
  const name = execution.item?.name || execution.request?.name || 'Sin nombre';
  const response = execution.response || {};
  const code = Number(response.code || response.statusCode || 0);
  const time = Number(response.responseTime || response.time || 0);
  const tests = execution.assertions || [];
  const failedTests = tests.filter((assertion) => assertion.error).length;

  if (!groups.has(name)) {
    groups.set(name, {
      name,
      count: 0,
      codes: {},
      failures: 0,
      http500: 0,
      times: [],
    });
  }

  const group = groups.get(name);
  group.count += 1;
  group.codes[code] = (group.codes[code] || 0) + 1;
  group.failures += failedTests;
  if (code >= 500) {
    group.http500 += 1;
  }
  if (Number.isFinite(time) && time > 0) {
    group.times.push(time);
  }
}

const rows = [...groups.values()].map((group) => {
  const times = group.times;
  const avg = times.length
    ? times.reduce((total, value) => total + value, 0) / times.length
    : 0;
  const min = times.length ? Math.min(...times) : 0;
  const max = times.length ? Math.max(...times) : 0;

  return {
    request: group.name,
    iterations: group.count,
    status_codes: group.codes,
    failed_assertions: group.failures,
    http_500_plus: group.http500,
    latency_avg_ms: Math.round(avg),
    latency_min_ms: Math.round(min),
    latency_max_ms: Math.round(max),
  };
});

const totals = rows.reduce(
  (acc, row) => {
    acc.iterations += row.iterations;
    acc.failed_assertions += row.failed_assertions;
    acc.http_500_plus += row.http_500_plus;
    return acc;
  },
  { iterations: 0, failed_assertions: 0, http_500_plus: 0 },
);

console.log(JSON.stringify({ source: absolutePath, totals, requests: rows }, null, 2));
