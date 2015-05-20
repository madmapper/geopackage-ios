//
//  GPKGConnection.m
//  geopackage-ios
//
//  Created by Brian Osborn on 5/7/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGConnection.h"
#import <sqlite3.h>
#import "GPKGSqlUtils.h"
#import "GPKGGeoPackageConstants.h"

@interface GPKGConnection()

@property (nonatomic) sqlite3 *database;

@end

@implementation GPKGConnection

-(instancetype)initWithDatabaseFilename:(NSString *) filename{
    self = [super init];
    if(self){
        self.filename = filename;
        self.name = [[filename lastPathComponent] stringByDeletingPathExtension];
        
        // Open the database.
        NSString *databasePath  = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.filename];
        sqlite3 *sqlite3Database;
        int openDatabaseResult = sqlite3_open([databasePath UTF8String], &sqlite3Database);
        if(openDatabaseResult != SQLITE_OK){
            [NSException raise:@"Open Database Failure" format:@"Failed to open database: %@, Error: %s", databasePath, sqlite3_errmsg(sqlite3Database)];
        }else{
            self.database = sqlite3Database;
        }
    }

    return self;
}

-(void)close{
    [GPKGSqlUtils closeDatabase:self.database];
}

-(GPKGResultSet *) rawQuery:(NSString *) statement{
    return [GPKGSqlUtils queryWithDatabase:self.database andStatement:statement];
}

-(GPKGResultSet *) queryWithTable: (NSString *) table
                  andColumns: (NSArray *) columns
                    andWhere: (NSString *) where
                  andGroupBy: (NSString *) groupBy
                   andHaving: (NSString *) having
                  andOrderBy: (NSString *) orderBy{
    return [self queryWithTable:table
                     andColumns:columns
                     andWhere:where
                     andGroupBy:groupBy
                     andHaving:having
                     andOrderBy:orderBy
                     andLimit:nil];
}

-(GPKGResultSet *) queryWithTable: (NSString *) table
                          andColumns: (NSArray *) columns
                            andWhere: (NSString *) where
                          andGroupBy: (NSString *) groupBy
                           andHaving: (NSString *) having
                          andOrderBy: (NSString *) orderBy
                            andLimit: (NSString *) limit{
    return [GPKGSqlUtils queryWithDatabase:self.database
                               andDistinct:false andTable:table
                               andColumns:columns
                               andWhere:where
                               andGroupBy:groupBy
                               andHaving:having
                               andOrderBy:orderBy
                               andLimit:limit];
}

-(int) count:(NSString *) statement{
    return [GPKGSqlUtils countWithDatabase:self.database andStatement:statement];
}

-(int) countWithTable: (NSString *) table andWhere: (NSString *) where{
    return [GPKGSqlUtils countWithDatabase:self.database andTable:table andWhere:where];
}

-(long long) insert:(NSString *) statement{
    return [GPKGSqlUtils insertWithDatabase:self.database andStatement:statement];
}

-(int) update:(NSString *) statement{
    return [GPKGSqlUtils updateWithDatabase:self.database andStatement:statement];
}

-(int) updateWithTable: (NSString *) table andValues: (NSDictionary *) values andWhere: (NSString *) where{
    return [GPKGSqlUtils updateWithDatabase:self.database andTable:table andValues:values andWhere:where];
}

-(long long) insertWithTable: (NSString *) table andValues: (NSDictionary *) values{
    return [GPKGSqlUtils insertWithDatabase:self.database andTable:table andValues:values];
}

-(int) delete:(NSString *) statement{
    return [GPKGSqlUtils deleteWithDatabase:self.database andStatement:statement];
}

-(int) deleteWithTable: (NSString *) table andWhere: (NSString *) where{
    return [GPKGSqlUtils deleteWithDatabase:self.database andTable:table andWhere:where];
}

-(void) exec:(NSString *) statement{
    [GPKGSqlUtils execWithDatabase:self.database andStatement:statement];
}

-(BOOL) tableExists: (NSString *) table{
    int count = [self countWithTable:@"sqlite_master" andWhere:[NSString stringWithFormat:@"type ='table' and name = '%@'", table]];
    BOOL found = count > 0;
    return found;
}

-(void) setApplicationId{
    NSData *bytes = [GPKG_APPLICATION_ID dataUsingEncoding:NSUTF8StringEncoding];
    int applicationId = CFSwapInt32BigToHost(*(int*)([bytes bytes]));
    [self exec:[NSString stringWithFormat:@"PRAGMA application_id = %d", applicationId]];
}

-(void) dropTable: (NSString *) table{
    [self exec:[NSString stringWithFormat:@"drop table if exists %@", table]];
}

@end