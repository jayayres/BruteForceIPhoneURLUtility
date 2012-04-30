// From: http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
#import <Foundation/Foundation.h>
@interface NSData (DDData)

// gzip compression utilities
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
