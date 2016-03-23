runCoffee = (filename) ->
  "node -r coffee-script/register #{filename}.coffee"

module.exports = (grunt) ->
  (require 'load-grunt-tasks') grunt

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    mochacli:
      options:
        require: ['coffee-script/register']
        reporter: 'nyan'
        bail: true
      all: ['test/*.coffee']
    shell: run: command: runCoffee 'master'
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

  grunt.registerTask 'test',    ['build', 'mochacli']
  grunt.registerTask 'build',   'coffee:compile'
  grunt.registerTask 'version', () ->
    grunt.log.writeln "glgraph #{grunt.config.get 'pkg.version'}"
  grunt.registerTask 'clean', () ->
    grunt.file.delete file for file in ['lib', 'doc']
    
  grunt.registerTask 'default', 'version'
