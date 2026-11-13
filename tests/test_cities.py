import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('cities',Path(__file__).parents[1]/'cities.py')
cities=importlib.util.module_from_spec(spec);spec.loader.exec_module(cities)
class CityTests(unittest.TestCase):
    def test_persistence_duplicates_and_single_removal(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {'XDG_STATE_HOME':directory}):
            first=dict(name='Paris',latitude=48.86,longitude=2.35,description='France')
            second=dict(name='Paris',latitude=33.66,longitude=-95.55,description='Texas')
            for city in [first,first,second]: cities.dispatch(dict(action='add',city=city))
            rows=cities.dispatch(dict(action='list'))['cities']
            self.assertEqual(len(rows),2)
            self.assertNotEqual(rows[0]['id'],rows[1]['id'])
            result=cities.dispatch(dict(action='remove',id=rows[0]['id']))
            self.assertEqual(result['cities'][0]['description'],'Texas')
            self.assertEqual((Path(directory)/'velunori/weather/cities.json').stat().st_mode & 0o777,0o600)
    def test_invalid_coordinates_rejected(self):
        for lat in [float('nan'),91,-91]:
            with self.assertRaises(ValueError): cities.normalize(dict(name='X',latitude=lat,longitude=0))
    def test_name_only_locations_are_supported(self):
        self.assertEqual(cities.normalize(dict(name='Berlin'))['id'],cities.normalize(dict(name='berlin'))['id'])
