//
//  UIImage+Utility.m
//  ChatApp
//
//  Created by shaik riyaz on 22/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import "UIImage+Utility.h"
#import "ALChatViewController.h"
#import "ALApplozicSettings.h"

#define  DEFAULT_MAX_FILE_UPLOAD_SIZE 32

@implementation UIImage (Utility)

-(double)getImageSizeInMb
{
    NSData * imageData = UIImageJPEGRepresentation(self, 1);
    
    return (imageData.length/1024.0)/1024.0;
}

//-(BOOL)islandScape
//{
//    return self.size.width>self.size.height?YES:NO;
//}

-(UIImage *)getCompressedImageLessThanSize:(double)sizeInMb
{
    
    UIImage * originalImage = self;
    
    NSData * theImageData = UIImageJPEGRepresentation(originalImage,1);
    
    int numberOfAttempts = 0;
    
    while (self.getImageSizeInMb > sizeInMb && numberOfAttempts < 5) {
        
        numberOfAttempts = numberOfAttempts + 1;
        
        theImageData = UIImageJPEGRepresentation(self,0.9);
        
        originalImage = [UIImage imageWithData:theImageData];
        
    }
    
    return originalImage;
}

-(NSData *)getCompressedImageData
{
    
    CGFloat compression = 1.0f;
    CGFloat maxCompression = [ALApplozicSettings getMaxCompressionFactor];
    NSInteger maxSize =( [ALApplozicSettings getMaxImageSizeForUploadInMB]==0 )? DEFAULT_MAX_FILE_UPLOAD_SIZE : [ALApplozicSettings getMaxImageSizeForUploadInMB];
    NSData *imageData = UIImageJPEGRepresentation(self, compression);
    
    while (((imageData.length/1024.0)/1024.0) > maxSize & compression > maxCompression)
    {
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(self, compression);
        
    }
    return imageData;
    
}
- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            case UIImageOrientationUp:
            case UIImageOrientationDown:
            case UIImageOrientationLeft:
            case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end
