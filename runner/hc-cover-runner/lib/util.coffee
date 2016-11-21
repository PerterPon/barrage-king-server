 # util.coffee 应用管理的工具
 # honeycomb - lib/woerker/util.coffee
 # Copyright(c) 2014 Alibaba.com
 # Author: jifeng.zjd <jifeng.zjd@taobao.com>

parse        = require('url').parse
clone        = require 'clone'
fs           = require 'fs'
path         = require 'path'
os           = require 'options-stream'

#主路由的解析
exports.normalExtension = ( url, extensions )->
  urls         = url or []

  defaulMethod = undefined
  for url in urls
    pathname = parse(url, true).pathname
    if 0 <= pathname.indexOf ':'
      defaulMethod = 'all'
      break
  lists = []
  for k, v of extensions
    arr = k.split('>')
    module = arr[0]
    pathname = '/'
    method = defaulMethod
    if arr.length is 2
      module = arr[1]
      pathname = arr[0]
    # 针对路由 '/ > get > ./lib/show'
    else if arr.length is 3
      module = arr[2]
      method = arr[1]
      pathname = arr[0]
    module = module.trim()
    mm = module.split ' '
    module = mm[0].trim()
    fmethod = mm[1] and mm[1].trim()
    #判断是否需要解析参数
    if pathname.indexOf(':') > 0 and method is undefined
      method = 'all'
    
    pathname = pathname.trim()
    #参数解析url
    if method isnt undefined
      if pathname[pathname.length - 1] is '/'
        pathname = pathname.substr(0, pathname.length - 1)
        pathname += '*'
    lists.push {module: module, method: method and method.trim(), pathname: pathname, options: v || {}, fmethod: fmethod }
  
  return lists

#子路由的解析
exports.normalSubExtension = (extensions, method)->
  lists = []
  for k, v of extensions
    arr = k.split('>')
    pathname = arr[0]
    # method = undefined
    if arr.length is 2
      method = arr[1]
    #判断是否需要解析参数
    if pathname.indexOf(':') > 0 and method is undefined
      method = 'all'
    pathname = pathname.trim()
    if method isnt undefined
      if pathname[pathname.length - 1] is '/'
        pathname = pathname.substr(0, pathname.length - 1)
        pathname += '*'
    lists.push { method: method and method.trim().toLowerCase(), pathname: pathname, to: v }
  return lists

exports.getWebsocketPrefix = (prefixs) ->
  val = prefixs[0]
  return if val and '/' isnt val then val else ''


exports.getAppconfig = (dir) ->
  config = undefined
  return undefined if false is fs.existsSync dir
  try
    if true is fs.existsSync(path.join(dir, 'config.yaml'))
      config = os(path.join(dir, 'config.yaml'))
    else if true is fs.existsSync(path.join(dir, 'etc/config.yaml'))
      config = os(path.join(dir, 'etc/config.default.yaml'), path.join(dir, 'etc/config.yaml'))
    else
      config = os(path.join(dir, 'etc/config.default.yaml'))
  catch err
    console.log err
    return undefined
  config || {}

#判断son是否是father的子函数
exports.checkContain = (father, son)->
  return true if father is 'all' or father is undefined
  return true if father is son
  return true if son is undefined
  return false
