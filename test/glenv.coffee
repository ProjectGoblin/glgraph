_ = require 'underscore'
should = (require 'chai').should()
process = require 'process'
glenv = require '../src/glenv.coffee'

globalENV = {}
globalARGV = []

describe 'glgraph.glenv', () ->
  before () ->
    globalENV = _.extend {}, process.env
    globalARGV = process.argv

  afterEach () ->
    process.env = {}
    _.extend process.env, globalENV
    process.argv = globalARGV

  describe 'Constants', () ->
    it 'should have no miss spelling', () ->
      glenv.ROS_MASTER_URI.should.equal 'ROS_MASTER_URI'
      glenv.ROS_IP.should.equal 'ROS_IP'
      glenv.ROS_HOSTNAME.should.equal 'ROS_HOSTNAME'
      glenv.ROS_NAMESPACE.should.equal 'ROS_NAMESPACE'

  describe 'getMasterURI', () ->
    it "should use argv's remapping if possible", () ->
      process.argv.push '__master:=foobar'
      glenv.getMasterURI().should.equal 'foobar'
      process.argv.pop()

    it "should use ENV if '#{glenv.ROS_MASTER_URI}' is set", () ->
      process.env[glenv.ROS_MASTER_URI] = 'hostname'
      glenv.getMasterURI().should.equal 'hostname'

    it "should return null otherwise", () ->
      should.equal glenv.getMasterURI(), null

    it "should fail when meet illegal argv", () ->
      msg = (a) -> "__master remapping argument #{a} improperly specifie"

      arg = "__master:="
      process.argv.push arg
      should.Throw glenv.getMasterURI, Error, msg arg
      process.argv.pop()

      arg = "__master:=:="
      process.argv.push arg
      should.Throw glenv.getMasterURI, Error, msg arg
      process.argv.pop()

      arg = "__master:=x:=y:=z"
      process.argv.push arg
      should.Throw glenv.getMasterURI, Error, msg arg
      process.argv.pop()
