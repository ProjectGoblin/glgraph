process = require 'process'

ROS_MASTER_URI = "ROS_MASTER_URI"

ROS_IP = "ROS_IP"
ROS_IPV6 = "ROS_IPV6"
ROS_HOSTNAME = "ROS_HOSTNAME"
ROS_NAMESPACE = "ROS_NAMESPACE"

# Get the :envvar:`ROS_MASTER_URI` setting from the command-line args or
#       environment, command-line args takes precedence.
#
# :param env: override environment dictionary, ``dict``
#   :param argv: override ``sys.argv``, ``[str]``
#   :raises: :exc:`ValueError` If :envvar:`ROS_MASTER_URI` value is invalidly
# specified
getMasterURI = (env = null, argv = null) ->
  MASTER_PREFIX = '__master:='
  env ?= process.env
  argv ?= process.argv
  # remapped in argv?
  for arg in argv
    if arg.startsWith MASTER_PREFIX
      val = arg.split(':=')
      if val.length != 2 or val[1].length == 0
        throw Error "__master remapping argument #{arg} improperly specified"
      return val[1]
  # remapped in ENV?
  return env[ROS_MASTER_URI] || null

exports.getMasterURI = getMasterURI
exports.ROS_MASTER_URI = ROS_MASTER_URI
exports.ROS_IP = ROS_IP
exports.ROS_IPV6 = ROS_IPV6
exports.ROS_HOSTNAME = ROS_HOSTNAME
exports.ROS_NAMESPACE = ROS_NAMESPACE
