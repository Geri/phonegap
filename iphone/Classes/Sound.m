//
//  sound.m
//  Glass
//
//  Created by Nitobi on 12/12/08.
//  Copyright 2008 Nitobi. All rights reserved.
//

#import "Sound.h"

@implementation Sound

// Initializes a sound effect object with the contents of the specified sound file
- (id)initWithContentsOfFile:(NSString *)path {
    self = [super init];
    
	// Gets the file located at the specified path.
    if (self != nil) {
        NSURL *aFileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
		// If the file exists, calls Core Audio to create a system sound ID.
        if (aFileURL != nil)  {
            SystemSoundID aSoundID;
            OSStatus error = AudioServicesCreateSystemSoundID((CFURLRef)aFileURL, &aSoundID);
            
            if (error == kAudioServicesNoError) { // success
                soundID = aSoundID;
            } else {
                NSLog(@"Error %d loading sound at path: %@", error, path);
                [self release], self = nil;
            }
        } else {
            NSLog(@"NSURL is nil for path: %@", path);
            [self release], self = nil;
        }
    }
    return self;
}

// Releases resouces when no longer needed.
-(void)dealloc {
    AudioServicesDisposeSystemSoundID(soundID);
    [super dealloc];
}

// Plays the sound associated with a sound effect object.
-(void)play {
	// Calls Core Audio to play the sound for the specified sound ID.
    AudioServicesPlaySystemSound(soundID);
}

@end