# SQLPackage
SQLPackage is a Swift Package which includes SQLDataAccess, DataManager, Sqldb in Swift.

It makes using SQLite super easy and intuitive.

## Adding to Your Project
You only need to add SQLPackage to your Xcode Project to use.

It will also add two other packages, Apples Logger, and ObjectMapper, this is done automatically through the package dependencies.
  
To add this package go to Xcode Project 'Info' 'Build Settings' 'Swift Packages' select 'Swift Packages' and hit the '+' button and then enter the URL(git@github.com:pmurphyjam/SQLPackage.git) for this. Xcode should then do the rest for you. There will be three Packages, SQLDataAccess, DataManager, Sqldb, click on all three.

## Initializing SQLPackage

The SQLPackage is first of all easy to instantiate since it's a Swift Package.

The default SQL DB is named, "SQLite.db", but you can name it anything by calling setDBName. You do this all through DataManager. First init DataManager, then setDBName, then open the DB connection. This actually copies the DB into the Documents directory so it can be accessed.

```swift
    DataManager.init()
    DataManager.setDBName(name:"MySQL.db")
    let opened = DataManager.openDBConnection()
```
   You will need to put "MySQL.db" into a Resources directory so Xcode can see it. You can then edit the tables in "MySQL.db" or use Table Create to create your own tables for it. DataManager expects to find "MySQL.db" in Bundle directory of your App. If your DB is copied correctly opened will return true.
   
## Writing SQL Statements with Codable Models

SQLPackage with Sqldb.swift makes it super easy to create SQL Queries like: 

'insert into AppInfo (name,value,descrip) values(?,?,?)'

In addition queries like insert and update are created automatically for you so you don't have to write these out. To do this you need to create a Codable model for your DB table.

```swift
import UIKit
import ObjectMapper
import SQLDataAccess
import Sqldb
struct AppInfo: Codable,Sqldb,Mappable {
    
    //Define tableName for Sqldb required for Protocol
    var tableName : String? = "AppInfo"
    var name : String? = ""
    var value : String? = ""
    var descrip : String? = ""
    var date : Date? = Date()
    var blob : Data?
    //Optional sortAlpha default is false
    var sortAlpha: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case value = "value"
        case descrip = "descrip"
        case date = "date"
        case blob = "blob"
    }
    
    init?(map: Map) {
    }
    
    public mutating func mapping(map: Map) {
        name <- map["name"]
        value <- map["value"]
        descrip <- map["descrip"]
        date <- map["date"]
        blob <- map["blob"]
    }
    
    public func dbDecode(dataArray:Array<[String:AnyObject]>) -> [AppInfo]
    {
        //Maps DB dataArray [SQL,PARAMS] back to AppInfo from a DB select or read
        var array:[AppInfo] = []
        for dict in dataArray
        {
            let appInfo = AppInfo(JSON:dict )!
            array.append(appInfo)
        }
        return array
    }
        
    init (name:String,value:String,descrip:String,date:Date,blob:Data)
    {
        self.name = name
        self.value = value
        self.descrip = descrip
        self.date = date
        self.blob = blob
    }
    
    public init() {
        name = ""
        value = ""
        descrip = ""
        date = Date()
        blob = nil
    }
}

```

  The AppInfo.swift struct shows you how to write your Codable Models for your DB. It uses Codable, Sqldb, and Mappable. You need to define 'tableName' and then all the columns in your DB table. The func dbDecode Maps the SQL & PARAMS Dictionary which you get back from SQLDataAccess back to an AppInfo struct for you so your View Controller can consume it. You will need to follow the above construct for all your tables in SQLite.
  
