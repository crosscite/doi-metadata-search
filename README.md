## Installation

### Requirements

Ruby (any version), git

### Preparation

-   Download and install Vagrant from <http://www.vagrantup.com>

-   Download and install Virtualbox from https://www.virtualbox.org

-   Install the berkshelf gem: `gem install berkshelf`

### Installation

-   Clone this repo to your computer: `git clone
    https://github.com/mfenner/cr-search.git`

-   Switch into source code directory: `cd cr-search`

-   Install Chef cookbooks: `berks install`

-   Download Ubuntu 12.04, launch Virtual Machine and configure with Ruby 1.9.3,
    Apache, Passenger and Mongo DB: `vagrant up`


If you don't see any errors from the last command, you now have a properly
configured Ubuntu virtual machine running `cr-search`. You can point your
browser to `http://localhost:8088`.

## Testing

We use Rspec for unit testing and Cucumber for acceptance testing:

-   `rake spec`

-   `rake features`
