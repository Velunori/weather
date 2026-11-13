import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require = createRequire(import.meta.url);
const model = require('../Model.js');
const dates = Array.from({length: 10}, (_, i) => `2026-11-${String(12+i).padStart(2,'0')}`);
const report = {daily:{time:dates,temperature_2m_max:dates.map((_,i)=>10+i),temperature_2m_min:dates.map((_,i)=>i),weather_code:dates.map(()=>2)}};
test('weekly forecast excludes today and caps at seven future days', () => {
    const result = model.openMeteoForecastDays(report,'2026-11-12');
    assert.equal(result.length,7);
    assert.deepEqual(result.map(row=>row.date),dates.slice(1,8));
    assert.equal(result[0].maxtempC,'11');
    assert.equal(result[0].maxtempF,'52');
    assert.equal(result[6].mintempC,'7');
});
test('short fallback stays short rather than inventing extra days', () => {
    const result = model.buildForecastDays({weather:dates.slice(0,3).map(date=>({date,maxtempC:'10',mintempC:'0'}))},null,'2026-11-12');
    assert.equal(result.length,2);
    assert.equal(model.buildForecastDays(null,null,'2026-11-12').length,0);
});
