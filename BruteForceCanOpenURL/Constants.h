//
//  Constants.h
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

// Ascii code for lower range of test bounds (a)
#define ASCII_CODE_LOWER 97

// Ascii code for upper range of test bounds (z)
#define ASCII_CODE_UPPER 122

// When to stop
#define MAX_LENGTH_TO_CHECK 8

// How many checks should pass before progress indicator is updated
#define PROGRESS_UPDATE_INTERVAL 10000

// When true, compresses the BFS search tree in memory to 
// allow for a larger search space
#define USE_COMPRESSION YES
