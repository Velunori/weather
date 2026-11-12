import { createRequire } from 'node:module';
import test from 'node:test';
import assert from 'node:assert/strict';
const require = createRequire(import.meta.url);
const conditions = require('../Conditions.js');
const model = require('../Model.js');

test('Open-Meteo codes get a plain description', () => {
    assert.equal(conditions.describe({openMeteoWeatherCode: 0}), 'Clear');
    assert.equal(conditions.describe({openMeteoWeatherCode: 2}), 'Partly cloudy');
    assert.equal(conditions.describe({openMeteoWeatherCode: 63}), 'Rain');
    assert.equal(conditions.describe({openMeteoWeatherCode: 99}), 'Thunderstorm with hail');
    assert.equal(conditions.describe({openMeteoWeatherCode: 1234}), '');
});
test('wttr.in reports use their own description', () => {
    assert.equal(conditions.describe({weatherDesc: [{value: ' Light rain shower '}]}), 'Light rain shower');
    assert.equal(conditions.describe({}), '');
    assert.equal(conditions.describe(null), '');
});
test('every code with a description also has an icon in the shared model', () => {
    for (const code of [0, 1, 2, 3, 45, 51, 61, 63, 65, 66, 71, 73, 75, 80, 95, 96])
        assert.notEqual(model.iconForOpenMeteoCode(code, false), '', `icon for ${code}`);
});
