//
//  ViewController.m
//  BruteForceCanOpenURL
//
//  Created by Jay Ayres on 3/13/12.
//  Copyright (c) 2012 Jay Ayres. All rights reserved.
//

/*
 Copyright 2012 Jay Ayres
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ViewController.h"
#import "Constants.h"
#import "NSDataAdditions.h"

@implementation ViewController

@synthesize candidates, web;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.candidates = nil;
    [web loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] 
                                                                          pathForResource:@"web" ofType:@"html"]]]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.candidates = nil;
    self.web = nil;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (candidates != nil)
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (USE_COMPRESSION)
    {
        [self performSelectorInBackground:@selector(startAnalyzingCompressedBFS) withObject:nil];    
    }
    else 
    {
        [self performSelectorInBackground:@selector(startAnalyzingSimpleBFS) withObject:nil]; 
    }
}

- (void)addScheme:(NSString*)scheme
{
    NSString* js = [NSString stringWithFormat:@"addScheme('%@');", scheme];
    [web stringByEvaluatingJavaScriptFromString:js];
}

- (void)setNumProcessed:(NSString*)proc
{
    NSString* js = [NSString stringWithFormat:@"setNumProcessed(%@);", proc];
    [web stringByEvaluatingJavaScriptFromString:js];    
}

/**
 * Does a simple breadth-first-search of URL candidates,
 * entirely in memory. Runs out of memory fairly quickly.
 **/
- (void)startAnalyzingSimpleBFS
{
    NSLog(@"Analysis started");
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:10000];
    self.candidates = arr;
    [arr release];
    
    for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
    {
        [candidates insertObject:[[NSString alloc] initWithFormat:@"%c", c] atIndex:0];
    }
    
    UIApplication* app = [UIApplication sharedApplication];
    long long ct=0;
    while ([candidates count] > 0)
    {
        NSString*next = [candidates lastObject];
        NSString*nextUrlStr = [[NSString alloc] initWithFormat:@"%@://test", next];
        NSURL* testURL = [[NSURL alloc] initWithString:nextUrlStr];
        if ([app canOpenURL:testURL])
        {
            NSLog(@"%@://", next);
            [self performSelectorOnMainThread:@selector(addScheme:) withObject:next waitUntilDone:YES];
        }
        [testURL release];
        [nextUrlStr release];
        [candidates removeLastObject];
        if ([next length] < MAX_LENGTH_TO_CHECK)
        {
            for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
            {
                [candidates insertObject:[[NSString alloc] initWithFormat:@"%@%c", next, c] atIndex:0];
            }            
        }
        [next release];
        ct++;
        
        if (ct % PROGRESS_UPDATE_INTERVAL == 0)
        {
            NSString* fmtStr = [[NSString alloc] initWithFormat:@"%lld", ct];
            NSLog(@"Processed %@", fmtStr);
            [self performSelectorOnMainThread:@selector(setNumProcessed:) withObject:fmtStr waitUntilDone:YES];
            [fmtStr release];
        }
    }    
}

/**
 * Also does a breadth-first-search of URL candidates, but
 * new nodes added to the tree are concatenated together as
 * strings and then compressed with gzip, lessening the
 * memory footprint as the tree grows larger.
 **/
- (void)startAnalyzingCompressedBFS
{
    NSLog(@"Analysis started CompressedBFS");
    NSString* splitChar = @"_";
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:10000];
    self.candidates = arr;
    [arr release];
    
    NSMutableString* add1Str = [[NSMutableString alloc] initWithCapacity:26];
    for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
    {
        if (c < ASCII_CODE_UPPER)
        {
            [add1Str appendFormat:@"%c_", c];
        }
        else 
        {
            [add1Str appendFormat:@"%c", c];
        }
    }    
    NSData* data1=[[add1Str dataUsingEncoding:NSUTF8StringEncoding] gzipDeflate];
    [candidates insertObject:data1 atIndex:0];
    
    UIApplication* app = [UIApplication sharedApplication];
    long long ct=0;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    while ([candidates count] > 0)
    {
        NSData*nextData = [candidates lastObject];
        NSData*ucNextData = [nextData gzipInflate];
        NSString*next = [[NSString alloc] initWithData:ucNextData encoding:NSUTF8StringEncoding];
             
        NSMutableString* addStr = [[NSMutableString alloc] initWithCapacity:2400000];
        NSUInteger aIdx = 0;
        for (NSString* nextCmp in [next componentsSeparatedByString:splitChar])
        {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            
            if ([nextCmp length] == 0)
            {
                aIdx++;
                [pool drain];
                continue;
            }
            NSString*nextUrlStr = [[NSString alloc] initWithFormat:@"%@://test", nextCmp];
            NSURL* testURL = [[NSURL alloc] initWithString:nextUrlStr];
            if ([app canOpenURL:testURL])
            {
                [self performSelectorOnMainThread:@selector(addScheme:) withObject:nextCmp waitUntilDone:YES];
            }
            [testURL release];
            [nextUrlStr release];
            if ([nextCmp length] < MAX_LENGTH_TO_CHECK)
            {
                for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
                {
                    [addStr appendFormat:@"%@%c_", nextCmp, c];
                }    
            }
            ct++;
            
            if (ct % PROGRESS_UPDATE_INTERVAL == 0)
            {
                NSString* fmtStr = [[NSString alloc] initWithFormat:@"%lld", ct];
                NSLog(@"Processed %@", fmtStr);
                [self performSelectorOnMainThread:@selector(setNumProcessed:) withObject:fmtStr waitUntilDone:YES];
                [fmtStr release];
            }
            
            if (ct % 100 == 0 && [addStr length] > 2000000)
            {
                NSLog(@"addStr length at end: %d", [addStr length]);
                
                NSData* data=[[addStr dataUsingEncoding:NSUTF8StringEncoding] gzipDeflate];
                NSLog(@"compressed len=%d", [data length]);
                [candidates insertObject:data atIndex:0];    
                addStr = [[NSMutableString alloc] initWithCapacity:2400000];
            }
            aIdx++;
            [pool drain];
        }
        [candidates removeLastObject];
        
        NSLog(@"addStr length at end: %d", [addStr length]);
        
        NSData* data=[[addStr dataUsingEncoding:NSUTF8StringEncoding] gzipDeflate];
        NSLog(@"compressed len=%d", [data length]);
        [candidates insertObject:data atIndex:0]; 
        
        [next release];
    }    
    
    [pool drain];
}

- (void)dealloc
{
    self.candidates = nil;
    self.web = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
