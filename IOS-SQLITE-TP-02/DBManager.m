//
//  DBManager.m
//  IOS-SQLITE-TP-02
//
//  Created by local192 on 17/01/2018.
//  Copyright © 2018 local192. All rights reserved.
//

#import "DBManager.h"

@implementation DBManager

- (instancetype) initWithDatabaseFilename:(NSString *)dbFilename {
    self = [super init];
    if (self) {
        NSArray *dirPaths;
        
        // Get the documents directory
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        _databasePath = dirPaths[0];
        _databaseName = dbFilename;
        
        [self copyDatabaseIntoDocumentDirectory];
    }
    return self;
}

- (void) copyDatabaseIntoDocumentDirectory {
    NSString *destionationPath = [self.databasePath stringByAppendingPathComponent:self.databaseName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destionationPath]) {
        NSString *sourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:_databaseName];
        
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destionationPath error:&error];
        
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }
}

- (void) runQuery:(const char *)query isQueryExecutable:(BOOL)queryExecutable {
    sqlite3 *sqlite3Database;
    
    NSString *databasePath = [self.databasePath stringByAppendingPathComponent:self.databaseName];
    
    if (self.arrResults != nil) {
        [self.arrResults removeAllObjects];
        self.arrResults = nil;
    }
    self.arrResults = [[NSMutableArray alloc] init];
    
    if (self.arrColumnNames != nil) {
        [self.arrColumnNames removeAllObjects];
        self.arrColumnNames = nil;
    }
    self.arrColumnNames = [[NSMutableArray alloc] init];
    
    BOOL openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
    
    if (openDatabaseResult == SQLITE_OK) {
        sqlite3_stmt *compiledStatement;
        
        BOOL prepareStatementResult = sqlite3_prepare_v2(sqlite3Database, query, -1, &compiledStatement, NULL);
        if (prepareStatementResult == SQLITE_OK) {
            if (!queryExecutable) {
                NSMutableArray *arrDataRow;
                
                while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
                    arrDataRow = [[NSMutableArray alloc] init];
                    
                    int totalColumns = sqlite3_column_count(compiledStatement);
                    
                    for (int i = 0; i < totalColumns; i++) {
                        char *dbDataAsChars = (char *) sqlite3_column_text(compiledStatement, i);
                        
                        if (dbDataAsChars != NULL) {
                            [arrDataRow addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }
                        
                        if (self.arrColumnNames.count != totalColumns) {
                            dbDataAsChars = (char *) sqlite3_column_name(compiledStatement, i);
                            [self.arrColumnNames addObject:[NSString stringWithUTF8String:dbDataAsChars]];
                        }
                    }
                    
                    if (arrDataRow.count > 0) {
                        [self.arrResults addObject:arrDataRow];
                    }
                }
            } else {
                int executeQueryResults = sqlite3_step(compiledStatement);
                if (executeQueryResults == SQLITE_DONE) {
                    self.affectedRows = sqlite3_changes(sqlite3Database);
                    
                    self.lastInsertedRowID = sqlite3_last_insert_rowid(sqlite3Database);
                } else {
                    NSLog(@"DB Error: %s", sqlite3_errmsg(sqlite3Database));
                }
            }
        } else {
            NSLog(@"%s", sqlite3_errmsg(sqlite3Database));
        }
        
        sqlite3_finalize(compiledStatement);
    }
    
    sqlite3_close(sqlite3Database);
}

- (NSArray *) loadDataFromDB:(NSString *)query {
    [self runQuery:[query UTF8String] isQueryExecutable:NO];
    
    return (NSArray *) self.arrResults;
}

- (void) executeQuery:(NSString *)query {
    [self runQuery:[query UTF8String] isQueryExecutable:YES];
}

@end
