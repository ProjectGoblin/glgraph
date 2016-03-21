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
