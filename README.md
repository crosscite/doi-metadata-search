# DataCite-ORCID metadata search and claim

An online tool for searching for works in the DataCite metadata
catalogue and adding them to an ORCID profile.

This is a project by [ORCID EU labs](https://github.com/ORCID-EU-Labs/) and [ODIN - ORCID and DataCite Interoperability Network](http://odin-project.eu)

Try out our live running instance at [http://datacite.labs.orcid-eu.org](http://datacite.labs.orcid-eu.org)


## Background 

The application is a fork of the Sinatra-based [CrossRef Metadata Search](http://search.crossref.org) tool by by [CrossRef Labs](http://labs.crossref.org)



## Installation

### Requirements

- Ruby (any version)
- git
- Vagrant: http://www.vagrantup.com
- Chef: http://www.opscode.com/chef/
- Virtualbox: https://www.virtualbox.org


### Installation

    git clone git@github.com:ORCID-EU-Labs/DataCite-ORCID.git
    cd DataCite-ORCID
    gem install librarian-chef
    librarian-chef install
    vagrant plugin install vagrant-omnibus
    cp config/settings.yml.example config/settings.yml 
    vagrant up
**Note:** You'll seed to populate the client secret and client id in settings.yml.

If you don't see any errors from the last command, you now have a properly
configured Ubuntu virtual machine running `DataCite-ORCID`. You can point your
browser to `http://localhost:8080`.


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

We use Rspec for unit testing and Cucumber for acceptance testing:

-   `rake spec`

-   `rake features`


## License

The MIT License (OSI approved, see more at http://www.opensource.org/licenses/mit-license.php)

=============================================================================

Copyright (C) 2013 by ORCID EU

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
