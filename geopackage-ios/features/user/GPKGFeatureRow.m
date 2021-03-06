//
//  GPKGFeatureRow.m
//  geopackage-ios
//
//  Created by Brian Osborn on 5/26/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGFeatureRow.h"

@implementation GPKGFeatureRow

-(instancetype) initWithFeatureTable: (GPKGFeatureTable *) table andColumnTypes: (NSArray *) columnTypes andValues: (NSMutableArray *) values{
    self = [super initWithTable:table andColumnTypes:columnTypes andValues:values];
    if(self != nil){
        self.featureTable = table;
    }
    return self;
}

-(instancetype) initWithFeatureTable: (GPKGFeatureTable *) table{
    self = [super initWithTable:table];
    if(self != nil){
        self.featureTable = table;
    }
    return self;
}

-(int) getGeometryColumnIndex{
    return self.featureTable.geometryIndex;
}

-(GPKGFeatureColumn *) getGeometryColumn{
    return [self.featureTable getGeometryColumn];
}

-(void) setValueWithIndex:(int)index andValue:(NSObject *)value{
    if(index == [self getGeometryColumnIndex] && [value isKindOfClass:[NSData class]]){
        NSData * data = (NSData *) value;
        value = [[GPKGGeometryData alloc] initWithData:data];
    }
    [super setValueWithIndex:index andValue:value];
}

-(GPKGGeometryData *) getGeometry{
    GPKGGeometryData * geometryData = nil;
    NSObject * value = [self getValueWithIndex:self.featureTable.geometryIndex];
    if(value != nil){
        geometryData = (GPKGGeometryData *) value;
    }
    return geometryData;
}

-(void) setGeometry: (GPKGGeometryData *) geometryData{
    [self setValueWithIndex:self.featureTable.geometryIndex andValue:geometryData];
}

-(NSObject *) toObjectValueWithIndex: (int) index andValue: (NSObject *) value{
    
    NSObject * objectValue = value;
    
    GPKGFeatureColumn * column = (GPKGFeatureColumn *)[self getColumnWithIndex:index];
    if([column isGeometry] && ![value isKindOfClass:[GPKGGeometryData class]]){
        
        if([value isKindOfClass:[NSData class]]){
            objectValue = [[GPKGGeometryData alloc] initWithData:(NSData *) value];
        } else{
            [NSException raise:@"Unsupported Geometry Value" format:@"Unsupported geometry column value type. column %@, value type: %@", column.name, NSStringFromClass([value class])];
        }
    }
    
    return objectValue;
}

-(NSObject *) toDatabaseValueWithIndex: (int) index andValue: (NSObject *) value{

    NSObject * dbValue = value;
    
    GPKGFeatureColumn * column = (GPKGFeatureColumn *)[self getColumnWithIndex:index];
    if([column isGeometry] && ![value isKindOfClass:[NSData class]]){
        
        if([value isKindOfClass:[GPKGGeometryData class]]){
            GPKGGeometryData * geometryData = (GPKGGeometryData *) value;
            dbValue = [geometryData toData];
        } else{
            [NSException raise:@"Unsupported Geometry Value" format:@"Unsupported geometry column value type. column %@, value type: %@", column.name, NSStringFromClass([value class])];
        }
    }
    
    return dbValue;
}

-(NSObject *) copyValue: (NSObject *) value forColumn: (GPKGUserColumn *) column{
    
    NSObject *copyValue = nil;
    
    GPKGFeatureColumn * featureColumn = (GPKGFeatureColumn *) column;
    if([featureColumn isGeometry] && ![value isKindOfClass:[GPKGGeometryData class]]){
     
        if([value isKindOfClass:[GPKGGeometryData class]]){
            GPKGGeometryData *geometryData = (GPKGGeometryData *) value;
            @try {
                NSData *data = [geometryData toData];
                NSData *copyData = [data mutableCopy];
                copyValue = [[GPKGGeometryData alloc] initWithData:copyData];
            } @catch (NSException *e) {
                NSLog(@"Failed to copy Geometry Data. column: %@, error: %@", column.name, [e description]);
            }
        }else{
            copyValue = [super copyValue:value forColumn:column];
        }
        
    }else{
        copyValue = [super copyValue:value forColumn:column];
    }
    
    return copyValue;
}

-(id) mutableCopyWithZone: (NSZone *) zone{
    GPKGFeatureRow *featureRow = [super mutableCopyWithZone:zone];
    featureRow.featureTable = _featureTable;
    return featureRow;
}

@end
