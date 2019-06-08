
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
 @param filter A "MetadataQueryString" as is used in the `mdfind` command. [1]
 @param scopes A list of file directories.
 @param sortDescriptors A list of NSSortDescriptors indicating the order of the results.
 @param maxResults The maximinum number of results to return.
 @param string An arbitrary string.
 @param target The target of the callback.
 @param callback A method that takes two parameters: NSArray<NSString *> and NSString *. These
 correspond to the query results and the `string` parameter, respectively.
 
 Example Usage: Find all folders in the Downloads folder in alphabetical order.
 [FileQuery findFilesMatchingFilter:@"kMDItemContentType == public.folder"
                           inScopes:@[ @"/Users/thomasredding/Downloads" ]
                             sortBy:@[ [NSSortDescriptor sortDescriptorWithKey:@"kMDItemFSName" ascending:YES] ]
                         maxResults:NSUIntegerMax
                             string:@"12"
                             target:self
                           callback:@selector(fileSearchFinishedWithResults:string:)];
 
 [1] Discussion of `filter`
 TODO: url
 Useful Keys
 
 string kMDItemFSName The name of the item
 kMDItemFSNodeCount The number of items in the folder
 date   kMDItemFSCreationDate
 date   kMDItemFSContentChangeDate
 date   kMDItemLastUsedDate
 date   kMDItemDateAdded
 int    kMDItemFSSize          The size of the file in bytes
 float  kMDItemDurationSeconds Duration of the audio/video file in seconds.
 int    kMDItemPixelWidth      Width of the image/video file in pixels
 int    kMDItemPixelHeight     Height of the image/video file in pixels
 int    kMDItemPixelCount      Number of pixels in the image/video file
 bool   kMDItemStreamable      Whether the audio/video file can be streamed/
 bool   kMDItemFSInvisible     Whether the item is visible
 string kMDItemKind            A string describing the kind of data contained by the item.
 string kMDItemContentType     A string describing the kind of data contained by the item.
 ???    kMDItemPath            ???
 Example: kMDItemKind vs kMDItemContentType
 kMDItemKind                   kMDItemContentType
   Folder                     public.folder
   JPEG image                 public.jpeg
   PNG image                  public.png
   Apple MPEG-4 movie         public.mpeg-4
   MPEG-4 movie               com.apple.m4v-video
   JSON Document              public.json
   Microsoft Word Document    org.openxmlformats.wordprocessingml.document
 */
+ (void)findFilesMatchingFilter:(NSString *)filter
                       inScopes:(NSArray<NSString *> *)scopes
                         sortBy:(NSArray<NSSortDescriptor *> *)sortDescriptors
                     maxResults:(NSUInteger)maxResults
                         string:(NSString *)string
                         target:(id)target
                       callback:(SEL)callback;

 @end

 NS_ASSUME_NONNULL_END
 
