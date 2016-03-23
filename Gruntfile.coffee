module.exports = (grunt) ->
  (require 'load-grunt-tasks') grunt

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    mochaTest:
      test:
        options:
          require: ['coffee-script/register']
        src: ['test/*.coffee']
      coverage:
        options:
          require: ['coffee-script/register', 'blanket']
          reporter: 'html-cov'
          quiet: yes
          captureFile: 'coverage.html'
        src: ['test/*.coffee']
    coffee:
      compile:
        options:
          sourceMap: true
        files:
          'lib/env.js': 'src/env.coffee'
          'lib/name.js': 'src/name.coffee'
          'lib/graph.js': 'src/graph.coffee'
    codo:
      src: ['src']

  grunt.registerTask 'cov',     ['build', 'mochaTest:coverage']
  grunt.registerTask 'test',    ['build', 'mochaTest:test']
  grunt.registerTask 'build',   'coffee:compile'
  grunt.registerTask 'version', () ->
    grunt.log.writeln "glgraph #{grunt.config.get 'pkg.version'}"
  grunt.registerTask 'clean', () ->
    grunt.file.delete file, force: yes for file in [
      'lib'
      'doc'
      'coverage.html'
    ]
    
  grunt.registerTask 'default', 'version'
