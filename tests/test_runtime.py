import os
from pathlib import Path
import subprocess
import tempfile
import unittest
SCRIPT=Path(__file__).resolve().parents[1]/'scripts/make-loop.sh'
class GenerationTests(unittest.TestCase):
 def test_empty_minute_tokens_are_rejected(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);prompt=p/'prompt';prompt.write_text('x')
   for minutes in [',','7,',',7','7,,8','7 8']:
    r=subprocess.run(['bash',str(SCRIPT),'--name','demo','--dir',d,'--minutes',minutes,'--prompt-file',str(prompt),'--out',str(p/'out')],capture_output=True)
    self.assertEqual(r.returncode,2)
 def test_prompt_without_newline_and_failure_status(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d);prompt=p/'prompt';prompt.write_text('plain prompt without newline');home=p/'home';bin_dir=home/'.local/bin';bin_dir.mkdir(parents=True)
   fake=bin_dir/'claude';fake.write_text('#!/bin/sh\nexit 7\n');fake.chmod(0o700)
   args=['bash',str(SCRIPT),'--name','demo','--dir',d,'--minutes','7','--prompt-file',str(prompt),'--out',str(p/'out')]
   self.assertEqual(subprocess.run(args,capture_output=True).returncode,0)
   wrapper=p/'out/demo-loop.sh'
   self.assertEqual(subprocess.run(['zsh','-n',str(wrapper)],capture_output=True).returncode,0)
   result=subprocess.run(['zsh',str(wrapper)],env=dict(os.environ,HOME=str(home)),capture_output=True)
   self.assertEqual(result.returncode,7)
   self.assertIn('exit 7',(home/'.claude/demo-loop.log').read_text())
   self.assertNotEqual(subprocess.run(args,capture_output=True).returncode,0,'existing output must not be overwritten')
unittest.main()
