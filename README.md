# jQuery TourBus

A tour/walkthrough plugin for developers. It includes limited automatic behavior,
more like a 'toolkit' than some of the others out there.


## Installation

CoffeeScript and LESS source files are available in `src` while
compiled/pre-processed/minified files are in `dist`. Wire up your
asset packager appropriately or include the css and js by hand
old-school:

    <script src='path/to/jquery.min.js'></script>
    <script src='path/to/jquery-tourbus.min.js'></script>
    <link href='path/to/jquery-tourbus.min.css' media='all' rel='stylesheet' type='text/css' />

jQuery is the only dependency. I think technically it will be able to
support Zepto without too much difficulty.


## Documentation

Docs coming to this readme at some point, but for now you'll find all
the details and a demo on [the website](http://ryanfunduk.com/jquery-tourbus).


## Contributing

This project uses grunt plus an npm `package.json` for development
(the plugin itself is not on npm). That means you can hack on it by forking
the repo and:

    $ npm install -g grunt-cli
    $ git clone git@github.com:<you>/jquery-tourbus.git
    $ cd jquery-tourbus
    $ npm install
    $ grunt build
    $ open site/index.html # on OSX, opens the demo site in your browser

Other useful tasks:

    # run headless tests
    $ grunt test

    # build test js/etc and open them in your browser
    $ grunt build coffee:test
    $ open test/runner/basic.html

    # clean up minified source in site/ and compiled tests in test/
    $ grunt clean

    # watch for changes to sources and build
    $ grunt watch:dev

    # watch for changes to tests and build
    $ grunt watch:test

    # prepare compiled/minified sources for deploy
    $ grunt dist

If you're working on a pull request, please remember to work on a local
branch instead of master.

## Contributors

- [Ryan Funduk](https://github.com/rfunduk)
- [Gary Taylor](https://github.com/henrythewasp)
- [Joshua Jabbour](https://github.com/joshuajabbour)
