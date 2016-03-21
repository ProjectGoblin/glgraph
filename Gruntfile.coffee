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

  grunt.registerTask 'version', () ->
    grunt.log.writeln "glgraph #{grunt.config.get 'pkg.version'}"

  grunt.registerTask 'run',     'shell:run'
  grunt.registerTask 'test',    'mochacli'
  grunt.registerTask 'default', 'version'
