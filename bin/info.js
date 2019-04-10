#!/usr/bin/env node
//Return information about the currently installed wylib package
//Copyright WyattERP.org; See license in root of this package
// -----------------------------------------------------------------------------
const Path = require("path")
var package = require('../package.json')
var parent = Path.normalize(Path.join(__dirname, '../..'))

console.log(parent, package.name, package.version)
