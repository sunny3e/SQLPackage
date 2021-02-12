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
  
  You will also need to create a Models.swift struct which creates your SQL functions for AppInfo. InsertAppInfoSQL automatically creates the insert SQL & PARAMS Dictionary for you by using the Sqldb.getSQLInsert() method. The same goes for updateAppInfoSQL. The function Models.getAppInfo reads the DB and returns SQL & PARAMS Dictionary and then Maps this to the AppInfo struct by using dbDecode method, and does this in just 7 lines of code for any structure.
 
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
    static func insertAppInfoSQL(_ appInfo:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL insert syntax for us
        //creates SQL : insert into AppInfo (name,value,descript,date,blob) values(?,?,?,?,?)
        let sqlParams = appInfo.getSQLInsert()!
        log.debug("insertAppInfoSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func insertAppInfo(_ appInfo:AppInfo) -> Bool
    {
        let sqlParams = self.insertAppInfoSQL(appInfo)
        let status = DataManager.dataAccess.executeStatement(sqlParams[SQL] as! String, withParams: sqlParams[PARAMS] as! Array<Any>)
        return status
    }
    
    static func updateAppInfoSQL(_ appInfo:AppInfo) -> Dictionary<String,Any>
    {
        //Let Sqldb create the SQL update syntax for us
        //creates SQL : update AppInfo set value = ?, descrip = ?, data = ?, blob = ? where name = ?
        let sqlParams = appInfo.getSQLUpdate(whereItems:"name")!
        log.debug("updateAppInfoSQL : sqlParams = \(sqlParams) ")
        return sqlParams
    }
    
    @discardableResult static func updateAppInfo(_ appInfo:AppInfo) -> Bool
    {
        let sqlParams = self.updateAppInfoSQL(appInfo)
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

SQLDataAccess supports high performance SQL Transactions. This is where you can literally write 1,000 inserts into the DB all at once, and SQLite will do this very quickly. All Transactions are is an Array of SQL Queries that are append together, and then you execute all of them at once with:

```swift
   let status1 = DataManager.dataAccess.executeTransaction(sqlAndParams)
```

The advantage of this is you can literally insert 1,000 Objects at once which is exponentially faster than doing individual inserts back to back. This comes in very handy when your Server API returns a hundred JSON objects that need to be saved in your DB quickly. SQLDataAccess spends no more than a few hundred milliseconds writing all that data into the DB, rather than seconds if you were to do them individually.

## Simple SQL Queries

When you write your SQL Queries as a String, all the terms that follow are in a variadic argument list of type Any, and your parameters are in an Array. All these terms are separated by commas in your list of SQL arguments. You can enter Strings, Integers, Date’s, and Blobs right after the sequel statement since all of these terms are considered to be parameters for the SQL. The variadic argument array just makes it convenient to enter all your sequel in just one executeStatement or getRecordsForQuery call. If you don’t have any parameters, don’t enter anything after your SQL.

## Data Types SQLDataAccess Supports

The results array is an Array of Dictionary’s where the ‘key’ is your tables column name, and the ‘value’ is your data obtained from SQLite. You can easily iterate through this array with a for loop or print it out directly or assign these Dictionary elements to custom data object Classes that you use in your View Controllers for model consumption.

SQLDataAccess will store, ***text, double, float, blob, Date, integer and long long integers***. 

For Blobs you can store ***binary, varbinary, blob.***

For Text you can store ***char, character, clob, national varying character, native character, nchar, nvarchar, varchar, variant, varying character, text***.

For Dates you can store ***datetime, time, timestamp, date.*** No need to convert Dates to Strings and back and forth, SQLDataAccess does all that for you!

For Integers you can store ***bigint, bit, bool, boolean, int2, int8, integer, mediumint, smallint, tinyint, int.***

For Doubles you can store ***decimal, double precision, float, numeric, real, double.*** Double has the most precision.

You can even store Nulls of type ***Null.***

You just declare these types in tables, and and your Codable struct, and SQLDataAccess does the rest for you!

## SQLCipher and Encryption
	
In addition SQLDataAccess will also work with SQLCipher, and it's pretty easy to do. To use SQLCipher you must remove 'libsqlite3.tbd' and add 'libsqlcipher-ios.a'. You must also add '-DSQLITE_HAS_CODEC', you then encrypt the Database by calling DataManager.dbEncrypt(key), and you can decrypt it using DataManager.dbDecrypt(). You just set your encryption key, and your done. 

## Battle Tested and High Performance

SQLDataAccess is a very fast and efficient class and guaranteed to not leak memory, and uses the low level C calls from SQLite, and nothing is faster then low level C. In addition it is thread safe so you can read or write your DB on the foreground or background threads without crashing or corrupting your data. SQLDataAccess can be used in place of CoreData or Realm or FMDB. CoreData really just uses SQLite as it's underlying data store without all the CoreData integrity fault crashes that come with CoreData. CoreData and Realm need to update their models on the main thread which is a real problem if you're trying to display data in a view controller which is consuming a lot of data at the same time. This means your view controller will become slow and not scroll efficiently for a TableView or CollectionView because it's updating CoreData or Realm Entities. In addition if you do these updates on a background thread Core Data and Realm will crash. SQLDataAccess has none of these threading problems, and you can read or write data on either the background or foreground threads.

So make your life easier, and all your Apps more reliable, and use SQLPackage, and best of all it's free with no license required!
