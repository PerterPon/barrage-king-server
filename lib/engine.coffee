
# /*
#   engine
# */
# Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
# Create: Tue Aug 25 2015 03:45:27 GMT+0800 (CST)
# 

"use strict"

commom = require './commom'

path   = require 'path'

cwd    = process.cwd()

config = commom.getConfig process.cwd()

CONFIG =
  dir     : cwd
  appname : "#{config.app}@#{config.version}"

start  = ( runner ) ->
  unless runner?
    console.warn '\"runner\" option was not specified, use default runner: hc-cover-runner'
    runner     = 'hc-cover-runner'

  try
    runnerPath = path.join __dirname, '../runner', runner
    Runner     = require runnerPath
  catch e
    return console.error "require runner: #{runner} with error:#{e.message}, does it exists? \n #{e.stack}"

  runnerIns = Runner CONFIG
  runnerIns.config.sock = config.port
  runnerIns.run()

module.exports = 
  start : start
