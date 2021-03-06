//
//  GPKGRelatedTablesExtension.m
//  geopackage-ios
//
//  Created by Brian Osborn on 6/13/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGRelatedTablesExtension.h"
#import "GPKGProperties.h"
#import "GPKGUserCustomTableReader.h"
#import "GPKGGeoPackageConstants.h"

NSString * const GPKG_EXTENSION_RELATED_TABLES_NAME_NO_AUTHOR = @"related_tables";
NSString * const GPKG_PROP_EXTENSION_RELATED_TABLES_DEFINITION = @"geopackage.extensions.extended_relations";

@interface GPKGRelatedTablesExtension ()

@property (nonatomic, strong) NSString *extensionName;
@property (nonatomic, strong) NSString *extensionDefinition;
@property (nonatomic, strong) GPKGExtendedRelationsDao *extendedRelationsDao;

@end

@implementation GPKGRelatedTablesExtension

-(instancetype) initWithGeoPackage: (GPKGGeoPackage *) geoPackage{
    self = [super initWithGeoPackage:geoPackage];
    if(self != nil){
        // TODO Remove the commented sections when extension is adopted
        self.extensionName = /*[GPKGExtensions buildExtensionNameWithAuthor:GPKG_GEO_PACKAGE_EXTENSION_AUTHOR andExtensionName:*/GPKG_EXTENSION_RELATED_TABLES_NAME_NO_AUTHOR/*]*/;
        self.extensionDefinition = [GPKGProperties getValueOfProperty:GPKG_PROP_EXTENSION_RELATED_TABLES_DEFINITION];
        self.extendedRelationsDao = [geoPackage getExtendedRelationsDao];
    }
    return self;
}

-(GPKGExtendedRelationsDao *) getExtendedRelationsDao{
    return self.extendedRelationsDao;
}

-(NSString *) getExtensionName{
    return self.extensionName;
}

-(NSString *) getExtensionDefinition{
    return self.extensionDefinition;
}

-(GPKGExtensions *) getOrCreateExtension{
    
    // Create table
    [self.geoPackage createExtendedRelationsTable];
    
    GPKGExtensions * extension = [self getOrCreateWithExtensionName:self.extensionName andTableName:GPKG_ER_TABLE_NAME andColumnName:nil andDefinition:self.extensionDefinition andScope:GPKG_EST_READ_WRITE];
    
    return extension;
}

-(GPKGExtensions *) getOrCreateExtensionWithMappingTable: (NSString *) mappingTable{
    
    [self getOrCreateExtension];
    
    GPKGExtensions * extension = [self getOrCreateWithExtensionName:self.extensionName andTableName:mappingTable andColumnName:nil andDefinition:self.extensionDefinition andScope:GPKG_EST_READ_WRITE];
    
    return extension;
}

-(BOOL) has{
    return [self hasWithExtensionName:self.extensionName andTableName:GPKG_ER_TABLE_NAME andColumnName:nil];
}

-(BOOL) hasWithMappingTable: (NSString *) mappingTable{
    return [self has] && [self hasWithExtensionName:self.extensionName andTableName:mappingTable andColumnName:nil];
}


-(NSString *) primaryKeyColumnNameOfTable: (NSString *) tableName{
    GPKGUserCustomTable *table = [GPKGUserCustomTableReader readTableWithConnection:self.geoPackage.database andTableName:tableName];
    GPKGUserColumn *pkColumn = [table getPkColumn];
    if(pkColumn == nil){
        [NSException raise:@"No Primary Key" format:@"Found no primary key for table %@", tableName];
    }
    return pkColumn.name;
}

-(void) setContentsInTable: (GPKGUserRelatedTable *) table{
    GPKGContentsDao *dao = [self.geoPackage getContentsDao];
    GPKGContents *contents = (GPKGContents *)[dao queryForIdObject:table.tableName];
    if(contents == nil){
        [NSException raise:@"No Contents Table" format:@"No Contents Table exists for table name: %@", table.tableName];
    }
    [table setContents:contents];
}

