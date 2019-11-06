//
//  RocksDBBackupEngine.h
//  ObjectiveRocks
//
//  Created by Iska on 28/12/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RocksDB.h"

@class RocksDBBackupInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 The `RocksDBBackupEngine` provides backup and restore functionality for RocksDB. Backups are incremental and
 each backup receives an ID, which can be used to restore that specific backup. Backups can also be deleted to
 reduce the total size and reduce restoration times.
 */
@interface RocksDBBackupEngine : NSObject

/**
 Initializes a new Backup Enginge with the given path as a destination directory.

 @param path The destination path for the new Backup Engine.
 @return The newly-created Backup Engine with the given destination path.
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 Initializes a new Backup Enginge with the given path as a destination directory.

 @param path The destination path for the new Backup Engine.
 @param env To create backupengine within
 @return The newly-created Backup Engine with the given destination path.
 */
- (instancetype)initWithPath:(NSString *)path env:(RocksDBEnv *)env;

/**
 Creates a new backup of the given database instance.

 @param database The database instance for which a backup is to be created.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the backup succeeded, `NO` otherwise.
 */
- (BOOL)createBackupForDatabase:(RocksDB *)database error:(NSError * _Nullable *)error;

/**
 Creates a new backup of the given database instance.

 @param database The database instance for which a backup is to be created.
 @param metadata Application metadata
 @param flush When true, the Backup Engine will first issue a
 memtable flush and only then copy the DB files to the backup directory. Doing so will prevent log
 files from being copied to the backup directory (since flush will delete them).
 When false, the Backup Engine will not issue a flush before starting the backup. In that case,
 the backup will also include log files corresponding to live memtables. If writes have
 been performed with the write ahead log disabled, set flushBeforeBackup to true to prevent those
 writes from being lost. Otherwise, the backup will always be consistent with the current state of the
 database regardless of the flushBeforeBackup parameter.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the backup succeeded, `NO` otherwise.
 */
- (BOOL)createBackupForDatabase:(RocksDB *)database metadata:(NSString *)metadata flushBeforeBackup:(BOOL)flush error:(NSError * _Nullable *)error;

/**
 Restores the latest backup of this Backup Engine to the given destination path.

 @param destination The destination path where the last backup is to be restored to.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the restore succeeded, `NO` otherwise.
 */
- (BOOL)restoreBackupToDestinationPath:(NSString *)destination error:(NSError * _Nullable *)error;

/**
 Restores the backup with the given ID in this Backup Engine to the given destination path.

 @param backupId The backup ID to restore.
 @param destination The destination path where the last backup is to be restored to.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the restore succeeded, `NO` otherwise.
 */
- (BOOL)restoreBackupWithId:(uint32_t)backupId toDestinationPath:(NSString *)destination error:(NSError * _Nullable *)error;

/**
 Deleted all backups from this Backup Engine keeping the last N backups.
 
 @param countBackups The count of backaups to keep in this Backup Engine.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the purge succeeded, `NO` otherwise.
 */
- (BOOL)purgeOldBackupsKeepingLast:(uint32_t)countBackups error:(NSError * _Nullable *)error;

/**
 Deletes a specific backup from this Backup Engine.

 @param backupId The ID of the backaup to delete from this Backup Engine.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
 @return `YES` if the delete succeeded, `NO` otherwise.
 */
- (BOOL)deleteBackupWithId:(uint32_t)backupId error:(NSError * _Nullable *)error;

/**
 Returns a list of backups in this Backup Engine together with information on timestamp of the backups
 and their sizes.

 @return An array containing `RocksDBBackupInfo` objects with informations about the backups.

 @see RocksDBBackupInfo
 */
- (NSArray<RocksDBBackupInfo *> *)backupInfo;

/**
 Returns a list of corrupted backup ids. If there is no corrupted backup the method will return an empty list.
 */
- (NSArray<NSNumber *> *)getCorruptedBackups;

/**
 Will delete all the files we don't need anymore. It will
 do the full scan of the files/ directory and delete all the
 files that are not referenced.
 */
- (BOOL)garbageCollect:(NSError * _Nullable *)error;

/**
 Restore the database from a backup

 IMPORTANT: if options.share_table_files == true and you restore the DB
 from some backup that is not the latest, and you start creating new
 backups from the new DB, they will probably fail!

 Example: Let's say you have backups 1, 2, 3, 4, 5 and you restore 3.
 If you add new data to the DB and try creating a new backup now, the
 database will diverge from backups 4 and 5 and the new backup will fail.
 If you want to create new backup, you will first have to delete backups 4
 and 5.

 @param backupId The id of the backup to restore
 @param dbDir The directory to restore the backup to, i.e. where your database is
 @param walDir The location of the log files for your database, often the same as dbDir
 @param keepLogFiles If true, restore won't overwrite the existing log files in wal_dir.
 It will also move all log files from archive directory to wal_dir. Use this option in combination with
 @param error filled if error was encountered
 */
- (BOOL)restoreDbFromBackup:(int)backupId
					  dbDir:(NSString *)dbDir
					 walDir:(NSString *)walDir
			   keepLogFiles:(BOOL)keepLogFiles
					  error:(NSError * _Nullable __autoreleasing *)error;

/**
 Restore the database from the latest backup
 @param dbDir The directory to restore the backup to, i.e. where your database is
 @param walDir The location of the log files for your database, often the same as dbDir
 @param keepLogFiles If true, restore won't overwrite the existing log files in wal_dir.
 It will also move all log files from archive directory to wal_dir. Use this option in combination with
 @param error filled if error was encountered
 */
- (BOOL)restoreDbFromLatestBackup:(NSString *)dbDir
						   walDir:(NSString *)walDir
						keepLogFiles:(BOOL)keepLogFiles
								error:(NSError * _Nullable __autoreleasing *)error;

/**
 @brief Closes this Backup Engine instance.
 */
- (void)close;

@end

NS_ASSUME_NONNULL_END
