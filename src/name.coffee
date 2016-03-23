_ = require 'underscore'
os = require 'os'
crypto = require 'crypto'
process = require 'process'

env = require './env.coffee'

GLOBAL_NAMESPACE = '/'
PRIVATE_PREFIX = '~'
SEP = '/'
NAME_VALIDATOR = /^[~\/A-Za-z][\w\/]*$/g
BASE_NAME_VALIDATOR = /^[A-Za-z][\w]*$/
REMAP = /:=/
NS_PREFIX = '__ns:='

# Test if name is a private graph resource name.
#
# @param name [String] must be a legal name in canonical form
# @return [Boolean] True if name is a privately referenced name (i.e. /ns/name)
isPrivate = (name) -> name? and name.startsWith PRIVATE_PREFIX

# Test if name is a global graph resource name.
#
# @param name [String] must be a legal name in canonical form
# @return [Boolean] True if name is a privately referenced name (i.e. ~name)
isGlobal = (name) -> name? and name.startsWith SEP

# Check if name is a legal ROS name for graph resources
# (alphabetical character followed by alphanumeric, underscore, or
# forward slashes). This constraint is currently not being enforced,
# but may start getting enforced in later versions of ROS.
#
# @param name [String] the name to be validate
# @return [Boolean] if the name is legal
isLegal = (name) ->
  if not _.isString(name)
    return no 
  if name.length == 0
    return yes 
  m = name.match NAME_VALIDATOR
  return m? and m[0] == name and name.search('//') == -1

# Validates that name is a legal base name for a graph resource. A base name has
# no namespace context, e.g. "node_name".
isLegalBaseName = (name) ->
  return name? and name.match(BASE_NAME_VALIDATOR)?[0] == name

# Join a namespace and name. If name is unjoinable (i.e. ~private or /global) it will be returned without joining
#
# @param ns [String] namespace ('/' and '~' are both legal). If ns is the empty string, name will be returned.
# @param name [String] a legal name
# @return [String] name concatenated to ns, or name if it is unjoinable.
join = (ns, name) ->
  if (isPrivate name) or (isGlobal name) or not ns
    return name
  if ns == PRIVATE_PREFIX
    return PRIVATE_PREFIX + name
  if ns.endsWith SEP
    return ns + name
  else
    return ns + SEP + name

# Put name in canonical form. Extra slashes '//' are removed and
# name is returned without any trailing slash, e.g. /foo/bar
#
# @param name [String] ROS name
canonicalize = (name) ->
  if not name or name == SEP 
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
toGlobal = (name) ->
  if isPrivate(name)
    throw Error "Cannot turn private name [#{name}] into a global name"
  if not isGlobal(name) # relative names
    name = SEP + name
  if not name.endsWith(SEP) # global names that not ends with SEP
    name = name + SEP
  return name

# Resolve a local name to the caller ID based on ROS environment settings (i.e. ROS_NAMESPACE)
#
# @param name [String] local name to calculate caller ID from, e.g. 'camera', 'node'
# @return [String] caller ID based on supplied local name
toCallerID = (name) ->
  toGlobal(join(getROSNamespace(), name))

# Get the namespace of name. The namespace is returned with a
# trailing slash in order to favor easy concatenation and easier use
# within the global context.
namespaceOf = (name) ->
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
resolve = (name, ns, remapping) ->
  if not name
    return namespaceOf ns
  name = canonicalize name
  if isGlobal name
    resolved_name = name
  else if isPrivate name
    resolved_name = canonicalize(ns + SEP + name[1..])
  else # relative
    resolved_name = namespaceOf(ns) + name
  if remapping and remapping[resolved_name] isnt undefined
    return remapping[resolved_name]
  else
    return resolved_name

# Name resolver for scripts. Supports ROS_NAMESPACE.  Does not
# support remapping arguments.
#
# @param scriptName [String] name of script. script_name must not
# @param name [String] name to resolve
# contain a namespace
# @return [String] resolved name
resolveScriptName = (scriptName, name) ->
  if not name
    return getROSNamespace()
  if isGlobal(name)
    return name
  if isPrivate(name)
    return join(toCallerID(scriptName), name[1..])
  else
    return getROSNamespace() + name

# Generate a ROS-legal 'anonymous' name
genAnonymous = (id = 'anonymous') ->
  host = os.hostname().replace(/[\.-:]/, '_')
  rand = crypto.randomBytes(16).toString('hex')
  "#{id}_#{host}_#{process.pid}_#{rand}"

# Load name mappings encoded in command-line arguments. This will filter
# out any parameter assignment mappings.
#
# @param [[String]] argv
# @return [{String: String}]
loadMapping = (argv) ->
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
getROSNamespace = (environ = process.env, argv = process.argv) ->
  for arg in argv
    if arg.startsWith NS_PREFIX
      return toGlobal(arg[NS_PREFIX.length..])
  return toGlobal(environ[env.ROS_NAMESPACE] || GLOBAL_NAMESPACE)

exports.isLegal = isLegal
exports.isLegalBaseName = isLegalBaseName
exports.isGlobal = isGlobal
exports.isPrivate = isPrivate

exports.toGlobal = toGlobal
exports.toCallerID = toCallerID

exports.namespaceOf = namespaceOf
exports.canonicalize = canonicalize
exports.join = join

exports.genAnonymous = genAnonymous

exports.resolve = resolve
exports.resolveScriptName = resolveScriptName

exports.loadMapping = loadMapping
exports.getROSNamespace = getROSNamespace
