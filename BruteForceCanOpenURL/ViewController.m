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
    [self performSelectorInBackground:@selector(startAnalyzing) withObject:nil];    
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
- (void)startAnalyzing
{
    NSLog(@"Analysis started");
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity:10000];
    self.candidates = arr;
    [arr release];
    
    for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
    {
        [candidates addObject:[[NSString alloc] initWithFormat:@"%c", c]];
    }
    
    UIApplication* app = [UIApplication sharedApplication];
    long long ct=0;
    while ([candidates count] > 0)
    {
        NSString*next = [candidates objectAtIndex:0];
        NSString*nextUrlStr = [[NSString alloc] initWithFormat:@"%@://test", next];
        NSURL* testURL = [[NSURL alloc] initWithString:nextUrlStr];
        if ([app canOpenURL:testURL])
        {
            NSLog(@"%@://", next);
            [self performSelectorOnMainThread:@selector(addScheme:) withObject:next waitUntilDone:YES];
        }
        [testURL release];
        [nextUrlStr release];
        [candidates removeObjectAtIndex:0];
        if ([next length] < MAX_LENGTH_TO_CHECK)
        {
            for (NSUInteger c = ASCII_CODE_LOWER; c <= ASCII_CODE_UPPER; c++)
            {
                [candidates addObject:[[NSString alloc] initWithFormat:@"%@%c", next, c]];
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
