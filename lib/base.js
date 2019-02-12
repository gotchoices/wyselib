//Action control function handlers
//Copyright WyattERP.org; See license in root of this package
// ----------------------------------------------------------------------------
//TODO:
//- 
//var log = require('./logger')('control1')
//var wyseman = require('wyseman')
//var errCode = function(view, code) {return {code: '!' + view + '.' + code}}

// ----------------------------------------------------------------------------
//function errMsg(msg) {
//}

// ----------------------------------------------------------------------------
function func1(info, cb, resource) {
  let error
  log.debug('Calling func1', data)
  cb(error)
  return false
}

// ----------------------------------------------------------------------------
function func2(data, cb, resource) {
  let error
  log.debug('Calling func2', data)
  cb(error)
  return false
}

module.exports = {
  'base.ent_v': {func1, func2},
  'base.addr_v': {func1, func2},
  'base.comm_v': {func1, func2}
}
