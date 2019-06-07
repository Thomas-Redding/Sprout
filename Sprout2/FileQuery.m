//
//  FileQuery.m
//  Sprout2
//
//  Created by Thomas Redding on 6/2/19.
//  Copyright © 2019 Thomas Redding. All rights reserved.
//

#import "FileQuery.h"

static int _nextQueryId;
static NSMutableDictionary<NSString *, FileQuery *> *_idToQuery;

@implementation FileQuery {
  NSMetadataQuery *_metadataSearch;
  NSString *_string;
  NSString *_queryId;
  id _target;
  SEL _callback;
  NSString *_callbackString;
}

+ (void)initialize {
  if (self == [FileQuery self]) {
    _idToQuery = [[NSMutableDictionary alloc] init];
  }
}

+ (void)startQuery:(NSMetadataQuery *)query string:(NSString *)string target:(id)target callback:(SEL)callback {
  
  NSString *queryId = [NSString stringWithFormat:@"%d", _nextQueryId];
  ++_nextQueryId;
  FileQuery *fileQuery = [[FileQuery alloc] initWithQuery:query string:string queryId:queryId target:target callback:callback];
  [_idToQuery setValue:fileQuery forKey:queryId];
}

+ (void)removeMe:(FileQuery *)fileQuery {
  [_idToQuery removeObjectForKey:fileQuery.queryId];
}

- (instancetype)initWithQuery:(NSMetadataQuery *)query string:(NSString *)string queryId:(NSString *)queryId target:(id)target callback:(SEL)callback {
  self = [super init];
  if (self) {
    _metadataSearch = query;
    
    _string = string;
    _queryId = queryId;
    _target = target;
    _callback = callback;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinish:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:_metadataSearch];
    [_metadataSearch startQuery];
  }
  return self;
}

#pragma mark - Private

- (void)didFinish:(id)sender {
  [_metadataSearch stopQuery];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSMetadataQueryDidFinishGatheringNotification
                                                object:_metadataSearch];
  NSMutableArray<NSString *> *results = [[NSMutableArray alloc] init];
  for (NSMetadataItem *item in _metadataSearch.results) {
    [results addObject:[item valueForAttribute:kMDItemPath]];
  }
  [_target performSelector:_callback withObject:results withObject:_string];
  [FileQuery removeMe:self];
}

#pragma mark - File Predicate

+ (NSPredicate *)filePredicateFromString:(NSString *)string {
  return [NSPredicate predicateWithFormat:@""];
}

@end