-(NSArray<GPKGExtendedRelation *> *) relationships{
    NSMutableArray<GPKGExtendedRelation *> *relationships = [[NSMutableArray alloc] init];
    if([self.extendedRelationsDao tableExists]){
        GPKGResultSet *resultSet = [self.extendedRelationsDao queryForAll];
        @try {
            while([resultSet moveToNext]){
                [relationships addObject:[self.extendedRelationsDao relation:resultSet]];
            }
        } @finally {
            [resultSet close];
        }
    }
    return relationships;
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andMappingTableName: (NSString *) mappingTableName andRelation: (enum GPKGRelationType) relationType{
    return [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andMappingTableName:mappingTableName andRelationName:[GPKGRelationTypes name:relationType]];
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andMappingTableName: (NSString *) mappingTableName andRelationAuthor: (NSString *) relationAuthor andRelationName: (NSString *) relationName{
    return [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andMappingTableName:mappingTableName andRelationName:[self buildRelationNameWithAuthor:relationAuthor andName:relationName]];
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andMappingTableName: (NSString *) mappingTableName andRelationName: (NSString *) relationName{
    
    GPKGUserMappingTable *userMappingTable = [GPKGUserMappingTable createWithName:mappingTableName];

    GPKGExtendedRelation *extendedRelation = [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andUserMappingTable:userMappingTable andRelationName:relationName];
    
    return extendedRelation;
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andUserMappingTable: (GPKGUserMappingTable *) userMappingTable andRelation: (enum GPKGRelationType) relationType{
    return [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andUserMappingTable:userMappingTable andRelationName:[GPKGRelationTypes name:relationType]];
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andUserMappingTable: (GPKGUserMappingTable *) userMappingTable andRelationAuthor: (NSString *) relationAuthor andRelationName: (NSString *) relationName{
    return [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andUserMappingTable:userMappingTable andRelationName:[self buildRelationNameWithAuthor:relationAuthor andName:relationName]];
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andUserMappingTable: (GPKGUserMappingTable *) userMappingTable andRelationName: (NSString *) relationName{
    
    // Validate the relation
    [self validateRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andRelationName:relationName];
    
    // Create the user mapping table if needed
    [self createUserMappingTable:userMappingTable];
    
    // Add a row to gpkgext_relations
    GPKGExtendedRelation *extendedRelation = [[GPKGExtendedRelation alloc] init];
    [extendedRelation setBaseTableName:baseTableName];
    [extendedRelation setBasePrimaryColumn:[self primaryKeyColumnNameOfTable:baseTableName]];
    [extendedRelation setRelatedTableName:relatedTableName];
    [extendedRelation setRelatedPrimaryColumn:[self primaryKeyColumnNameOfTable:relatedTableName]];
    [extendedRelation setMappingTableName:userMappingTable.tableName];
    [extendedRelation setRelationName:relationName];
    [self.extendedRelationsDao create:extendedRelation];
    
    return extendedRelation;
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andUserRelatedTable: (GPKGUserRelatedTable *) relatedTable andMappingTableName: (NSString *) mappingTableName{
    
    GPKGUserMappingTable *userMappingTable = [GPKGUserMappingTable createWithName:mappingTableName];
    
    return [self addRelationshipWithBaseTable:baseTableName andUserRelatedTable:relatedTable andUserMappingTable:userMappingTable];
}

-(GPKGExtendedRelation *) addRelationshipWithBaseTable: (NSString *) baseTableName andUserRelatedTable: (GPKGUserRelatedTable *) relatedTable andUserMappingTable: (GPKGUserMappingTable *) userMappingTable{
    
    // Create the related table if needed
    [self createRelatedTable:relatedTable];
    
    return [self addRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTable.tableName andUserMappingTable:userMappingTable andRelationName:relatedTable.relationName];
}

-(GPKGExtendedRelation *) addFeaturesRelationshipWithBaseTable: (NSString *) baseFeaturesTableName andRelatedTable: (NSString *) relatedFeaturesTableName andMappingTableName: (NSString *) mappingTableName{
    return [self addRelationshipWithBaseTable:baseFeaturesTableName andRelatedTable:relatedFeaturesTableName andMappingTableName:mappingTableName andRelation:GPKG_RT_FEATURES];
}

-(GPKGExtendedRelation *) addFeaturesRelationshipWithBaseTable: (NSString *) baseFeaturesTableName andRelatedTable: (NSString *) relatedFeaturesTableName andUserMappingTable: (GPKGUserMappingTable *) userMappingTable{
        return [self addRelationshipWithBaseTable:baseFeaturesTableName andRelatedTable:relatedFeaturesTableName andUserMappingTable:userMappingTable andRelation:GPKG_RT_FEATURES];
}

-(GPKGExtendedRelation *) addMediaRelationshipWithBaseTable: (NSString *) baseTableName andMediaTable: (GPKGMediaTable *) mediaTable andMappingTableName: (NSString *) mappingTableName{
    return [self addRelationshipWithBaseTable:baseTableName andUserRelatedTable:mediaTable andMappingTableName:mappingTableName];
}

-(GPKGExtendedRelation *) addMediaRelationshipWithBaseTable: (NSString *) baseTableName andMediaTable: (GPKGMediaTable *) mediaTable andUserMappingTable: (GPKGUserMappingTable *) userMappingTable{
    return [self addRelationshipWithBaseTable:baseTableName andUserRelatedTable:mediaTable andUserMappingTable:userMappingTable];
}

-(GPKGExtendedRelation *) addSimpleAttributesRelationshipWithBaseTable: (NSString *) baseTableName andSimpleAttributesTable: (GPKGSimpleAttributesTable *) simpleAttributesTable andMappingTableName: (NSString *) mappingTableName{
    return [self addRelationshipWithBaseTable:baseTableName andUserRelatedTable:simpleAttributesTable andMappingTableName:mappingTableName];
}

-(GPKGExtendedRelation *) addSimpleAttributesRelationshipWithBaseTable: (NSString *) baseTableName andSimpleAttributesTable: (GPKGSimpleAttributesTable *) simpleAttributesTable  andUserMappingTable: (GPKGUserMappingTable *) userMappingTable{
    return [self addRelationshipWithBaseTable:baseTableName andUserRelatedTable:simpleAttributesTable andUserMappingTable:userMappingTable];
}

/**
 * Validate that the relation name is valid between the base and related
 * table
 *
 * @param baseTableName
 *            base table name
 * @param relatedTableName
 *            related table name
 * @param relationName
 *            relation name
 */
-(void) validateRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andRelationName: (NSString *) relationName{
    
    // Verify the base and related tables exist
    if(![self.geoPackage isTable:baseTableName]){
        [NSException raise:@"Base Table" format:@"Base Relationship table does not exist: %@, Relation: %@", baseTableName, relationName];
    }
     if(![self.geoPackage isTable:relatedTableName]){
        [NSException raise:@"Related Table" format:@"Related Relationship table does not exist: %@, Relation: %@", relatedTableName, relationName];
    }
    
    // Verify spec defined relation types
    enum GPKGRelationType relationType = [GPKGRelationTypes fromName:relationName];
    if ((int)relationType >= 0) {
        [self validateRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andRelation:relationType];
    }
    
}

/**
 * Determine if the relation type is valid between the base and related
 * table
 *
 * @param baseTableName
 *            base table name
 * @param relatedTableName
 *            related table name
 * @param relationType
 *            relation type
 */
-(void) validateRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andRelation: (enum GPKGRelationType) relationType{
    
    if ((int)relationType >= 0) {
        
        switch (relationType) {
            case GPKG_RT_FEATURES:
                {
                    if(![self.geoPackage isFeatureTable:baseTableName]){
                        [NSException raise:@"Base Table" format:@"The base table must be a feature table. Relation: %@, Base Table: %@, Type: %@", [GPKGRelationTypes name:relationType], baseTableName, [self.geoPackage typeOfTable:baseTableName]];
                    }
                    if(![self.geoPackage isFeatureTable:relatedTableName]){
                        [NSException raise:@"Related Table" format:@"The related table must be a feature table. Relation: %@, Related Table: %@, Type: %@", [GPKGRelationTypes name:relationType], relatedTableName, [self.geoPackage typeOfTable:relatedTableName]];
                    }
                }
                break;
            case GPKG_RT_SIMPLE_ATTRIBUTES:
            case GPKG_RT_MEDIA:
                {
                    if(![self.geoPackage isTable:relatedTableName ofTypeName:[GPKGRelationTypes name:relationType]]){
                        [NSException raise:@"Related Table" format:@"The related table must be a %@ table. Related Table: %@, Type: %@", [GPKGRelationTypes name:relationType], relatedTableName, [self.geoPackage typeOfTable:relatedTableName]];
                    }
                }
                break;
            default:
                [NSException raise:@"Unsupported Relation" format:@"Unsupported relation type: %@", [GPKGRelationTypes name:relationType]];
        }
        
    }
    
}

-(BOOL) createUserMappingTableWithName: (NSString *) mappingTableName{
    
    GPKGUserMappingTable *userMappingTable = [GPKGUserMappingTable createWithName:mappingTableName];

    return [self createUserMappingTable:userMappingTable];
}

-(BOOL) createUserMappingTable: (GPKGUserMappingTable *) userMappingTable{
    
    BOOL created = NO;
    
    NSString *userMappingTableName = userMappingTable.tableName;
    [self getOrCreateExtensionWithMappingTable:userMappingTableName];
    
    if(![self.geoPackage isTable:userMappingTableName]){
        
        [self.geoPackage createUserTable:userMappingTable];
        
        created = YES;
    }
    
    return created;
}

-(BOOL) createRelatedTable: (GPKGUserRelatedTable *) relatedTable{
    
    BOOL created = NO;
    
    NSString *relatedTableName = relatedTable.tableName;
    if(![self.geoPackage isTable:relatedTableName]){
        
        [self.geoPackage createUserTable:relatedTable];
        
        // Create the contents
        GPKGContents *contents = [[GPKGContents alloc] init];
        [contents setTableName:relatedTableName];
        [contents setDataType:[relatedTable relationName]];
        [contents setIdentifier:relatedTableName];
        GPKGContentsDao *contentsDao = [self.geoPackage getContentsDao];
        [contentsDao create:contents];
        contents = (GPKGContents *)[contentsDao queryForIdObject:relatedTableName];
        
        [relatedTable setContents:contents];
        
        created = YES;
    }
    
    return created;
}

-(void) removeRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andRelation: (enum GPKGRelationType) relationType{
    [self removeRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andRelationName:[GPKGRelationTypes name:relationType]];
}

-(void) removeRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andRelationAuthor: (NSString *) relationAuthor andRelationName: (NSString *) relationName{
    [self removeRelationshipWithBaseTable:baseTableName andRelatedTable:relatedTableName andRelationName:[self buildRelationNameWithAuthor:relationAuthor andName:relationName]];
}

-(void) removeRelationship: (GPKGExtendedRelation *) extendedRelation{
        [self removeRelationshipWithBaseTable:extendedRelation.baseTableName andRelatedTable:extendedRelation.relatedTableName andRelationName:extendedRelation.relationName];
}

-(void) removeRelationshipWithBaseTable: (NSString *) baseTableName andRelatedTable: (NSString *) relatedTableName andRelationName: (NSString *) relationName{
    
    if([self.extendedRelationsDao tableExists]){
        GPKGColumnValues *whereValues = [[GPKGColumnValues alloc] init];
        [whereValues addColumn:GPKG_ER_COLUMN_BASE_TABLE_NAME withValue:baseTableName];
        [whereValues addColumn:GPKG_ER_COLUMN_RELATED_TABLE_NAME withValue:relatedTableName];
        [whereValues addColumn:GPKG_ER_COLUMN_RELATION_NAME withValue:relationName];
        NSString *where = [self.extendedRelationsDao buildWhereWithFields:whereValues];
        NSArray *whereArgs = [self.extendedRelationsDao buildWhereArgsWithValues:whereValues];
        NSMutableArray<GPKGExtendedRelation *> *extendedRelations = [[NSMutableArray alloc] init];
        GPKGResultSet *extendedRelationsResultSet = [self.extendedRelationsDao queryWhere:where andWhereArgs:whereArgs];
        @try {
            while([extendedRelationsResultSet moveToNext]){
                [extendedRelations addObject:[self.extendedRelationsDao relation:extendedRelationsResultSet]];
            }
        } @finally {
            [extendedRelationsResultSet close];
        }
        for(GPKGExtendedRelation *extendedRelation in extendedRelations){
            [self.geoPackage deleteUserTable:extendedRelation.mappingTableName];
        }
        [self.extendedRelationsDao deleteWhere:where andWhereArgs:whereArgs];
    }
    
}

-(void) removeExtension{
    
    if([self.extendedRelationsDao tableExists]){
        GPKGResultSet *extendedRelations = [self.extendedRelationsDao queryForAll];
        @try {
            while([extendedRelations moveToNext]){
                GPKGExtendedRelation *extendedRelation = [self.extendedRelationsDao relation:extendedRelations];
                [self.geoPackage deleteUserTable:extendedRelation.mappingTableName];
            }
            [self.extendedRelationsDao dropTable];
        } @finally {
            [extendedRelations close];
        }
    }
    if([self.extensionsDao tableExists]){
        [self.extensionsDao deleteByExtension:self.extensionName];
    }

}

-(NSString *) buildRelationNameWithAuthor: (NSString *) author andName: (NSString *) name{
    return [NSString stringWithFormat:@"x-%@_%@", author, name];
}

-(GPKGUserCustomDao *) userDaoForTableName: (NSString *) tableName{
    return [GPKGUserCustomDao readTableWithDatabase:self.geoPackage.name andConnection:self.geoPackage.database andTable:tableName];
}

-(GPKGUserMappingDao *) mappingDaoForRelation: (GPKGExtendedRelation *) extendedRelation{
    return [self mappingDaoForTableName:extendedRelation.mappingTableName];
}

-(GPKGUserMappingDao *) mappingDaoForTableName: (NSString *) tableName{
    return [[GPKGUserMappingDao alloc] initWithDao:[self userDaoForTableName:tableName]];
}

-(GPKGMediaDao *) mediaDaoForTable: (GPKGMediaTable *) mediaTable{
    return [self mediaDaoForTableName:mediaTable.tableName];
}

-(GPKGMediaDao *) mediaDaoForRelation: (GPKGExtendedRelation *) extendedRelation{
    return [self mediaDaoForTableName:extendedRelation.relatedTableName];
}

-(GPKGMediaDao *) mediaDaoForTableName: (NSString *) tableName{
    GPKGMediaDao *mediaDao = [[GPKGMediaDao alloc] initWithDao:[self userDaoForTableName:tableName]];
    [self setContentsInTable:[mediaDao table]];
    return mediaDao;
}

-(GPKGSimpleAttributesDao *) simpleAttributesDaoForTable: (GPKGSimpleAttributesTable *) simpleAttributesTable{
    return [self simpleAttributesDaoForTableName:simpleAttributesTable.tableName];
}

-(GPKGSimpleAttributesDao *) simpleAttributesDaoForRelation: (GPKGExtendedRelation *) extendedRelation{
    return [self simpleAttributesDaoForTableName:extendedRelation.relatedTableName];
}

-(GPKGSimpleAttributesDao *) simpleAttributesDaoForTableName: (NSString *) tableName{
    GPKGSimpleAttributesDao *simpleAttributesDao = [[GPKGSimpleAttributesDao alloc] initWithDao:[self userDaoForTableName:tableName]];
    [self setContentsInTable:[simpleAttributesDao table]];
    return simpleAttributesDao;
}

-(NSArray<NSNumber *> *) mappingsForRelation: (GPKGExtendedRelation *) extendedRelation withBaseId: (int) baseId{
    return [self mappingsForTableName:extendedRelation.mappingTableName withBaseId:baseId];
}

-(NSArray<NSNumber *> *) mappingsForTableName: (NSString *) tableName withBaseId: (int) baseId{
    
    NSMutableArray<NSNumber *> *relatedIds = [[NSMutableArray alloc] init];
    
    GPKGUserMappingDao *userMappingDao = [self mappingDaoForTableName:tableName];
    GPKGResultSet *resultSet = [userMappingDao queryByBaseId:baseId];
    @try{
        while([resultSet moveToNext]){
            GPKGUserMappingRow *row = [userMappingDao row:resultSet];
            [relatedIds addObject:[NSNumber numberWithInt:[row relatedId]]];
        }
    }@finally{
        [resultSet close];
    }
    
    return relatedIds;
}

-(NSArray<NSNumber *> *) mappingsForRelation: (GPKGExtendedRelation *) extendedRelation withRelatedId: (int) relatedId{
    return [self mappingsForTableName:extendedRelation.mappingTableName withRelatedId:relatedId];
}

-(NSArray<NSNumber *> *) mappingsForTableName: (NSString *) tableName withRelatedId: (int) relatedId{
    
    NSMutableArray<NSNumber *> *baseIds = [[NSMutableArray alloc] init];
    
    GPKGUserMappingDao *userMappingDao = [self mappingDaoForTableName:tableName];
    GPKGResultSet *resultSet = [userMappingDao queryByRelatedId:relatedId];
    @try{
        while([resultSet moveToNext]){
            GPKGUserMappingRow *row = [userMappingDao row:resultSet];
            [baseIds addObject:[NSNumber numberWithInt:[row baseId]]];
        }
    }@finally{
        [resultSet close];
    }
    
    return baseIds;
}

@end
