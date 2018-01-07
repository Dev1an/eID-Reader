#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSString *_content = @"<html style=\"background-color:rgba(0, 0, 0, 0);\"><body style=\"background-color:rgba(0, 0, 0, 0);\"><ul><li>One</li><li>Twee</li><li>Three</li></ul><p>Hello web view!<p></body></html>";
	
	NSDictionary *properties = @{ // properties for the HTML data
		(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
		(__bridge NSString *)kQLPreviewPropertyMIMETypeKey : @"text/html"
	};
	
	QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)[_content dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML, (__bridge CFDictionaryRef) properties);
	
	return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
