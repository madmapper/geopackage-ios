//
//  GPKGGeoPackageOverlay.m
//  geopackage-ios
//
//  Created by Brian Osborn on 7/1/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGGeoPackageOverlay.h"
#import "GPKGTileMatrixSetDao.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGImageConverter.h"

@interface GPKGGeoPackageOverlay ()

@property (nonatomic, strong) GPKGTileDao *tileDao;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) GPKGBoundingBox * setWebMercatorBoundingBox;

@end

@implementation GPKGGeoPackageOverlay

-(instancetype) initWithTileDao: (GPKGTileDao *) tileDao{
    self = [super initWithURLTemplate:nil];
    if(self != nil){
        self.tileDao = tileDao;
        [tileDao adjustTileMatrixLengths];
        
        GPKGTileMatrixSetDao * tileMatrixSetDao = [[GPKGTileMatrixSetDao alloc] initWithDatabase: self.tileDao.database];
        GPKGProjection * projection = [tileMatrixSetDao getProjection:tileDao.tileMatrixSet];
        
        GPKGProjectionTransform * projectionToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
        
        GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
        GPKGBoundingBox * setProjectionBoundingBox = [tileMatrixSet getBoundingBox];
        self.setWebMercatorBoundingBox = [projectionToWebMercator transformWithBoundingBox:setProjectionBoundingBox];
    }
    return self;
}

-(instancetype) initWithTileDao: (GPKGTileDao *) tileDao andWidth: (int) width andHeight: (int) height{
    self = [self initWithTileDao:tileDao];
    if(self != nil){
        self.width = [NSNumber numberWithInt:width];
        self.height = [NSNumber numberWithInt:height];
    }
    return self;
}

-(NSURL *)URLForTilePath:(MKTileOverlayPath)path{
    return [NSURL URLWithString:@""];
}

-(void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *tileData, NSError *error))result{
    
    if(!result){
        return;
    }
    
    NSData * tileData = nil;
    
    // Get the bounding box of the requested tile
    GPKGBoundingBox * webMercatorBoundingBox = [GPKGTileBoundingBoxUtils getWebMercatorBoundingBoxWithX:(int)path.x andY:(int)path.y andZoom:(int)path.z];
    
    // Check if the request overlaps the tile matrix set
    if([GPKGTileBoundingBoxUtils overlapWithBoundingBox:webMercatorBoundingBox andBoundingBox:self.setWebMercatorBoundingBox] != nil){
     
        // Get the tile distance
        double distance = [webMercatorBoundingBox.maxLongitude doubleValue] - [webMercatorBoundingBox.minLongitude doubleValue];
        
        // Get the zoom level to request based upon the tile size
        NSNumber * zoomLevel = [self.tileDao getZoomLevelWithLength:distance];
        
        // If there is a matching zoom level
        if(zoomLevel != nil){
            
            GPKGTileMatrix * tileMatrix = [self.tileDao getTileMatrixWithZoomLevel:[zoomLevel intValue]];
            
            // Get the grid
            GPKGTileGrid * tileGrid = [GPKGTileBoundingBoxUtils getTileGridWithWebMercatorTotalBoundingBox:self.setWebMercatorBoundingBox andMatrixWidth:[tileMatrix.matrixWidth intValue] andMatrixHeight:[tileMatrix.matrixHeight intValue] andWebMercatorBoundingBox:webMercatorBoundingBox];
            
            // Query for matching tiles in the tile grid
            GPKGResultSet * tileResults = [self.tileDao queryByTileGrid:tileGrid andZoomLevel:[zoomLevel intValue]];
            if(tileResults != nil){
                
                @try{
                    
                    if([tileResults count] > 0){
                    
                        // Get the requested tile dimensions
                        int tileWidth = [tileMatrix.tileWidth intValue];
                        int tileHeight = [tileMatrix.tileHeight intValue];
                    
                        // Draw the resulting image with the matching tiles
                        UIGraphicsBeginImageContext(CGSizeMake(tileWidth, tileHeight));
                        CGContextRef context = UIGraphicsGetCurrentContext();
                    
                        while([tileResults moveToNext]){
                        
                            // Get the next tile
                            GPKGTileRow * tileRow = [self.tileDao getTileRow:tileResults];
                            UIImage * tileDataImage = [tileRow getTileDataImage];
                        
                            // Get the bounding box of the tile
                            GPKGBoundingBox * tileWebMercatorBoundingBox = [GPKGTileBoundingBoxUtils getWebMercatorBoundingBoxWithWebMercatorTotalBoundingBox:self.setWebMercatorBoundingBox andTileMatrix:tileMatrix andTileColumn:[tileRow getTileColumn] andTileRow:[tileRow getTileRow]];
                        
                            // Get the bounding box where the requested image and tile overlap
                            GPKGBoundingBox * overlap = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:webMercatorBoundingBox andBoundingBox:tileWebMercatorBoundingBox];
                        
                            // If the tile overlaps with the requested box
                            if(overlap != nil){
                                
                                // TODO figure out the x and y offest
                                CGRect imageRect = CGRectMake(0, 0, tileDataImage.size.width, tileDataImage.size.height);
                                CGContextDrawImage(context, imageRect, tileDataImage.CGImage);
                            }
                        }
                    
                        // Create the tile
                        UIImage *tileImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        if(tileImage != nil){
                            
                            // Scale the image if needed
                            if((self.width != nil && [self.width intValue] != tileWidth) || (self.height != nil && [self.height intValue] != tileHeight)){
                                int scaledTileWidth = self.width != nil ? [self.width intValue] : [tileMatrix.tileWidth intValue];
                                int scaledTileHeight = self.height != nil ? [self.height intValue] : [tileMatrix.tileHeight intValue];
                                CGSize scaledSize = CGSizeMake(scaledTileWidth, scaledTileHeight);
                                UIGraphicsBeginImageContext(scaledSize);
                                [tileImage drawInRect:CGRectMake(0,0,scaledSize.width,scaledSize.height)];
                                tileImage = UIGraphicsGetImageFromCurrentImageContext();
                                UIGraphicsEndImageContext();
                            }
                            
                            tileData = [GPKGImageConverter toData:tileImage andFormat:GPKG_CF_PNG];
                        }
                    }
                    
                }@finally{
                    [tileResults close];
                }
                
            }
        }
    }
    
    result(tileData, nil);
}

@end
