_ = require 'underscore'
should = (require 'chai').should()
Name = require '../src/name.coffee'
env = require '../src/env.coffee'

describe 'glgraph.name.Name', () ->
  describe 'isPrivate', () ->
    it "should treats '~private' as private", () ->
      Name::isPrivate('~private').should.equal true

    it "should treats 'private' as normal", () ->
      Name::isPrivate('private').should.equal false

    it 'should treats undefined as illegal', () ->
      Name::isPrivate().should.equal false

    it 'should fit official cases', () ->
      tests = ['~name', '~name/sub']
      fails = ['', 'not_private', 'not/private', 'not/~private',
        '/not/~private']
      for test in tests
        Name::isPrivate(test).should.equal yes, "('#{test}') => yes"
      for test in fails
        Name::isPrivate(test).should.equal no, "('#{test}') => no"

  describe 'isGlobal', () ->
    it "should treats '/ns' as global", () ->
      Name::isGlobal('/ns').should.equal true

    it "should treats '~' as private", () ->
      Name::isGlobal('~').should.equal false

    it "should treats '' as normal", () ->
      Name::isGlobal('').should.equal false

    it 'should treats undefined as illegal', () ->
      Name::isGlobal().should.equal false

    it 'should fit official cases', () ->
      tests = ['/', '/global', '/global2']
      fails = ['', 'not_global', 'not/global']
      for test in tests
        Name::isGlobal(test).should.equal yes
      for test in fails
        Name::isGlobal(test).should.equal no

  describe 'toGlobal', () ->
    it 'should throw Error on private name', () ->
      should.Throw((-> Name::toGlobal('~foo')), Error, "Cannot turn private name [~foo] into a global name")

    it 'should works on relative names', () ->
      Name::toGlobal('').should.equal '/'
      Name::toGlobal('foo').should.equal '/foo/'

    it 'should works on public names', () ->
      Name::toGlobal('/foo').should.equal '/foo/'
      Name::toGlobal('/foo/').should.equal '/foo/'
      Name::toGlobal('/foo/bar').should.equal '/foo/bar/'
      Name::toGlobal('/foo/bar/').should.equal '/foo/bar/'

    it 'should be functional', () ->
      name = 'foo'
      Name::toGlobal(name)
      name.should.equal 'foo'

  describe 'toCallerID', () ->
    it 'should throw error on any private name', () ->
      should.Throw((-> Name::toCallerID('~name')), Error)

    it 'should works by default', () ->
      Name::toCallerID('node').should.equal '/node/'
      Name::toCallerID('bar/node').should.equal '/bar/node/'
      Name::toCallerID('/bar/node').should.equal '/bar/node/'

    it 'should works when ENV set', () ->
      ns = process.env[env.ROS_NAMESPACE]
      process.env[env.ROS_NAMESPACE] = '/test/'
      Name::toCallerID('node').should.equal '/test/node/'
      Name::toCallerID('bar/node').should.equal '/test/bar/node/'
      Name::toCallerID('/bar/node').should.equal '/bar/node/'
      process.env[env.ROS_NAMESPACE] = ns

  describe 'isLegal', () ->
    it "should treats empty string as legal name", () ->
      Name::isLegal('').should.equal true

    it "should treats any legal name as legal", () ->
      Name::isLegal('/').should.equal true
      Name::isLegal('~').should.equal true
      Name::isLegal('~anything').should.equal true
      Name::isLegal('/ns/p/a/t/h').should.equal true
      Name::isLegal('/ns/p/a/t/h/').should.equal true

    it "should treats use of empty namespave as illegal", () ->
      Name::isLegal('//').should.equal false
      Name::isLegal('///').should.equal false
      Name::isLegal('////').should.equal false

    it 'should treats undefined as illegal', () ->
      Name::isLegal().should.equal false

    it 'should fit official cases', () ->
      tests = ['',
        'f', 'f1', 'f_', 'f/', 'foo', 'foo_bar', 'foo/bar', 'foo/bar/baz',
        '~f', '~a/b/c',
        '~/f',
        '/a/b/c/d', '/']
      for test in tests
        Name::isLegal(test).should.equal yes
      failures = [null, undefined,
        'foo++', 'foo-bar', '#foo',
        'hello\n', '\t', ' name', 'name ',
        'f//b',
        '1name', 'foo\\']
      for test in failures
        Name::isLegal(test).should.equal no

  describe 'isLegalBase', () ->
    it "should return false on illegal names", () ->
      illegalNames = [null, undefined, '',
        "hello\n", "\t", 'foo++', 'foo-bar', '#foo',
        'f/', 'foo/bar', '/', '/a',
        'f//b',
        '~f', '~a/b/c',
        ' name', 'name ',
        '1name', 'foo\\']
      for name in illegalNames
        Name::isLegalBaseName(name).should.equal no, "#{JSON.stringify name} is illegal"

    it "should return false on illegal names", () ->
      legalNames = ['f', 'f1', 'f_', 'foo', 'foo_bar']
      for name in legalNames
        Name::isLegalBaseName(name).should.equal yes, "#{JSON.stringify name} is legal"

  describe 'join', () ->
    test = (ns, name, expected) ->
      Name::join(ns, name).should.equal expected,
        "(#{JSON.stringify ns}, #{JSON.stringify name}) => #{JSON.stringify expected}"

    it 'private and global names cannot be joined', () ->
      cases = [
        ['/foo', '~name', '~name']
        ['/foo', '/name', '/name']
        ['~', '~name', '~name']
        ['/', '/name', '/name']
      ]
      for [ns, name, expected] in cases
        test ns, name, expected

    it "ns can be '~' or '/'", () ->
      cases = [
        ['~', 'name', '~name']
        ['/', 'name', '/name']
        ['/ns', 'name', '/ns/name']
        ['/ns/', 'name', '/ns/name']
        ['/ns', 'ns2/name', '/ns/ns2/name']
        ['/ns/', 'ns2/name', '/ns/ns2/name']
      ]
      for [ns, name, expected] in cases
        test ns, name, expected

    it "allow ns to be empty", () ->
      test '', 'name', 'name'

  describe 'canonicalize', () ->
    it 'should fit official test cases', () ->
      tests = [
        ['', '']
        ['/', '/']
        ['foo', 'foo']
        ['/foo', '/foo']
        ['/foo/', '/foo']
        ['/foo/bar', '/foo/bar']
        ['/foo/bar/', '/foo/bar']
        ['/foo/bar//', '/foo/bar']
        ['/foo//bar', '/foo/bar']
        ['//foo/bar', '/foo/bar']
        ['foo/bar', 'foo/bar']
        ['foo//bar', 'foo/bar']
        ['foo/bar/', 'foo/bar']
        ['/foo/bar', '/foo/bar']
      ]
      for [input, expected] in tests
        Name::canonicalize(input).should.equal expected, "'#{input}' => '#{expected}'"

  describe 'getNamespace', () ->
    test = (input, expected) ->
      Name::getNamespace(input).should.equal expected, "(#{JSON.stringify input}) => #{JSON.stringify expected}"

    it 'should works on official test cases', () ->
      cases = [
        ['', '/']
        ['/', '/']
        ['/foo', '/']
        ['/foo/', '/']
        ['/foo/bar', '/foo/']
        ['/foo/bar/', '/foo/']
        ['/foo/bar/baz', '/foo/bar/']
        ['/foo/bar/baz/', '/foo/bar/']
      ]
      for [input, expected] in cases
        test input, expected

    it 'should works on unicode', () ->
      cases = [
        ['', '/']
        ['/', '/']
        ['/foo/bar/baz/', '/foo/bar/']
      ]
      for [input, expected] in cases
        test input, expected

  describe 'resolve', () ->
    it 'should fit official cases', () ->
      test = (name, ns, expected) ->
        Name::resolve(name, ns).should.equal expected, "('#{name}', '#{ns}') => '#{expected}'"
      cases = [
        ['', '/', '/']
        ['', '/node', '/']
        ['', '/ns1/node', '/ns1/']
        ['foo', '', '/foo']
        ['foo/', '', '/foo']
        ['/foo', '', '/foo']
        ['/foo/', '', '/foo']
        ['/foo', '/', '/foo']
        ['/foo/', '/', '/foo']
        ['/foo', '/bar', '/foo']
        ['/foo/', '/bar', '/foo']
        ['foo', '/ns1/ns2', '/ns1/foo']
        ['foo', '/ns1/ns2/', '/ns1/foo']
        ['foo', '/ns1/ns2/ns3/', '/ns1/ns2/foo']
        ['foo/', '/ns1/ns2', '/ns1/foo']
        ['/foo', '/ns1/ns2', '/foo']
        ['foo/bar', '/ns1/ns2', '/ns1/foo/bar']
        ['foo//bar', '/ns1/ns2', '/ns1/foo/bar']
        ['foo/bar', '/ns1/ns2/ns3', '/ns1/ns2/foo/bar']
        ['foo//bar//', '/ns1/ns2/ns3', '/ns1/ns2/foo/bar']
        ['~foo', '/', '/foo']
        ['~foo', '/node', '/node/foo']
        ['~foo', '/ns1/ns2', '/ns1/ns2/foo']
        ['~foo/', '/ns1/ns2', '/ns1/ns2/foo']
        ['~foo/bar', '/ns1/ns2', '/ns1/ns2/foo/bar']
        ['~/foo', '/', '/foo']
        ['~/foo', '/node', '/node/foo']
        ['~/foo', '/ns1/ns2', '/ns1/ns2/foo']
        ['~/foo/', '/ns1/ns2', '/ns1/ns2/foo']
        ['~/foo/bar', '/ns1/ns2', '/ns1/ns2/foo/bar']
      ]
      for [name, ns, expected] in cases
        test name, ns, expected
        
