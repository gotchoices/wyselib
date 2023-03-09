//Build test database schema; Run first
//Copyright WyattERP.org; See license in root of this package
// -----------------------------------------------------------------------------
// TODO
//- 
const assert = require("assert");
const Fs = require('fs')
const Path = require('path')
const Child = require('child_process')
const { TestDB, DBAdmin, Log, DbClient, SchemaDir, SchemaFile, WmItems } = require('./settings')
const dbConfig = {database: TestDB, user: DBAdmin, connect: true}
const SchemaList = "'wylib','base'"
var log = Log('test-schema')

describe("Schema: Build DB schema files", function() {
  var db

  before('Delete sample database if it exists', function(done) {
    Child.exec(`dropdb --if-exists -U ${DBAdmin} ${TestDB}`, (e) => done(e))
  })

  before('Build schema database', function(done) {
    this.timeout(10000)				//Build may be a little slow
    Child.exec("wyseman objects text defs init", {cwd: __dirname}, (e) => {done(e)})
  })

  before('Connect to schema database', function(done) {
    db = new DbClient(dbConfig, null, ()=>{
      log.debug("Connected to DB");
      done()
    })
  })

  it('Should have expected wyseman tables built', function(done) {
    let sql = "select * from pg_tables where schemaname = 'wm'"
    db.query(sql, null, (e, res) => {if (e) done(e)
//log.debug("Tables:", res.rows)
      assert.equal(res.rows.length, 9)
      done()
    })
  })

  it('Should have expected wyselib tables built', function(done) {
    let sql = "select * from pg_tables where schemaname = 'base'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 17)
      done()
    })
  })

  it('Should have expected wyselib column text descriptions', function(done) {
    let sql = "select * from wm.column_text where ct_sch = 'base'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 200)
      done()
    })
  })

  it('should have expected wyselib column defaults', function(done) {
    let sql = "select * from wm.column_def where obj ~ '^base.'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 318)
      done()
    })
  })

  it('should have expected rows in base.countries', function(done) {
    let sql = "select * from base.country"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 249)
      done()
    })
  })

  it('check for undocumented tables', function(done) {
    let sql = `select sch,tab from wm.table_lang where help is null and sch in (${SchemaList}) order by 1,2`
log.debug("Sql:", sql)
    db.query(sql, (e, res) => {if (e) done(e)
log.debug("res:", res.rows ? JSON.stringify(res.rows) : null)
      assert.equal(res.rows.length, 0)
      done()
    })
  })

  it('check for undocumented columns', function(done) {
    let sql = `select sch,tab,col from wm.column_lang where help is null and sch in (${SchemaList}) order by 1,2`
log.debug("Sql:", sql)
    db.query(sql, (e, res) => {if (e) done(e)
log.debug("res:", res)
      assert.equal(res.rows.length, 0)
      done()
    })
  })
/* */
  after('Disconnect from test database', function(done) {
    db.disconnect()
    done()
  })
})
