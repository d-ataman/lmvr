#!/usr/bin/env python

import re
from setuptools import setup

main_py = open('flatcat/__init__.py').read()
metadata = dict(re.findall("__([a-z]+)__ = '([^']+)'", main_py))

requires = [
    'morfessor>=2.0.2alpha1'
]

setup(name='LMVR',
      version=metadata['version'],
      author=metadata['author'],
      author_email='ataman@fbk.eu',
      url='https://github.com/d-ataman/lmvr',
      description='LMVR',
      keywords='linguistically-motivated vocabulary reduction',
      packages=['flatcat'],
      classifiers=[
          'Development Status :: 4 - Beta',
          'Intended Audience :: Science/Research',
          'License :: OSI Approved :: BSD License',
          'Operating System :: OS Independent',
          'Programming Language :: Python :: 2.7',
          'Programming Language :: Python :: 3',
          'Topic :: Scientific/Engineering',
      ],
      license="BSD",
      scripts=['scripts/lmvr',
               'scripts/lmvr-evaluate',
               'scripts/lmvr-train',
               'scripts/lmvr-segment',
              ],
      install_requires=requires,
      extras_require={
          'docs': [l.strip() for l in open('docs/build_requirements.txt')]
      }
     )
