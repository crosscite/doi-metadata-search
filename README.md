## Installation

### Requirements

- Ruby (any version)
- git
- Vagrant: http://www.vagrantup.com
- Virtualbox: https://www.virtualbox.org

### Installation

    git clone https://github.com/mfenner/cr-search.git
    cd cr-search
    vagrant up

If you don't see any errors from the last command, you now have a properly
configured Ubuntu virtual machine running `cr-search`. You can point your
browser to `http://localhost:8088`.

## Testing

We use Rspec for unit testing and Cucumber for acceptance testing:

-   `rake spec`

-   `rake features`
