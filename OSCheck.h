

static bool isLeopardOrAbove()
{
    
    return YES;
    
    /*
    SInt32 version = 0;
    Gestalt( gestaltSystemVersion, &version );
		
    if ( version >= 0x1050 )
    {
        return YES;
    }
    
    return NO;
     */ // - commented out by majicdave before making open souce, this check didn't compile, probably won't work on < Leopard anyway
}
