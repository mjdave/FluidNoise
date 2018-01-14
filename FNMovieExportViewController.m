

#import "FNMovieExportViewController.h"

#import <Quicktime/Quicktime.h>
#import <Quicktime/QuickTimeComponents.h>

@implementation FNMovieExportViewController

- (NSArray *)availableComponents
{
	NSMutableArray *array = [NSMutableArray array];
	
	ComponentDescription cd;
	Component c;
	
	cd.componentType = MovieExportType;
	cd.componentSubType = 0;
	cd.componentManufacturer = 0;
	cd.componentFlags = canMovieExportFiles;
	cd.componentFlagsMask = canMovieExportFiles;
	
	while((c = FindNextComponent(c, &cd)))
	{
        
		Handle name = NewHandle(4);
		ComponentDescription exportCD;
		
		if (GetComponentInfo(c, &exportCD, name, nil, nil) == noErr)
		{
			unsigned char *namePStr = (unsigned char*)*name;
			NSString *nameStr = [[NSString alloc] initWithBytes:&namePStr[1] length:namePStr[0] encoding:NSMacOSRomanStringEncoding];
            
            /*char cc[5];
            GetComponentInfo(c, &exportCD, nil, nil, nil);
            cc[0] = 4;
            *(long *)&cc[1] = exportCD.componentSubType;
            DebugStr((StringPtr)cc);*/
            
            OSType extension;
            
            MovieExportComponent exporter = OpenComponent(c);
            MovieExportGetFileNameExtension(exporter, &extension);
            CloseComponent(exporter);
            
            NSString* stringExtension = NSFileTypeForHFSTypeCode(extension);
            NSCharacterSet* set = [NSCharacterSet characterSetWithCharactersInString:@"' "];
            stringExtension = [stringExtension stringByTrimmingCharactersInSet:set];
            if(!([stringExtension isEqualToString:@"mid"] ||
                [stringExtension isEqualToString:@"txt"] ||
                [stringExtension isEqualToString:@"xml"] ||
                [stringExtension isEqualToString:@"aif"] ||
                [stringExtension isEqualToString:@"au"] ||
                [stringExtension isEqualToString:@"wav"]))
            {
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                    nameStr, @"name",
                    stringExtension, @"extension",
                    [NSData dataWithBytes:&c length:sizeof(c)], @"component",
                    [NSNumber numberWithLong:exportCD.componentType], @"type",
                    [NSNumber numberWithLong:exportCD.componentSubType], @"subtype",
                    [NSNumber numberWithLong:exportCD.componentManufacturer], @"manufacturer",
                    [NSNumber numberWithBool:exportCD.componentFlags & hasMovieExportUserInterface], @"has_options",
                    nil];
                [array addObject:dictionary];
            }
			[nameStr release];
		}
		
		DisposeHandle(name);
	}
	return array;
}

- (void)updateFPSFromSettings:(QTAtomContainer*)settings
{
    QTAtom	atomA;
    _fps = 30.0f;
    
    atomA = QTFindChildByID(*settings, kParentAtomIsContainer, kQTSettingsTime, 1, NULL);
    if (atomA) 
    {
        atomA = QTFindChildByID(*settings, atomA, FOUR_CHAR_CODE('fps '), 1, NULL);
        if (atomA) {
            Fixed tempFPS;
			
            ComponentResult err = QTCopyAtomDataToPtr(*settings, atomA, false, sizeof(tempFPS), &tempFPS, NULL);
            if (!err)
            {
                Fixed frameRate = OSSwapHostToBigInt32(tempFPS);
                float newFPS = FixedToFloat(frameRate);
                if(newFPS > 0.1f)
                {
                    _fps = newFPS;
                    //NSLog(@"fps a:%f", _fps);
                }
            }
		}
    }
    
    QTAtom atom = QTFindChildByID(*settings, kParentAtomIsContainer, kQTSettingsVideo, 1, NULL);
    if (atom) 
    {
        long dataSize = 0;
        Ptr atomData = NULL;

        QTAtom temporalAtom = QTFindChildByID(*settings, atom, scTemporalSettingsType, 1, NULL);
        ComponentResult err = QTGetAtomDataPtr(*settings, temporalAtom, &dataSize, &atomData);
        if(!err)
        {
            SCTemporalSettings *myTemporalSettings = (void *)atomData;
            Fixed frameRate = OSSwapHostToBigInt32(myTemporalSettings->frameRate);
            float newFPS = FixedToFloat(frameRate);
            if(newFPS > 0.1f)
            {
                _fps = newFPS;
               // NSLog(@"fps b:%f", _fps);
            }
        }
    }
    
    if(_fps < 0.1f || _fps > 256.0f)
    {
        _fps = 30.0f;
    }
}

- (NSData*)getDefaultExportSettings
{
	Component c;
	memcpy(&c, [[[[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]] objectForKey:@"component"] bytes], sizeof(c));
	
	MovieExportComponent exporter = OpenComponent(c);
    
    BOOL valid = YES;
	QTAtomContainer settings;
	ComponentResult err = MovieExportGetSettingsAsAtomContainer(exporter, &settings);
	if(err)
	{
		NSLog(@"Got error when calling MovieExportGetSettingsAsAtomContainer");
		valid = NO;
	}
    NSData *data = NULL;
    if(valid)
    {
         data = [NSData dataWithBytes:*settings length:GetHandleSize(settings)];
    }
    
    [self updateFPSFromSettings:&settings];
    
    
	DisposeHandle(settings);

	CloseComponent(exporter);
	
	return data;
}

