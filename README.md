# DOI Metadata Search

[![Build Status](https://travis-ci.org/crosscite/doi-metadata-search.svg?branch=datacite)](https://travis-ci.org/crosscite/doi-metadata-search)
[![Code Climate](https://codeclimate.com/github/crosscite/doi-metadata-search/badges/gpa.svg)](https://codeclimate.com/github/crosscite/doi-metadata-search)
[![Test Coverage](https://codeclimate.com/github/crosscite/doi-metadata-search/badges/coverage.svg)](https://codeclimate.com/github/crosscite/doi-metadata-search/coverage)
[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.21430.svg)](http://doi.org/10.5281/zenodo.21430)

An online tool for searching for works in the CrossRef or DataCite metadata
catalogue and adding them to an ORCID profile.

This project was started as [CrossRef Metadata Search](http://search.crossref.org) tool
by [CrossRef](http://crossref.org), the original code repository is
[here](https://github.com/crossref/doi-metadata-search). Later the code was extended
to also work with the DataCite metadata Search in a project by
[ORCID EU labs](https://github.com/ORCID-EU-Labs/) and the
[ODIN - ORCID and DataCite Interoperability Network](http://odin-project.eu).

DOI Metadata Search combines these activities into a single codebase that works
with both CrossRef and DataCite DOIs.

## Installation

### Requirements

- Ruby (2.1 or higher)
- git
- Vagrant: http://www.vagrantup.com
- Chef: http://www.opscode.com/chef/
- Virtualbox: https://www.virtualbox.org


### Installation

    git clone https://github.com/datacite/DataCite-ORCID.git
    cd DataCite-ORCID
    gem install librarian-chef
    librarian-chef install
    vagrant plugin install vagrant-omnibus
    vagrant plugin install vagrant-aws
    cp .env.example .env
    vagrant up

If you don't see any errors from the last command, you now have a properly
configured Ubuntu virtual machine running `DataCite-ORCID`. You can point your
browser to `http://10.2.2.12`.


## Vagrant Pluggins

- vagrant-aws (0.4.1)
- vagrant-login (1.0.1, system)
- vagrant-omnibus (1.3.1)
- vagrant-share (1.0.1, system)
- vagrant-vbguest (0.10.0)


## Environment Variables

| Variable       | Notes               |
|----------------|---------------------|
| AWS_ACCESS_KEY | Used for production |
| AWS_SECRET     | Used for production |
| AWS_TAGS_NAME  | Used for production |
| SSH_KEY_PATH   | Used for production |


## Testing

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
```

## License

The MIT License (OSI approved, see more at http://www.opensource.org/licenses/mit-license.php)

=============================================================================

Copyright (C) 2013-2015 by ORCID EU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=============================================================================

![Open Source Initiative Approved License](http://www.opensource.org/trademarks/opensource/web/opensource-110x95.jpg)
