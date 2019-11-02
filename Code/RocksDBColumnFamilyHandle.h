//
//  RocksDBColumnFamilyHandle.h
//  ObjectiveRocks
//
//  Created by Jurriaan Mous on 20/10/2019.
//

#import <Foundation/Foundation.h>
#import "RocksDBColumnFamilyDescriptor.h"

#ifndef RocksDBColumnFamilyHandle_h
#define RocksDBColumnFamilyHandle_h

/**
 Options to control the behavior of the DB.
 */
@interface RocksDBColumnFamilyHandle : NSObject

/** @brief Gets the ID of the Column Family. */
@property (nonatomic, readonly) uint32_t id;


/** @brief Gets the name of the Column Family. */
@property (nonatomic, readonly) NSString *name;

/** @brief Closes the handle*/
- (void)close;

@end

#endif /* RocksDBColumnFamilyHandle_h */