_ = require 'underscore'
process = require 'process'

env = require './env.coffee'

GLOBALNS = '/'
ANYTYPE = '*'

class Name
  SEP = '/'
  PRIV_NAME = '~'
  # Test if name is a private graph resource name.
  #
  # @param name [String] must be a legal name in canonical form
  # @return [Boolean] True if name is a privately referenced name (i.e. /ns/name)
  isPrivate: (name) -> name? and name.startsWith PRIV_NAME

  # Test if name is a global graph resource name.
  #
  # @param name [String] must be a legal name in canonical form
  # @return [Boolean] True if name is a privately referenced name (i.e. ~name)
  isGlobal: (name) -> name? and name.startsWith SEP

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
    if (Name::isPrivate name) or (Name::isGlobal name) or not ns
      return name
    if ns == PRIV_NAME
      return PRIV_NAME + name
    if ns.endsWith SEP
      return ns + name
    else
      return ns + SEP + name

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

  # Convert name to a global name with a trailing namespace separator.
  #
  # @param name [String] name to convert
  # @return [String] converted name
  # @throw throws Error on private name
  toGlobal: (name) ->
    if Name::isPrivate(name)
      throw Error "Cannot turn private name [#{name}] into a global name"
    if not Name::isGlobal(name) # relative names
      name = SEP + name
    if not name.endsWith(SEP) # global names that not ends with SEP
      name = name + SEP
    return name

  # Resolve a local name to the caller ID based on ROS environment settings (i.e. ROS_NAMESPACE)
  #
  # @param name [String] local name to calculate caller ID from, e.g. 'camera', 'node'
  # @return [String] caller ID based on supplied local name
  toCallerID: (name) ->
    Name::toGlobal(Name::join(Name::getROSNamespace(), name))

  # Get the namespace of name. The namespace is returned with a
  # trailing slash in order to favor easy concatenation and easier use
  # within the global context.
  getNamespace: (name) ->
    if not _.isString name
      throw TypeError "Cannot get namespace from #{name}[#{typeof name}]"
    if not name or name == SEP
      return SEP
    crumbs = (crumb for crumb in name.split(SEP) when crumb)
    crumbs.pop()
    if crumbs.length
      return SEP + crumbs.join(SEP) + SEP
    else
      return SEP

  # Resolve a ROS name to its global, canonical form. Private ~names
  # are resolved relative to the node name.
  # @param name [String] name to solve
  # @param ns [String] node name to resolve relative to
  # @param remappings [Object] Map of resolved remappings. Use {} or null to indicate no remapping
  # @return [String] Resolved name. If name is empty/not given, resolve_name
  # returns parent namespace_. If namespace_ is empty/not given
  resolve: (name, ns, remapping) ->
    if not name
      return Name::getNamespace ns
    name = Name::canonicalize name
    if Name::isGlobal name
      resolved_name = name
    else if Name::isPrivate name
      resolved_name = Name::canonicalize(ns + SEP + name[1..])
    else # relative
      resolved_name = Name::getNamespace(ns) + name
    if remapping and remapping[resolved_name] isnt undefined
      return remapping[resolved_name]
    else
      return resolved_name

  # Load name mappings encoded in command-line arguments. This will filter
  # out any parameter assignment mappings.
  #
  # @param [[String]] argv
  # @return [{String: String}]
  loadMapping: (argv) ->
    REMAP = /:=/
    mapping = {}
    for arg in argv when arg.search(REMAP) != -1
      crumbs = (s.trim() for s in arg.split(REMAP))
      [src, dest] = crumbs
      if src and dest and crumbs.length is 2 and src.match(/^_[^_].*/) is null
        mapping[src] = dest
    return mapping

  # get ROS Namespace
  #
  # @param  environ [Object] environment dictionary (defaults to os.environ)
  # @param  argv    [Array]  command-line arguments (defaults to sys.argv)
  # @return [String] ROS  namespace of current program
  getROSNamespace: (environ=process.env, argv=process.argv) ->
    NS_PREFIX = '__ns:='
    for arg in argv
      if arg.startsWith NS_PREFIX
        return Name::toGlobal(arg[NS_PREFIX.length..])
    return Name::toGlobal(environ[env.ROS_NAMESPACE] || GLOBALNS)

module.exports = Name