describe 'glgraph.name', () ->
  describe 'loadMapping', () ->
    it 'should loads nothing if no remapping found', () ->
      test = (c) -> Name::loadMapping([c]).should.eql {}, "('#{[c]}') => {}"
      test c for c in ['foo', ':=', ':=:=', 'f:=', ':=b', 'foo:=bar:=baz']

    it 'should ignore node param assignments', () ->
      Name::loadMapping(['_foo:=bar']).should.eql {}
      Name::loadMapping(['foo:=bar']).should.eql {'foo': 'bar'}

    it 'should allow double-underscore names', () ->
      Name::loadMapping(['__foo:=bar']).should.eql {'__foo': 'bar'}
      Name::loadMapping(['./f', '-x', '--blah',
        'foo:=bar']).should.eql {'foo': 'bar'}
      Name::loadMapping(['c:=3', 'c:=', ':=3', 'a:=1',
        'b:=2']).should.eql {a: '1', b: '2', c: '3'}

  describe 'getROSNamespace', () ->
    ns = process.env[env.ROS_NAMESPACE]
    it 'should works...', () ->
      Name::getROSNamespace().should.equal '/'
      Name::getROSNamespace(null, []).should.equal '/'
      Name::getROSNamespace({}, null).should.equal '/'
      Name::getROSNamespace({}, []).should.equal '/'

    it "should works when #{env.ROS_NAMESPACE} is set", () ->
      process.env[env.ROS_NAMESPACE] = 'unresolved'
      Name::getROSNamespace().should.equal '/unresolved/'
      Name::getROSNamespace({'ROS_NAMESPACE': '/resolved'}).should.equal '/resolved/'
      process.env[env.ROS_NAMESPACE] = ns

    it 'should works when argv is set', () ->
      r = process.argv
      process.argv = ['foo', '__ns:=unresolved_ns']
      Name::getROSNamespace().should.equal '/unresolved_ns/'
      Name::getROSNamespace(null, ['foo', '__ns:=unresolved_ns2']).should.equal '/unresolved_ns2/'
      process.argv = ['foo', '__ns:=/resolved_ns/']
      Name::getROSNamespace().should.equal '/resolved_ns/'
      Name::getROSNamespace(null, ['foo', '__ns:=resolved_ns2']).should.equal '/resolved_ns2/'
      process.argv = r
