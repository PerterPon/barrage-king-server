
# /*
#   aio
# */
# Author: PerterPon<PerterPon@gmail.com>
# Create: Wed Aug 12 2015 07:30:59 GMT+0800 (CST)
#

"use strict"

path    = require 'path'

fs      = require 'fs'

pm2     = require 'pm2'

JustLog = require 'justlog'

common  = require './common'

os      = require 'os'

log     = require( './log' )()

class Aio

  constructor : ( env ) ->
    @env    = env
    @config = common.getConfig()
    @init()

  init : ->
    # @initLog()
    @initRunner()
    @start()

  start : ->
    script     = path.join __dirname, './worker.js'
    processNum = @_getPorcessNumber()
    option     =
      name       : "#{@config.name}@#{@config.version}"
      script     : script
      args       : [ @config.runner ]
      exec_mode  : 'cluster_mode'
      instances  : processNum
      cwd        : process.cwd()
      env        : {
        NODE_ENV   : @env
      }
      out_file   : path.join process.cwd(), './log/child_stdout.log'
      error_file : path.join process.cwd(), './log/child_stderr.log'
      log_date_format : 'YYYY-MM-DD HH:mm:ss Z'
      merge_logs : true

    pm2.connect ->
      log.info 'pm2 connect'
      pm2.start option, ( err, subProcess ) ->
        log.info 'application has been successfully started!'
        pm2.disconnect()

  _getPorcessNumber : () ->
    { process_num } = @config
    process_num ?= 'auto'
    number   = null
    if 'auto' is process_num
      number = os.cpus().length
    else
      number = process_num

    return number

  initRunner : ->
    { runner } = @config
    unless runner?
      log.warn '\"runner\" option was not specified, use default runner: hc-cover-runner'
      runner   = 'hc-cover-runner'
      @config.runner = runner

module.exports = Aio
