module.exports = function( grunt ) {
  config.pkg = grunt.file.readJSON( 'package.json' );
  grunt.initConfig( config );

  grunt.loadNpmTasks( 'grunt-contrib-uglify' );
  grunt.loadNpmTasks( 'grunt-contrib-coffee' );
  grunt.loadNpmTasks( 'grunt-contrib-less' );
  grunt.loadNpmTasks( 'grunt-contrib-cssmin' );
  grunt.loadNpmTasks( 'grunt-mocha' );
  grunt.loadNpmTasks( 'grunt-contrib-watch' );
  grunt.loadNpmTasks( 'grunt-contrib-copy' );
  grunt.loadNpmTasks( 'grunt-rsync' );
  grunt.loadNpmTasks( 'grunt-contrib-clean' );

  grunt.registerTask( 'build', [
    'coffee:build', 'less:build'
  ] );

  grunt.registerTask( 'dist', [
    'build',
    'uglify:dist', 'cssmin:dist',
    'copy'
  ] );

  grunt.registerTask( 'test', [
    'build', 'coffee:test', 'mocha'
  ] );

  grunt.registerTask( 'deploy', [
    'clean', 'dist', 'rsync'
  ] );

  grunt.registerTask( 'default', [ 'clean', 'test', 'watch' ] );
};

var config = {

  // SCRIPTS
  coffee: {
    build: {
      files: {
        'dist/<%= pkg.name %>.js': 'src/<%= pkg.name %>.coffee'
      }
    },
    test: {
      options: { bare: true },
      bare: true,
      expand: true,
      cwd: 'test/src/',
      src: [ '*.coffee' ],
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
        {
          expand: true,
          cwd: 'dist/',
          src: [ '**/*.min.*' ],
          dest: 'site/'
        }
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
