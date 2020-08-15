//
//  DataManager.swift
//  SQLPackage
//
//  Created by Pat Murphy on 8/10/20.
//  The MIT License (MIT)
//

import UIKit

open class DataManager: NSObject {

    static var dataAccess = SQLDataAccess()
    static var dateFormatter = DateFormatter()

    @discardableResult public override init() {
        super.init()
        //for 24-hour format need locale to work, ISO-8601 format
        DataManager.dateFormatter.locale = Locale(identifier:"en_US_POSIX")
        DataManager.dateFormatter.timeZone = TimeZone(secondsFromGMT:0)
        DataManager.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    class func initDateFormatters()
    {
        DataManager.dateFormatter.locale = Locale(identifier:"en_US_POSIX")
        DataManager.dateFormatter.timeZone = TimeZone(secondsFromGMT:0)
        DataManager.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    class func closeDBConnection()
    {
        dataAccess.closeConnection()
    }
    
    class func openDBConnection() -> Bool
    {
        let status:Bool = dataAccess.openConnection(copyFile:true)
        return status
    }
    
    class func getCurrentTimeStamp() -> Int64
    {
        let utcEpoc  = Int64(Date().timeIntervalSince1970)
        return utcEpoc
    }
    
    class func utcDateTime() -> String
    {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.init(abbreviation:"UTC")
        let utcDateTime  = dateFormatter.string(from:Date())
        return utcDateTime
    }
    
    class func pathForFileWithName(fileName:String) -> String
    {
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = (docDir as NSString).appendingPathComponent(fileName)
        if (fm.fileExists(atPath:path))  {
            var url = NSURL.fileURL(withPath: docDir)
            url.setTemporaryResourceValue(NSNumber(value:true), forKey: URLResourceKey.isExcludedFromBackupKey)
            return path
        }
        else
        {
            assert(false, "DM : pathFor : Path for file \(fileName)! Not Found ")
            return ""
        }
    }
    
    class func doesFileExistWithName(fileName:String) -> Bool
    {
        var status:Bool = false
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = (docDir as NSString).appendingPathComponent(fileName)
        if (fm.fileExists(atPath:path))  {
            status = true
        }
        return status
    }
    
    class func deleteFileWithName(fileName:String) -> Bool
    {
        var status:Bool = false
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = (docDir as NSString).appendingPathComponent(fileName)
        do {
            try fm.removeItem(atPath: path)
            status = true
        } catch let error {
            assert(false, "DM : deleteFile : Failed to delete file \(fileName)! Error - \(error.localizedDescription)")
            status = false
        }
        return status
    }
    
    class func moveDBtoDocumentDirectory(fileName:String) -> Bool
    {
        var status:Bool = false
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = (docDir as NSString).appendingPathComponent(fileName)
        guard let rp = Bundle.main.resourcePath else { return false }
        let from = (rp as NSString).appendingPathComponent(fileName)
        do {
            try fm.copyItem(atPath:from, toPath:path)
            status = true
        } catch let error {
            assert(false, "DA : moveDB : Failed to move file \(fileName)! to Documents Directory Error - \(error.localizedDescription)")
            status = false
        }
        return status
    }
    
    @discardableResult class func copyDBtoDocumentDirectory(copyDBFile:String, toDBFile:String) -> Bool
    {
        var status:Bool = false
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let copyDBPath = (docDir as NSString).appendingPathComponent(copyDBFile)
        let toDBPath = (docDir as NSString).appendingPathComponent(toDBFile)
        
        if !(fm.fileExists(atPath:copyDBPath)) {
            do {
                try fm.copyItem(atPath:copyDBPath, toPath:toDBPath)
                status = true
            } catch let error {
                assert(false, "DA : copyDB : Failed to copy file \(copyDBPath) to \(toDBPath) Error - \(error.localizedDescription)")
                status = false
            }
        }
        return status
    }
    
    @discardableResult class func replaceDBinDocumentDirectory(removeDBFile:String, renameDBFile:String) -> Bool
    {
        var status:Bool = false
        let fm = FileManager.default
        let docDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let removeDBPath = (docDir as NSString).appendingPathComponent(removeDBFile)
        let renameDBPath = (docDir as NSString).appendingPathComponent(renameDBFile)
        
        do {
            try fm.removeItem(atPath: removeDBPath)
            status = true
        } catch let error {
            assert(false, "DM : replaceDB : Failed to remove file \(removeDBFile)! Error - \(error.localizedDescription)")
            status = false
            return status
        }
        
        do {
            try fm.moveItem(atPath: renameDBPath, toPath: removeDBPath)
            status = true
        } catch let error {
            assert(false, "DM : replaceDB : Failed to move file \(renameDBFile)! Error - \(error.localizedDescription)")
            status = false
            return status
        }
        
        if !(fm.fileExists(atPath:removeDBPath)) {
            assert(false, "DA : replaceDB : Failed to replace file \(removeDBFile) with \(renameDBFile) Error ")
            status = false
        }
        return status
    }
    
}
