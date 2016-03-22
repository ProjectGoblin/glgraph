_ = require 'underscore'
process = require 'process'

env = require './env.coffee'

GLOBALNS = '/'
REMAP = ":="
ANYTYPE = '*'

class Name
  SEP = '/'
  PRIV_NAME = '~'
  # Test if name is a private graph resource name.
  #
  # @param name [String] must be a legal name in canonical form
  # @return [Boolean] True if name is a privately referenced name (i.e. /ns/name)
  isPrivate: (name) -> Boolean name and name[0] == PRIV_NAME

  # Test if name is a global graph resource name.
  #
  # @param name [String] must be a legal name in canonical form
  # @return [Boolean] True if name is a privately referenced name (i.e. ~name)
  isGlobal: (name) -> Boolean name and name[0] == SEP

  # Check if name is a legal ROS name for graph resources
  # (alphabetical character followed by alphanumeric, underscore, or
  # forward slashes). This constraint is currently not being enforced,
  # but may start getting enforced in later versions of ROS.
  #
  # @param name [String] the name to be validate
  # @return [Boolean] if the name is legal
  isLegal: (name) ->
    REGEXP = /^[~\/A-Za-z][\w\/]*$/
    unless name?
      return false
    if name.length == 0
      return true
    m = name.match REGEXP
    return m? and m[0] == name and (name.search /\/\//) == -1

  # Validates that name is a legal base name for a graph resource. A base name has
  # no namespace context, e.g. "node_name".
  isLegalBaseName: (name) ->
    REGEXP = /^[A-Za-z][\w]*$/
    return name? and (name.match(REGEXP)?[0]) == name


  # Join a namespace and name. If name is unjoinable (i.e. ~private or /global) it will be returned without joining
  #
  # @param ns [String] namespace ('/' and '~' are both legal). If ns is the empty string, name will be returned.
  # @param name [String] a legal name
  # @return [String] name concatenated to ns, or name if it is unjoinable.
  join: (ns, name) ->
    if isPrivate name or isGlobal name
      return name
  # Put name in canonical form. Extra slashes '//' are removed and
  # name is returned without any trailing slash, e.g. /foo/bar
  #
  # @param name [String] ROS name
  canonicalize: (name) ->
    if not name or name == Name
      return name
    canonical = (x for x in name.split SEP when x).join SEP
    if name.startsWith SEP
      return SEP + canonical
    else
      return canonical

# get ROS Namespace
#
# @param  env  [Object] environment dictionary (defaults to os.environ)
# @param  argv [Array]  command-line arguments (defaults to sys.argv)
# @return [String] ROS  namespace of current program
getROSNamespace = (env=null, argv=null) ->
  NS_PREFIX = '__ns:='
  argv ?= process.argv
  env ?= process.env
  for arg in argv
    if arg.startsWith NS_PREFIX
      return makeGlobalNS arg[len(NS_PREFIX)..]
  return makeGlobalNS (env[glenv.ROS_NAMESPACE] || GLOBALNS)

# Resolve a local name to the caller ID based on ROS environment settings (i.e. ROS_NAMESPACE)
#
# @param name [String] local name to calculate caller ID from, e.g. 'camera', 'node'
# @return [String] caller ID based on supplied local name
makeCallerID = (name) ->


exports.Name = Name

