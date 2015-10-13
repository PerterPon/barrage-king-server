
# /*
#   aio
# */
# Author: PerterPon<PerterPon@gmail.com>
# Create: Wed Aug 12 2015 07:30:59 GMT+0800 (CST)
# 

"use strict"

os      = require 'options-stream'

path    = require 'path'

fs      = require 'fs'

pm2     = require 'pm2'

JustLog = require 'justlog'

commom  = require './commom'

class Aio

  constructor : ->
    @config = commom.getConfig process.cwd()
    @init()

  init : ->
    @initLog()
    @initRunner()
    @start()

  start : ->
    script = path.join __dirname, './worker.js'
    option =
      name       : "#{@config.name}@#{@config.version}"
      script     : script
      args       : [ @config.runner ]
      exec_mode  : 'cluster_mode'
      instances  : @config.process_num
      cwd        : process.cwd()
      out_file   : process.cwd(), './log/child_stdout.log'
      error_file : process.cwd(), './log/child_stderr.log'

    pm2.connect ->
      pm2.start option, ( err, subProcess ) ->
        console.log 'application has been successfully started!'
        pm2.disconnect()

  initRunner : ->
    { runner } = @config
    unless runner?
      @log.warn '\"runner\" option was not specified, use default runner: hc-cover-runner'
      runner   = '@ali/hc-cover-runner'
      @config.runner = runner

  initLog : ->
    { log_dir } = @config
    log_dir ?= process.cwd()
    if 'dev' isnt process.env
      @log  = JustLog
        file  :
          level  : JustLog.ERROR | JustLog.INFO | JustLog.WARN
          path   : "[#{path.join log_dir, './log/hc-lite.log'}]"
          patten : 'file'
    else
      @log  = console

module.exports = Aio
