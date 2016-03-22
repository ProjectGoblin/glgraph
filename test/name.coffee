_ = require 'underscore'
should = (require 'chai').should()
name = require '../src/name.coffee'
Name = name.Name;

describe 'glgraph.name.Name', () ->
  describe 'isPrivate', () ->
    it "should treats '~private' as private", () ->
      Name::isPrivate('~private').should.equal true

    it "should treats 'private' as normal", () ->
      Name::isPrivate('private').should.equal false

    it 'should treats undefined as illegal', () ->
      Name::isPrivate().should.equal false

  describe 'isGlobal', () ->
    it "should treats '/ns' as global", () ->
      Name::isGlobal('/ns').should.equal true

    it "should treats '~' as private", () ->
      Name::isGlobal('~').should.equal false

    it "should treats '' as normal", () ->
      Name::isGlobal('').should.equal false

    it 'should treats undefined as illegal', () ->
      Name::isGlobal().should.equal false

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

  describe 'isLegalBase', () ->
    it "should return false on illeagl names", () ->
      illegalNames = [null,
        undefined,
        '',
        "hello\n", "\t", 'foo++', 'foo-bar',
        '#foo',
        'f/', 'foo/bar', '/', '/a',
        'f//b',
        '~f', '~a/b/c',
        ' name', 'name ',
        '1name', 'foo\\']
      for name in illegalNames
        Name::isLegalBaseName(name).should.equal false, "#{JSON.stringify name} is illegal"

    it "should return false on illeagl names", () ->
      legalNames = ['f', 'f1', 'f_', 'foo', 'foo_bar']
      for name in legalNames
        Name::isLegalBaseName(name).should.equal true, "#{JSON.stringify name} is legal"

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
