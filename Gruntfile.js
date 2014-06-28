module.exports = function( grunt ) {
  config.pkg = grunt.file.readJSON( 'package.json' );
  grunt.initConfig( config );

  grunt.loadNpmTasks( 'grunt-contrib-uglify' );
  grunt.loadNpmTasks( 'grunt-browserify' );
  grunt.loadNpmTasks( 'grunt-contrib-coffee' );
  grunt.loadNpmTasks( 'grunt-contrib-less' );
  grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
  grunt.loadNpmTasks( 'grunt-mocha' );
  grunt.loadNpmTasks( 'grunt-contrib-watch' );
  grunt.loadNpmTasks( 'grunt-contrib-copy' );
  grunt.loadNpmTasks( 'grunt-rsync' );
  grunt.loadNpmTasks( 'grunt-contrib-clean' );

  grunt.registerTask( 'build', [
    'coffee:build', 'browserify', 'less:build'
  ] );

  grunt.registerTask( 'dist', [
    'build',
    'uglify:dist', 'cssmin:dist',
    'copy'
  ] );

  grunt.registerTask( 'test', [
    'build', 'copy', 'coffee:test', 'mocha'
  ] );

  grunt.registerTask( 'deploy', [
    'clean', 'dist', 'rsync'
  ] );

  grunt.registerTask( 'default', [ 'clean', 'test', 'watch' ] );
};

var config = {

  // SCRIPTS
  browserify: {
    dist: {
      files: {
        'dist/jquery-tourbus.js': ['.tmp/**/*.js'],
      }
    }
  },
  coffee: {
    build: {
      options: { sourceMap: true },
      expand: true,
      cwd: 'src',
      src: ['**/*.coffee'],
      dest: '.tmp',
      ext: '.js'
    },
    test: {
      options: { bare: true },
      bare: true,
      expand: true,
      cwd: 'test/src/',
      src: [ '**/*.coffee' ],
      dest: 'test/',
      ext: '.js'
    }
  },
  uglify: {
    dist: {
      files: {
        'dist/<%= pkg.name %>.min.js': [ 'dist/<%= pkg.name %>.js' ]
      }
    }
  },

  // STYLES
  less: {
    build: {
      files: {
        'dist/<%= pkg.name %>.css': [ 'src/<%= pkg.name %>.less' ]
      }
    }
  },
  cssmin: {
    dist: {
      options: { keepLineBreaks: true },
      files: {
        'dist/<%= pkg.name %>.min.css': ['dist/<%= pkg.name %>.css']
      }
    }
  },

  // TESTS
  mocha: {
    test: {
      src: [ 'test/runner/*.html' ],
      options: {
        mocha: { ignoreLeaks: false },
        reporter: 'Dot',
        run: true
      }
    }
  },

  // BUILD
  copy: {
    dist: {
      files: [
        // jquery via bower_components
        {
          expand: true,
          flatten: true,
          cwd: 'bower_components',
          src: [
            'jquery/dist/jquery.min.js',
            'imagesloaded-packaged/imagesloaded.pkgd.min.js',
            'jquery.scrollTo/jquery.scrollTo.min.js'
          ],
          dest: 'site/deps'
        },
        // copy sourcemap to dist
        {
          expand: true,
          cwd: '.tmp',
          src: [ '*.map' ],
          dest: 'dist'
        },
        // copy build to site
        {
          expand: true,
          cwd: 'dist/',
          src: [ '*' ],
          dest: 'site/'
        },
      ]
    }
  },

  // DEPLOY
  rsync: {
    deploy: {
      src: 'site/',
      dest: '/var/www/rf/<%= pkg.name %>/',
      host: 'ryanfunduk.com',
      recursive: true,
      syncDest: true,
      args: [ '--verbose' ]
    }
  },

  // DEV
  watch: {
    dev: {
      files: [ 'src/*' ],
      tasks: [ 'dist' ]
    },
    test: {
      files: [ 'test/src/*.coffee', 'test/runner/*.html', 'src/*' ],
      tasks: [ 'test' ]
    }
  },

  // CLEAN
  clean: {
    test: [ 'test/*.js' ],
    min: [ 'site/<%= pkg.name %>.min.*' ]
  }

}