### Create Your Models 
  
  You will also need to create a Models.swift struct which creates your SQL functions for AppInfo. InsertAppInfoSQL automatically creates the insert SQL & PARAMS Dictionary for you by using the Sqldb.getSQLInsert() method. The same goes for updateAppInfoSQL. Both these methods insert or update Null or Nil data. If you want the SQL to skip over Null or Nil data in the SQL & PARAMS use the sqldb.getSQLInsertValid() or sqldb.getSQLUpdateValid methods, and only valid data will be inserted or updated. The function Models.getAppInfo reads the DB and returns SQL & PARAMS Dictionary and then Maps this to the AppInfo struct by using dbDecode method, and does this in just 7 lines of code for any structure.
  
  The Sqldb package creates the SQL for update, insert, and upsert for you automatically so you don't need to write the SQL for these common queries. An updateValid, insertValid, and upsertValid checks the vars or parameters in your query, and if the values are unknown or nil then the update does not change the values in the existing table thus retaining prior values all ready written into the DB. 
  
  To use these Sqldb methods to generate your SQL queries automatically, just call them on your Codable model as : getSQLInsert(), getSQLInsertValid(), getSQLUpdate(whereItems:), getSQLUpdateValid(whereItems:), getSQLUpsertValid(whereItems:,forId:). Upsert is explained more later in this document.
 
 ```swift
import Foundation
import Logging
import DataManager

struct Models {

    static let SQL             = "SQL"
    static let PARAMS          = "PARAMS"
    
    static var log: Logger
    {
        var logger = Logger(label: "Models")
        logger.logLevel = .debug
        return logger
    }
    
    // MARK: - AppInfo
    static func insertAppInfoSQL(_ obj:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL insert syntax for us
        //creates SQL : insert into AppInfo (name,value,descript,date,blob) values(?,?,?,?,?)
        let sqlParams = obj.getSQLInsert()!
        log.debug("insertAppInfoSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func insertAppInfo(_ obj:AppInfo) -> Bool
    {
        let sqlParams = self.insertAppInfoSQL(obj)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func insertAppInfoValidSQL(_ obj:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL insert syntax for us
        //creates SQL : insert into AppInfo (name,value,descript,date,blob) values(?,?,?,?,?)
        let sqlParams = obj.getSQLInsertValid()!
        log.debug("insertAppInfoValidSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func insertAppInfoValid(_ obj:AppInfo) -> Bool
    {
        let sqlParams = self.insertAppInfoValidSQL(obj)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func updateAppInfoSQL(_ obj:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL update syntax for us
        //creates SQL : update AppInfo set value = ?, descrip = ?, data = ?, blob = ? where name = ?
        let sqlParams = obj.getSQLUpdate(whereItems:"name")!
        log.debug("updateAppInfoSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func updateAppInfo(_ obj:AppInfo) -> Bool
    {
        let sqlParams = self.updateAppInfoSQL(obj)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func updateAppInfoValidSQL(_ obj:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL update syntax for us
        //creates SQL : update AppInfo set value = ?, descrip = ?, data = ?, blob = ? where name = ?
        let sqlParams = obj.getSQLUpdateValid(whereItems:"name")!
        log.debug("updateAppInfoSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func updateAppInfoValid(_ obj:AppInfo) -> Bool
    {
        let sqlParams = self.updateAppInfoValidSQL(obj)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func upsertAppInfoValidSQL(_ obj:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL upsert syntax for us
	//creates update or insert SQL : insert into AppInfo (name,value,descript,date,blob) values(?,?,?,?,?) on conflict(id) do update set 
	//value = ?, descrip = ?, data = ?, blob = ? where name = ?
        let sqlParams = obj.getSQLUpsertValid(whereItems:"name",forId:"id")!
        log.debug("upsertAppInfoValidSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func upsertAppInfoValid(_ obj:AppInfo) -> Bool
    {
        let sqlParams = self.upsertAppInfoValidSQL(obj)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func getAppInfo() -> [AppInfo]
    {
        let appInfo:AppInfo? = AppInfo()
        let dataArray = DataManager.dataAccess.getRecordsForQuery("select * from AppInfo ")
        let appInfoArray = appInfo?.dbDecode(dataArray:dataArray as! Array<[String : AnyObject]>)
        return appInfoArray!
    }
    
    static func doesAppInfoExistForName(_ name:String) -> Bool
    {
        var status:Bool? = false
        let dataArray = DataManager.dataAccess.getRecordsForQuery("select name from AppInfo where name = ?",name)
        if (dataArray.count > 0)
        {
            status = true
        }
        return status!
    }
 
 ```
  
  And that's it, now you can add additional methods to your Model's struct and create Models for other tables if you want. 
  
  Since this is just a Swift Package, it doesn't include AppInfo or Models, but 
  
  [SQLiteDemo](https://github.com/pmurphyjam/SQLiteDemo).
  
  Shows you how to use this Swift Package and creates these structures and models for you.
  
  For your App you'll need to create a new AppInfo struct and the equivalent Model for it.
  
## Advantages of using SQLPackage
  
  As you can see writing the SQL statements is easy for your Models since SQLDataAccess supports writing the SQL statements directly with simple strings like, 'select * from AppInfo'. You don't need to worry about Preferred Statements and obscure SQLite3 low level C method calls, SQLDataAccess does all that for you, and is battle tested so it doesn't leak memory and uses a queue to sync all your operations so they are guaranteed to complete on the proper thread. SQLDataAccess can run on the back ground thread or the foreground thread without crashing unlike Core Data and Realm. Typically you'll write or insert into your DB on a back ground thread through a Server API using Alamofire and decode the Server JSON using the Codable Model defined in AppInfo.swift. Once your data has been written into SQLite, then just issue a completion event to your View Controller, and then call your View Model which will then consume the data from SQLDataAccess on the foreground thread to display your just updated data in your view controller so it can display it.

You can also write the SQL Queries if you choose too, but having the Models.swift do it for you takes advantage of Sqldb extension which creates the inserts and updates for you automatically as long as you define your Codable model properly. 

## SQL Transactions

SQLDataAccess supports high performance SQL Transactions for insert or update along with select SQL statements. This is where you can literally write 1,000 inserts or updates into the DB all at once, and SQLite will do this very quickly. In addition you can perform select Transactions where you can literally query a 1,000 select statements at once and retrieve all the results of this query. All Transactions are is an Array of SQL Queries that are append together, and then you execute all of them at once with:

```swift
   let status1 = DataManager.dataAccess.executeTransaction(sqlAndParams)
   OR
   let dataArray = DataManager.dataAccess.getRecordsForQueryTrans(sqlAndParams)
```

The advantage of this is you can literally insert, update, or select 1,000 Objects at once which is exponentially faster than doing individual inserts, updates or selects back to back. This comes in very handy when your Server API returns a hundred JSON objects that need to be saved in your DB quickly, or you're querying a 100 selects and displaying these Objects in a View. SQLDataAccess spends no more than a few hundred milliseconds writing all that data into the DB, rather than seconds if you were to do them individually.

The executeStatementSQL and getRecordsForQuerySQL will take a regular SQL Query with Parameters and output sqlAndParams Array's that can be appended too and consumed by executeTransaction or getRecordsForQueryTrans.

The power of Transactions give's SQLite high performance capabilities.

## Back Ground Concurrent Processes
SQLDataAccess supports synchronous inserts or updates, and can also perform writes on background concurrent threads into SQLite, this can speed up writing into the DB for transactions or inserts or updates, just call any of the DataAccess methods with a '**BG**' after the method name in order to execute these methods. These background methods can dramatically speed up the writing of the data into SQLite for large amounts of data.

## Simple SQL Queries

When you write your SQL Queries as a String, all the terms that follow are in a variadic argument list of type Any, and your parameters are in an Array. All these terms are separated by commas in your list of SQL arguments. You can enter Strings, Integers, Date’s, and Blobs right after the sequel statement since all of these terms are considered to be parameters for the SQL. The variadic argument array just makes it convenient to enter all your sequel in just one executeStatement or getRecordsForQuery call. If you don’t have any parameters, don’t enter anything after your SQL.

## Upsert Capability For High Performance

Usually in order for you to insert or update the SQLite DB, you need to know if the data already exists in the DB or not. As such you usually execute a SQL query to determine if the data exists, if it does you do an update, if it doesn't you then do an insert. When fetching lots of data from a Server where megabytes of JSON comes down and then needs to be written into the DB, the SQL query to determine if it exists or not can become expensive performance wise. To get around this issue SQLite supports Upsert which is really just an Insert followed by an On Conflict(id) Do Update SQL Query. The On Conflict statement needs an indexed column that is unique in order to work, a column like id will work. Using the Upsert command you now don't need a separate lookup anymore, and your Codable Model can just parse the JSON and then write it directly into the DB using the Upsert command. The Upsert SQL query will determine if it needs to do an insert or an update automatically. The Sqldb package will create the SQL for you for the Upsert command, simply call Sqldb : getSQLUpsertValid(whereItems:"items",forId:"id") where the forId is the column that is indexed and has to be unique.

Using Upsert you can see a 2X performance speed up for inserting or updating large amounts of data into SQLite.

## Data Types SQLDataAccess Supports

The results array is an Array of Dictionary’s where the ‘key’ is your tables column name, and the ‘value’ is your data obtained from SQLite. You can easily iterate through this array with a for loop or print it out directly or assign these Dictionary elements to custom data object Classes that you use in your View Controllers for model consumption.

SQLDataAccess will store, ***text, double, float, blob, Date, integer and long long integers***. 

For Blobs you can store ***binary, varbinary, blob, Data.***

You can store Swift Data types directly.

For Text you can store ***char, character, clob, national varying character, native character, nchar, nvarchar, varchar, variant, varying character, text***.

For Dates you can store ***datetime, time, timestamp, date.*** No need to convert Dates to Strings and back and forth, SQLDataAccess does all that for you! Dates should always be stored as UTC in the DB and are stored using DataFormatter ***yyyy-MM-dd HH:mm:ss*** so DataFormatter takes care of day light savings time for the "en\_US\_POSIX" local you are in.

For Integers you can store ***bigint, bit, bool, boolean, int2, int8, integer, mediumint, smallint, tinyint, int.***

For Doubles you can store ***decimal, double precision, float, numeric, real, double.*** Double has the most precision.

You can even store Nulls of type ***Null.***

You can also store Swift UUID directy of type ***UUID.***

You just declare these types in tables, and and your Codable struct, and SQLDataAccess does the rest for you!

## Support for Foreign Keys
SQLite supports foreign Keys which are used to enforce relationships between table Id's. These keys speed up your SQL queries and make it easy to delete or update items in tables quickly. By default SQLite comes with foreignKeys disabled, you have to turn it on with:

```swift
DataManager.openDBConnection()
DataManager.dataAcess.foreignKeys(true)

```
Now foreign Key access is enabled and checked on all your SQL queries. Typically the Id's are primary keys that exist in the Parent and Child tables with the Child table having the foreign key constraints. The Id's must unique and can not be Null, and you can delay the foreign key check by adding a deferred clause, this means they will only be checked when the transaction is committed. For more information on foreign keys search for 'SQLite Foreign Key Support' in Google.

## SQLCipher and Encryption
	
In addition SQLDataAccess will also work with SQLCipher, and it's pretty easy to do. To use SQLCipher you must remove 'libsqlite3.tbd' and add 'libsqlcipher-ios.a'. You must also add '-DSQLITE_HAS_CODEC', you then encrypt the Database by calling DataManager.dbEncrypt(key), and you can decrypt it using DataManager.dbDecrypt(). You just set your encryption key, and your done. 

## Battle Tested and High Performance

SQLDataAccess is a very fast and efficient class and guaranteed to not leak memory, and uses the low level C calls from SQLite, and nothing is faster then low level C. In addition it is thread safe so you can read or write your DB on the foreground or background threads without crashing or corrupting your data. SQLDataAccess can be used in place of CoreData or Realm or FMDB. CoreData really just uses SQLite as it's underlying data store without all the CoreData integrity fault crashes that come with CoreData. CoreData and Realm need to update their models on the main thread which is a real problem if you're trying to display data in a view controller which is consuming a lot of data at the same time. This means your view controller will become slow and not scroll efficiently for a TableView or CollectionView because it's updating CoreData or Realm Entities. In addition if you do these updates on a background thread Core Data and Realm will crash. SQLDataAccess has none of these threading problems, and you can read or write data on either the background or foreground threads.

So make your life easier, and all your Apps more reliable, and use SQLPackage, and best of all it's free with no license required!
