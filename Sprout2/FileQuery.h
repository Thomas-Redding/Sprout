//
//  FileQuery.h
//  Sprout2
//
//  Created by Thomas Redding on 6/2/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileQuery : NSObject
@property(nonatomic, readonly) NSString *queryId;
/**
 @param query The query to start. Do not modify the query after this point.
 @param string An arbitrary string.
 @param target The target of the callback.
 @param callback A method that takes two parameters: NSArray<NSString *> and NSString *. These
 correspond to the query results and the `string` parameter, respectively.
 */
+ (void)startQuery:(NSMetadataQuery *)query string:(NSString *)string target:(id)target callback:(SEL)callback;

/**
 changed   kMDItemAttributeChangeDate
 created   kMDItemContentCreationDate
 modified  kMDItemContentModificationDate
 type      kMDItemContentType
 duration  kMDItemDurationSeconds
 opened    kMDItemLastUsedDate
 Operators:
   <, <=, =, >=, =, !=
   audienceList,
   changeDate
 (= dateChanged 2018-05-03)
 (contains)
 */
+ (NSPredicate *)filePredicateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