- (NSData *)getExportSettings
{
	Component c;
	memcpy(&c, [[[[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]] objectForKey:@"component"] bytes], sizeof(c));
	
	MovieExportComponent exporter = OpenComponent(c);
	Boolean canceled;
	ComponentResult err = MovieExportDoUserDialog(exporter, NULL, NULL, 0, 0, &canceled);
    
    BOOL valid = YES;
    
	if(canceled)
	{
		valid = NO;
	}
	else if(err)
	{
		NSLog(@"Got error when calling MovieExportDoUserDialog");
		valid = NO;
	}

   
	QTAtomContainer settings;
	err = MovieExportGetSettingsAsAtomContainer(exporter, &settings);
	if(err)
	{
		NSLog(@"Got error when calling MovieExportGetSettingsAsAtomContainer");
		valid = NO;
	}
    NSData *data = NULL;
    if(valid)
    {
         data = [NSData dataWithBytes:*settings length:GetHandleSize(settings)];
    }
    else
    {
        //NSLog(@"invalid");
    }
    
    [self updateFPSFromSettings:&settings];
    
    
	DisposeHandle(settings);

	CloseComponent(exporter);
	
	return data;
}

- (id)initWithSavePanel:(NSSavePanel*)sp
    currentSettings:(NSDictionary*)prefs;
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    _currentSettings = [[NSMutableDictionary alloc] init];
    
    _fps = 30.0f;
    
    BOOL OK = [NSBundle loadNibNamed:@"AnimationExportView" owner:self];
    if(!OK)
    {
        NSLog(@"failed to load nib AnimationExportView");
    }
    
    NSArray* components = [self availableComponents];
    
    [_codec removeAllItems];
    
    int selectedComponentIndex=-1;
    
	NSEnumerator *enumerator = [components objectEnumerator];
    
    NSDictionary* dict = NULL;
    while(dict = [enumerator nextObject]) 
    {
		NSString* name = [dict objectForKey:@"name"];
        unsigned int i = 2;
		for(i = 2; [_codec itemWithTitle:name] != nil; ++i)
        {
            name = [NSString stringWithFormat:@"%@-%u", [dict objectForKey:@"name"], i];
        } 
        
        if(selectedComponentIndex==-1 && [name isEqualToString:[prefs objectForKey:@"codec"]])
        {
			selectedComponentIndex = [_codec numberOfItems];
            [_currentSettings setObject:name forKey:@"codec"];
        }
		else if(selectedComponentIndex==-1 && [name isEqualToString:@"QuickTime Movie"])
        {
			selectedComponentIndex = [_codec numberOfItems];
            [_currentSettings setObject:name forKey:@"codec"];
        }
		[_codec addItemWithTitle:name];
	}
    
	if(selectedComponentIndex!=-1)
    {
        [_codec selectItemAtIndex:selectedComponentIndex];
    }
    
    _sp = sp;
    [_sp setRequiredFileType:@"mov"];
    
    [self codecChanged:self];
    
    return self;
}

- (NSView*)view
{
    return _view;
}

- (float)fps
{
    return _fps;
}

- (NSData*)exportSettings
{
    return _exportSettings;
}

- (NSDictionary*)component
{
    return [[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]];
}

- (NSDictionary*)currentSettings
{
    //NSLog(@"%@", _currentSettings);
    return nil; // I have no idea why this is nil, but I'm too scared to return _currentSettings having found it this way years after writing it this way.
}

- (IBAction)codecChanged:(id)sender
{
    Component c;
	memcpy(&c, [[[[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]] objectForKey:@"component"] bytes], sizeof(c));
    
    BOOL hasOptions = [[[[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]] objectForKey:@"has_options"] boolValue];
    
    NSString* extension = [[[self availableComponents] objectAtIndex:[_codec indexOfSelectedItem]] objectForKey:@"extension"];
    if(extension)
    {
        //NSLog(extension);
        [_sp setRequiredFileType:extension];
    }
    else
    {
        //NSLog(@"no extension");
    }
    
    if(hasOptions)
    {
        [_optionsButton setEnabled:YES];
    }
    else
    {
        [_optionsButton setEnabled:NO];
    }
    
    [_exportSettings release];
    _exportSettings = [[self getDefaultExportSettings] retain];
    

    Handle name = NewHandle(4);
    ComponentDescription exportCD;
    
    if (GetComponentInfo(c, &exportCD, name, nil, nil) == noErr)
    {
        unsigned char *namePStr = (unsigned char*)*name;
        NSString *nameStr = [[NSString alloc] initWithBytes:&namePStr[1] length:namePStr[0] encoding:NSMacOSRomanStringEncoding];
        
        [_currentSettings setObject:nameStr forKey:@"codec"];
    }
    
    _fps = 30.0f;
}

- (IBAction)optionsClicked:(id)sender
{
    NSData* newExportSettings = [self getExportSettings];
    if(newExportSettings)
    {
        [_exportSettings release];
        _exportSettings = [newExportSettings retain];
    }

}

-(void)dealloc
{
    [_exportSettings release];
    [_currentSettings release];
    [super dealloc];
}

@end
