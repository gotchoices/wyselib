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
const SchemaList = "'{wylib,base}'"
var log = Log('test-schema')

describe("Schema: Build DB schema files", function() {
  var db

  before('Delete sample database if it exists', function(done) {
    Child.exec(`dropdb -U ${DBAdmin} ${TestDB}`, (err, out) => done())
  })

  before('Build schema database', function(done) {
    Child.exec("wyseman objects text defs init", {cwd: __dirname}, (e,o) => {if (e) done(e); done()})
  })

  before('Connect to schema database', function(done) {
    db = new DbClient(dbConfig, ()=>{}, ()=>{
      log.debug("Connected to DB");
      done()
    })
  })

  it('should have 9 wyseman tables built', function(done) {
    let sql = "select * from pg_tables where schemaname = 'wm'"
    db.query(sql, null, (e, res) => {if (e) done(e)
log.debug("Tables:", res.rows)
      assert.equal(res.rows.length, 9)
      done()
    })
  })

  it('should have 13 wyselib tables built', function(done) {
    let sql = "select * from pg_tables where schemaname = 'base'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 13)
      done()
    })
  })

  it('should have expected wyselib column text descriptions', function(done) {
    let sql = "select * from wm.column_text where ct_sch = 'base'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 176)
      done()
    })
  })

  it('should have expected wyselib column defaults', function(done) {
    let sql = "select * from wm.column_def where obj ~ '^base.'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 264)
      done()
    })
  })

  it('should have expected rows in base.countries', function(done) {
    let sql = "select * from base.country"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 242)
      done()
    })
  })

  it('check for undocumented tables', function(done) {
    let sql = `select sch,tab from wm.table_lang where language = 'en' and help is null and sch in (${SchemaList}) order by 1,2`
    db.query(sql, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 0)
      done()
    })
  })

  it('check for undocumented columns', function(done) {
    let sql = `select sch,tab,col from wm.column_lang where language = 'en' and help is null and sch in (${SchemaList}) order by 1,2`
    db.query(sql, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 0)
      done()
    })
  })

  after('Disconnect from test database', function(done) {
    db.disconnect()
    done()
  })
})
