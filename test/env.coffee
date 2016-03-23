_ = require 'underscore'
should = (require 'chai').should()
graph = require '../lib/graph'
env = graph.env

globalENV = {}
globalARGV = []

describe 'glgraph.env', () ->
  before () ->
    globalENV = _.extend {}, process.env
    globalARGV = process.argv

  afterEach () ->
    process.env = {}
    _.extend process.env, globalENV
    process.argv = globalARGV

  describe 'Constants', () ->
    it 'should have no miss spelling', () ->
      env.ROS_MASTER_URI.should.equal 'ROS_MASTER_URI'
      env.ROS_IP.should.equal 'ROS_IP'
      env.ROS_HOSTNAME.should.equal 'ROS_HOSTNAME'
      env.ROS_NAMESPACE.should.equal 'ROS_NAMESPACE'

  describe 'getMasterURI', () ->
    it "should use argv's remapping if possible", () ->
      process.argv.push '__master:=foobar'
      env.getMasterURI().should.equal 'foobar'
      process.argv.pop()

    it "should use ENV if '#{env.ROS_MASTER_URI}' is set", () ->
      process.env[env.ROS_MASTER_URI] = 'hostname'
      env.getMasterURI().should.equal 'hostname'

    it "should return null otherwise", () ->
      should.equal env.getMasterURI(), null

    it "should fail when meet illegal argv", () ->
      msg = (a) -> "__master remapping argument #{a} improperly specifie"

      arg = "__master:="
      process.argv.push arg
      should.Throw env.getMasterURI, Error, msg arg
      process.argv.pop()

      arg = "__master:=:="
      process.argv.push arg
      should.Throw env.getMasterURI, Error, msg arg
      process.argv.pop()

      arg = "__master:=x:=y:=z"
      process.argv.push arg
      should.Throw env.getMasterURI, Error, msg arg
      process.argv.pop()
