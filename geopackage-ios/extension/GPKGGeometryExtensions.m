//
//  GPKGGeometryExtensions.m
//  geopackage-ios
//
//  Created by Brian Osborn on 6/1/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGGeometryExtensions.h"
#import "SFGeometryTypes.h"
#import "GPKGGeoPackageConstants.h"
#import "GPKGExtensions.h"
#import "GPKGProperties.h"
#import "SFWGeometryCodes.h"

NSString * const GPKG_PROP_GEOMETRY_TYPES_EXTENSION_DEFINITION = @"geopackage.extensions.geometry_types";
NSString * const GPKG_PROP_USER_GEOMETRY_TYPES_EXTENSION_DEFINITION = @"geopackage.extensions.user_geometry_types";

@implementation GPKGGeometryExtensions

-(instancetype) initWithGeoPackage: (GPKGGeoPackage *) geoPackage{
    self = [super initWithGeoPackage:geoPackage];
    if(self != nil){
        self.geometryTypesDefinition = [GPKGProperties getValueOfProperty:GPKG_PROP_GEOMETRY_TYPES_EXTENSION_DEFINITION];
        self.userGeometryTypesDefinition = [GPKGProperties getValueOfProperty:GPKG_PROP_USER_GEOMETRY_TYPES_EXTENSION_DEFINITION];
    }
    return self;
}

-(GPKGExtensions *) getOrCreateWithTable: (NSString *) tableName andColumn: (NSString *) columnName andType: (enum SFGeometryType) geometryType{
    
    NSString * extensionName = [GPKGGeometryExtensions getExtensionName:geometryType];
    GPKGExtensions * extension = [self getOrCreateWithExtensionName:extensionName andTableName:tableName andColumnName:columnName andDefinition:self.geometryTypesDefinition andScope:GPKG_EST_READ_WRITE];
    
    return extension;
}

-(BOOL) hasWithTable: (NSString *) tableName andColumn: (NSString *) columnName andType: (enum SFGeometryType) geometryType{
    
    NSString * extensionName = [GPKGGeometryExtensions getExtensionName:geometryType];
    BOOL exists = [self hasWithExtensionName:extensionName andTableName:tableName andColumnName:columnName];
    
    return exists;
}

+(BOOL) isExtension: (enum SFGeometryType) geometryType{
    return [SFWGeometryCodes codeFromGeometryType:geometryType] > [SFWGeometryCodes codeFromGeometryType:SF_GEOMETRYCOLLECTION];
}

+(BOOL) isNonStandard: (enum SFGeometryType) geometryType{
    return [SFWGeometryCodes codeFromGeometryType:geometryType] > [SFWGeometryCodes codeFromGeometryType:SF_SURFACE];
}

+(BOOL) isGeoPackageExtension: (enum SFGeometryType) geometryType{
    int geometryCode = [SFWGeometryCodes codeFromGeometryType:geometryType];
    return geometryCode >= [SFWGeometryCodes codeFromGeometryType:SF_CIRCULARSTRING] && geometryCode <= [SFWGeometryCodes codeFromGeometryType:SF_SURFACE];
}

+(NSString *) getExtensionName: (enum SFGeometryType) geometryType{
    
    if(![self isExtension:geometryType]){
        [NSException raise:@"Not Extension" format:@"Geometry Type is not an extension: %@", [SFGeometryTypes name:geometryType]];
    }
    
    if(![self isGeoPackageExtension:geometryType]){
        [NSException raise:@"Not GeoPackage Extension" format:@"Geometry Type is not a GeoPackage extension, User-Defined requires an author: %@", [SFGeometryTypes name:geometryType]];
    }
    
    NSString * extensionName = [NSString stringWithFormat:@"%@%@%@%@%@",
                                GPKG_GEO_PACKAGE_EXTENSION_AUTHOR,
                                GPKG_EX_EXTENSION_NAME_DIVIDER,
                                GPKG_GEOMETRY_EXTENSION_PREFIX,
                                GPKG_EX_EXTENSION_NAME_DIVIDER,
                                [SFGeometryTypes name:geometryType]];
    return extensionName;
}

-(GPKGExtensions *) getOrCreateWithTable: (NSString *) tableName andColumn: (NSString *) columnName andAuthor: (NSString *) author andType: (enum SFGeometryType) geometryType{
    
    NSString * extensionName = [GPKGGeometryExtensions getExtensionNameWithAuthor:author andType:geometryType];
    NSString * description = [GPKGGeometryExtensions isGeoPackageExtension:geometryType] ? self.geometryTypesDefinition : self.userGeometryTypesDefinition;
    GPKGExtensions * extension = [self getOrCreateWithExtensionName:extensionName andTableName:tableName andColumnName:columnName andDefinition:description andScope:GPKG_EST_READ_WRITE];
    
    return extension;
}

-(BOOL) hasWithTable: (NSString *) tableName andColumn: (NSString *) columnName andAuthor: (NSString *) author andType: (enum SFGeometryType) geometryType{
    
    NSString * extensionName = [GPKGGeometryExtensions getExtensionNameWithAuthor:author andType:geometryType];
    BOOL exists = [self hasWithExtensionName:extensionName andTableName:tableName andColumnName:columnName];
    
    return exists;
}

+(NSString *) getExtensionNameWithAuthor: (NSString *) author andType: (enum SFGeometryType) geometryType{
    
    if(![self isExtension:geometryType]){
        [NSException raise:@"Not Extension" format:@"Geometry Type is not an extension: %@", [SFGeometryTypes name:geometryType]];
    }
    
    NSString * extensionName = [NSString stringWithFormat:@"%@%@%@%@%@",
                                [self isGeoPackageExtension:geometryType] ? GPKG_GEO_PACKAGE_EXTENSION_AUTHOR : author,
                                GPKG_EX_EXTENSION_NAME_DIVIDER,
                                GPKG_GEOMETRY_EXTENSION_PREFIX,
                                GPKG_EX_EXTENSION_NAME_DIVIDER,
                                [SFGeometryTypes name:geometryType]];
    return extensionName;
}

@end
