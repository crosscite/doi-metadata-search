# DOI Metadata Search

[![Build Status](https://travis-ci.org/crosscite/doi-metadata-search.svg)](https://travis-ci.org/crosscite/doi-metadata-search)  [![Maintainability](https://api.codeclimate.com/v1/badges/69aca8f548125bd813f3/maintainability)](https://codeclimate.com/github/crosscite/doi-metadata-search/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/69aca8f548125bd813f3/test_coverage)](https://codeclimate.com/github/crosscite/doi-metadata-search/test_coverage)

An online tool for searching for works in the CrossRef or DataCite metadata
catalogue. Also allows users to find their works and add them to their ORCID profile.

This project was started as [CrossRef Metadata Search](http://search.crossref.org) tool by [CrossRef](http://crossref.org), the original code repository is [here](https://github.com/crossref/doi-metadata-search). Later the code was extended to also work with the DataCite Metadata Search in a project by [ORCID EU labs](https://github.com/ORCID-EU-Labs/) and the [ODIN - ORCID and DataCite Interoperability Network](http://odin-project.eu).

DOI Metadata Search combines these activities into a single codebase that works with both CrossRef and DataCite DOIs.


## Installation

Using Docker. There is no required configuration file.

```
docker run -p 8095:80 crosscite/doi-metadata-search
```

You can now point your browser to `http://localhost:8095` and use the application.

![Screenshot](https://raw.githubusercontent.com/crosscite/doi-metadata-search/master/public/images/start.png)

For a more detailed configuration, including serving the application from the host for live editing and claiming works to ORCID, look at `docker-compose.yml` in the root folder.

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
```

Follow along via [Github Issues](https://github.com/crosscite/doi-metadata-search/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License
**doi-metadata-search** is released under the [MIT License](LICENSE.md).
