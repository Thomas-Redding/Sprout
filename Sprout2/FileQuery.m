
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
  NSUInteger _maxResults;
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

+ (void)findFilesMatchingFilter:(NSString *)filter
                       inScopes:(NSArray<NSString *> *)scopes
                         sortBy:(__unused NSArray<NSSortDescriptor *> *)sortDescriptors
                     maxResults:(NSUInteger)maxResults
                         string:(NSString *)string
                         target:(id)target
                       callback:(SEL)callback {
  NSString *queryId = [NSString stringWithFormat:@"%d", _nextQueryId];
  NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
  query.predicate = [NSPredicate predicateFromMetadataQueryString:filter];
  query.searchScopes = scopes;
  query.sortDescriptors = sortDescriptors;
  ++_nextQueryId;
  FileQuery *fileQuery = [[FileQuery alloc] initWithQuery:query maxResults:maxResults string:string queryId:queryId target:target callback:callback];
  [_idToQuery setValue:fileQuery forKey:queryId];
}

+ (void)removeMe:(FileQuery *)fileQuery {
  [_idToQuery removeObjectForKey:fileQuery.queryId];
}

- (instancetype)initWithQuery:(NSMetadataQuery *)query
                   maxResults:(NSUInteger)maxResults
                       string:(NSString *)string
                      queryId:(NSString *)queryId
                       target:(id)target
                     callback:(SEL)callback {
  self = [super init];
  if (self) {
    _metadataSearch = query;
    
    _string = string;
    _queryId = queryId;
    _target = target;
    _callback = callback;
    _maxResults = maxResults;
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
  int i = 0;
  for (NSMetadataItem *item in _metadataSearch.results) {
    [results addObject:[item valueForAttribute:(NSString *)kMDItemPath]];
    ++i;
    if (i >= _maxResults) break;
  }
  [_target performSelector:_callback withObject:results withObject:_string];
  [FileQuery removeMe:self];
}

@end
