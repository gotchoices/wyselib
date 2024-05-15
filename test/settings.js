//Copyright WyattERP.org; See license in root of this package
// -----------------------------------------------------------------------------
const Path = require('path')
const SchemaDir = Path.resolve(Path.join(__dirname, '..', 'schema'))

var schemaFile = function(release, extension = '.json') {
  return Path.join(SchemaDir, 'schema-' + release + extension)
}

module.exports = {
  TestDB: "wyselibTestDB",
  Module: "wltest",
  DBHost: process.env.WYSELIB_DBHOST || "localhost",
  DBPort: process.env.WYSELIB_DBPORT || 5432,
  DBAdmin: process.env.WYSELIB_DBUSER || "admin",
  SchemaDir: SchemaDir,
  Log: require(require.resolve('wyclif/lib/log.js')),
  DbClient: require(require.resolve('wyseman/lib/dbclient.js')),
  SchemaFile: schemaFile,
}
