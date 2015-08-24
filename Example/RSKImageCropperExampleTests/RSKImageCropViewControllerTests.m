//
// RSKImageCropViewControllerTests.m
//
// Copyright (c) 2015 Ruslan Skorb, http://ruslanskorb.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RSKImageCropViewController.h"
#import "RSKImageScrollView.h"

@interface RSKImageCropViewControllerDataSourceObject1 : NSObject <RSKImageCropViewControllerDataSource>

@end

@implementation RSKImageCropViewControllerDataSourceObject1

// Returns a custom rect for the mask.
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize maskSize;
    if ([controller isPortraitInterfaceOrientation]) {
        maskSize = CGSizeMake(250, 250);
    } else {
        maskSize = CGSizeMake(220, 220);
    }
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}

// Returns a custom path for the mask.
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    CGRect rect = controller.maskRect;
    CGPoint point1 = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPoint point2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    CGPoint point3 = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    
    UIBezierPath *triangle = [UIBezierPath bezierPath];
    [triangle moveToPoint:point1];
    [triangle addLineToPoint:point2];
    [triangle addLineToPoint:point3];
    [triangle closePath];
    
    return triangle;
}

// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    // If the image is not rotated, then the movement rect coincides with the mask rect.
    return controller.maskRect;
}

@end

@interface RSKImageCropViewControllerDataSourceObject2 : NSObject <RSKImageCropViewControllerDataSource>

@end

@implementation RSKImageCropViewControllerDataSourceObject2

- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    return CGRectZero;
};

- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    return [UIBezierPath bezierPath];
};

@end

@interface RSKImageCropViewControllerDelegateObject1 : NSObject <RSKImageCropViewControllerDelegate>

@end

@implementation RSKImageCropViewControllerDelegateObject1

- (void)imageCropViewController:(RSKImageCropViewController *)controller willCropImage:(UIImage *)originalImage {}
- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect {};
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller {};

@end

@interface RSKImageCropViewControllerDelegateObject2 : NSObject <RSKImageCropViewControllerDelegate>

@end

@implementation RSKImageCropViewControllerDelegateObject2

- (void)imageCropViewController:(RSKImageCropViewController *)controller didCropImage:(UIImage *)croppedImage usingCropRect:(CGRect)cropRect rotationAngle:(CGFloat)rotationAngle {}

@end

static const CGFloat kLayoutImageScrollViewAnimationDuration = 0.25;

@interface RSKImageCropViewController (Testing)

@property (strong, nonatomic) RSKImageScrollView *imageScrollView;
@property (assign, nonatomic) BOOL originalNavigationControllerNavigationBarHidden;
@property (assign, nonatomic) BOOL originalStatusBarHidden;
@property (assign, nonatomic) CGFloat rotationAngle;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotationGestureRecognizer;

- (void)cancelCrop;
- (void)cropImage;
- (UIImage *)croppedImage:(UIImage *)image cropMode:(RSKImageCropMode)cropMode cropRect:(CGRect)cropRect rotationAngle:(CGFloat)rotationAngle zoomScale:(CGFloat)zoomScale maskPath:(UIBezierPath *)maskPath applyMaskToCroppedImage:(BOOL)applyMaskToCroppedImage;
- (void)displayImage;
- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer;
- (void)handleRotation:(UIRotationGestureRecognizer *)gestureRecognizer;
- (void)onCancelButtonTouch:(UIBarButtonItem *)sender;
- (void)onChooseButtonTouch:(UIBarButtonItem *)sender;
- (void)layoutImageScrollView;
- (void)reset:(BOOL)animated;
- (void)resetContentOffset;
- (void)resetFrame;
- (void)resetRotation;
- (void)resetZoomScale;

@end

SpecBegin(RSKImageCropViewController)

describe(@"init", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
    });
    
    it(@"should init with disabled rotation", ^{
        expect(imageCropViewController.rotationEnabled).to.beFalsy();
    });
    
    it(@"should init with disabled masking image", ^{
        expect(imageCropViewController.applyMaskToCroppedImage).to.beFalsy();
    });
    
    it(@"should init with disabled avoiding empty space around image", ^{
        expect(imageCropViewController.avoidEmptySpaceAroundImage).to.beFalsy();
    });
});

describe(@"initWithImage:", ^{
    __block UIImage *image = nil;
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        image = [UIImage imageNamed:@"photo"];
        imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:image];
    });
    
    it(@"should init with the specified image", ^{
        expect(imageCropViewController.originalImage).to.equal(image);
    });
    
    it(@"should init with default crop mode of `RSKImageCropModeCircle`", ^{
        expect(imageCropViewController.cropMode).to.equal(RSKImageCropModeCircle);
    });
});

describe(@"initWithImage:cropMode:", ^{
    it(@"should init with specified crop mode", ^{
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:nil cropMode:RSKImageCropModeSquare];
        expect(imageCropViewController.cropMode).to.equal(RSKImageCropModeSquare);
    });
});

describe(@"empty space around the image", ^{
    it(@"sets `aspectFill` of `imageScrollView` identical to `avoidEmptySpaceAroundImage`", ^{
        BOOL testAvoidEmptySpaceAroundImage = YES;
        
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] init];
        
        expect(imageCropViewController.imageScrollView.aspectFill).notTo.equal(testAvoidEmptySpaceAroundImage);
        
        imageCropViewController.avoidEmptySpaceAroundImage = testAvoidEmptySpaceAroundImage;
        
        expect(imageCropViewController.imageScrollView.aspectFill).to.equal(testAvoidEmptySpaceAroundImage);
    });
});

describe(@"crop image", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    __block UIImage *originalImage = nil;
    
    dispatch_block_t sharedLoadView = ^{
        [imageCropViewController view];
        
        [imageCropViewController.view setNeedsUpdateConstraints];
        [imageCropViewController.view updateConstraintsIfNeeded];
        
        [imageCropViewController.view setNeedsLayout];
        [imageCropViewController.view layoutIfNeeded];
        
        [imageCropViewController viewWillAppear:YES];
        [imageCropViewController viewDidAppear:YES];
    };
    
    dispatch_block_t sharedIt = ^{
        UIImage *croppedImage = [imageCropViewController croppedImage:imageCropViewController.originalImage cropMode:imageCropViewController.cropMode cropRect:imageCropViewController.cropRect rotationAngle:imageCropViewController.rotationAngle zoomScale:imageCropViewController.zoomScale maskPath:imageCropViewController.maskPath applyMaskToCroppedImage:imageCropViewController.applyMaskToCroppedImage];
        
        expect(croppedImage).notTo.beNil();
        expect(croppedImage.imageOrientation).to.equal(UIImageOrientationUp);
        expect(croppedImage.scale).to.equal(imageCropViewController.originalImage.scale);
    };
    before(^{
        originalImage = [UIImage imageNamed:@"photo"];
    });
    
    describe(@"crop mode is `RSKImageCropModeCircle`", ^{
        before(^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:originalImage cropMode:RSKImageCropModeCircle];
            
            sharedLoadView();
        });
        
        it(@"correctly crop the image when all properties are default", ^{
            sharedIt();
        });
        
        it(@"correctly crop the image when rotation angle is not equal to 0", ^{
            imageCropViewController.rotationAngle = M_PI_4;
            
            sharedIt();
        });
        
        it(@"correctly crop the image when `applyMaskToCroppedImage` is `YES`", ^{
            imageCropViewController.applyMaskToCroppedImage = YES;
            
            sharedIt();
        });
        
        after(^{
            imageCropViewController = nil;
        });
    });
    
    describe(@"crop mode is `RSKImageCropModeSquare`", ^{
        before(^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:originalImage cropMode:RSKImageCropModeSquare];
            
            sharedLoadView();
        });
        
        it(@"correctly crop the image when all properties are default", ^{
            sharedIt();
        });
        
        it(@"correctly crop the image when rotation angle is not equal to 0", ^{
            imageCropViewController.rotationAngle = M_PI_4;
            
            sharedIt();
        });
        
        it(@"correctly crop the image when `applyMaskToCroppedImage` is `YES`", ^{
            imageCropViewController.applyMaskToCroppedImage = YES;
            
            sharedIt();
        });
        
        after(^{
            imageCropViewController = nil;
        });
    });
    
    describe(@"crop mode is `RSKImageCropModeCustom`", ^{
        before(^{
            RSKImageCropViewControllerDataSourceObject1 *dataSourceObject = [[RSKImageCropViewControllerDataSourceObject1 alloc] init];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:originalImage cropMode:RSKImageCropModeCustom];
            imageCropViewController.dataSource = dataSourceObject;
            
            sharedLoadView();
        });
        
        it(@"correctly crop the image when all properties are default", ^{
            sharedIt();
        });
        
        it(@"correctly crop the image when rotation angle is not equal to 0", ^{
            imageCropViewController.rotationAngle = M_PI_4;
            
            sharedIt();
        });
        
        it(@"correctly crop the image when `applyMaskToCroppedImage` is `YES`", ^{
            imageCropViewController.applyMaskToCroppedImage = YES;
            
            sharedIt();
        });
        
        after(^{
            imageCropViewController = nil;
        });
    });
    
    describe(@"crop image with any image orientation", ^{
        it(@"UIImageOrientationDown", ^{
            UIImage *downImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationDown];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:downImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationLeft", ^{
            UIImage *leftImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationLeft];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:leftImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationRight", ^{
            UIImage *rightImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationRight];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:rightImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationUpMirrored", ^{
            UIImage *upMirroredImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationUpMirrored];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:upMirroredImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationDownMirrored", ^{
            UIImage *downMirroredImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationDownMirrored];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:downMirroredImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationLeftMirrored", ^{
            UIImage *leftMirroredImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationLeftMirrored];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:leftMirroredImage];
            
            sharedLoadView();
            sharedIt();
        });
        
        it(@"UIImageOrientationRightMirrored", ^{
            UIImage *rightMirroredImage = [UIImage imageWithCGImage:originalImage.CGImage scale:originalImage.scale orientation:UIImageOrientationRightMirrored];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:rightMirroredImage];
            
            sharedLoadView();
            sharedIt();
        });
    });
});

describe(@"crop view", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    dispatch_block_t sharedIt = ^{
        [imageCropViewController.view setNeedsUpdateConstraints];
        [imageCropViewController.view updateConstraintsIfNeeded];
        
        [imageCropViewController.view setNeedsLayout];
        [imageCropViewController.view layoutIfNeeded];
        
        [imageCropViewController viewWillAppear:NO];
        [imageCropViewController viewDidAppear:NO];
        
        expect(imageCropViewController.view).to.haveValidSnapshot();
    };
    
    describe(@"portrait", ^{
        dispatch_block_t sharedPortraitIt = ^{
            imageCropViewController.view.frame = CGRectMake(0, 0, 320, 568);
            
            sharedIt();
        };
        
        it(@"looks right when crop mode is `RSKImageCropModeCircle`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeCircle];
            
            sharedPortraitIt();
        });
        
        it(@"looks right when crop mode is `RSKImageCropModeSquare`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeSquare];
            
            sharedPortraitIt();
        });
        
        it(@"looks right when crop mode is `RSKImageCropModeCustom`", ^{
            RSKImageCropViewControllerDataSourceObject1 *dataSourceObject = [[RSKImageCropViewControllerDataSourceObject1 alloc] init];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeCustom];
            imageCropViewController.dataSource = dataSourceObject;
            
            sharedPortraitIt();
        });
    });
    
    describe(@"landscape", ^{
        dispatch_block_t sharedLandscapeIt = ^{
            imageCropViewController.view.frame = CGRectMake(0, 0, 568, 320);
            
            sharedIt();
        };
        
        it(@"looks right when crop mode is `RSKImageCropModeCircle`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeCircle];
            
            sharedLandscapeIt();
        });
        
        it(@"looks right when crop mode is `RSKImageCropModeSquare`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeSquare];
            
            sharedLandscapeIt();
        });
        
        it(@"looks right when crop mode is `RSKImageCropModeCustom`", ^{
            RSKImageCropViewControllerDataSourceObject1 *dataSourceObject = [[RSKImageCropViewControllerDataSourceObject1 alloc] init];
            
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"] cropMode:RSKImageCropModeCustom];
            imageCropViewController.dataSource = dataSourceObject;
            
            sharedLandscapeIt();
        });
    });
});

describe(@"dataSource", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:nil cropMode:RSKImageCropModeCustom];
    });
    
    describe(@"with all methods", ^{
        __block id <RSKImageCropViewControllerDataSource> dataSourceObject = nil;
        
        before(^{
            dataSourceObject = [[RSKImageCropViewControllerDataSourceObject1 alloc] init];
            imageCropViewController.dataSource = dataSourceObject;
        });
        
        it(@"gives the right custom mask rect", ^{
            CGRect customMaskRect = CGRectMake(20, 40, 250, 250);
            
            id dataSourceMock = [OCMockObject partialMockForObject:dataSourceObject];
            [[[dataSourceMock stub] andReturnValue:[NSValue valueWithCGRect:customMaskRect]] imageCropViewControllerCustomMaskRect:imageCropViewController];
            [[dataSourceMock expect] imageCropViewControllerCustomMaskRect:imageCropViewController];
            
            [imageCropViewController view];
            
            [imageCropViewController.view setNeedsUpdateConstraints];
            [imageCropViewController.view updateConstraintsIfNeeded];
            
            [imageCropViewController.view setNeedsLayout];
            [imageCropViewController.view layoutIfNeeded];
            
            expect(imageCropViewController.maskRect).to.equal(customMaskRect);
            
            [dataSourceMock stopMocking];
        });
        
        it(@"gives the right custom movement rect", ^{
            CGRect customMovementRect = CGRectMake(20, 40, 250, 250);
            
            id dataSourceMock = [OCMockObject partialMockForObject:dataSourceObject];
            [[[dataSourceMock stub] andReturnValue:[NSValue valueWithCGRect:customMovementRect]] imageCropViewControllerCustomMovementRect:imageCropViewController];
            [[dataSourceMock expect] imageCropViewControllerCustomMovementRect:imageCropViewController];
            
            [imageCropViewController view];
            
            [imageCropViewController.view setNeedsUpdateConstraints];
            [imageCropViewController.view updateConstraintsIfNeeded];
            
            [imageCropViewController.view setNeedsLayout];
            [imageCropViewController.view layoutIfNeeded];
            
            expect(imageCropViewController.imageScrollView.frame).to.equal(customMovementRect);
            
            [dataSourceMock stopMocking];
        });
        
        it(@"gives the right custom mask path", ^{
            CGRect customMaskRect = CGRectMake(20, 40, 250, 250);
            UIBezierPath *customMaskPath = [UIBezierPath bezierPathWithRect:customMaskRect];
            
            id dataSourceMock = [OCMockObject partialMockForObject:dataSourceObject];
            [[[dataSourceMock stub] andReturn:customMaskPath] imageCropViewControllerCustomMaskPath:imageCropViewController];
            [[dataSourceMock expect] imageCropViewControllerCustomMaskPath:imageCropViewController];
            
            [imageCropViewController view];
            
            [imageCropViewController.view setNeedsUpdateConstraints];
            [imageCropViewController.view updateConstraintsIfNeeded];
            
            [imageCropViewController.view setNeedsLayout];
            [imageCropViewController.view layoutIfNeeded];
            
            expect(imageCropViewController.maskPath).to.equal(customMaskPath);
            
            [dataSourceMock stopMocking];
        });
        
        after(^{
            dataSourceObject = nil;
        });
    });
    
    describe(@"without optional methods", ^{
        __block id <RSKImageCropViewControllerDataSource> dataSourceObject = nil;
        
        before(^{
            dataSourceObject = [[RSKImageCropViewControllerDataSourceObject2 alloc] init];
            imageCropViewController.dataSource = dataSourceObject;
        });
        
        it(@"sets the right custom movement rect", ^{
            [imageCropViewController view];
            
            [imageCropViewController.view setNeedsUpdateConstraints];
            [imageCropViewController.view updateConstraintsIfNeeded];
            
            [imageCropViewController.view setNeedsLayout];
            [imageCropViewController.view layoutIfNeeded];
            
            expect(imageCropViewController.imageScrollView.frame).to.equal(imageCropViewController.maskRect);
        });
        
        after(^{
            dataSourceObject = nil;
        });
    });
    
    after(^{
        imageCropViewController = nil;
    });
});

describe(@"delegate", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
    });
    
    it(@"calls appropriate delegate methods before and after cropping image", ^{
        RSKImageCropViewControllerDelegateObject1 *delegateObject = [[RSKImageCropViewControllerDelegateObject1 alloc] init];
        imageCropViewController.delegate = delegateObject;
        
        id delegateMock = [OCMockObject partialMockForObject:delegateObject];
        
        [[delegateMock expect] imageCropViewController:imageCropViewController willCropImage:OCMOCK_ANY];
        [[delegateMock expect] imageCropViewController:imageCropViewController didCropImage:OCMOCK_ANY usingCropRect:imageCropViewController.cropRect];
        
        [imageCropViewController cropImage];
        
        [delegateMock verifyWithDelay:1.0];
        [delegateMock stopMocking];
    });
    
    it(@"calls the appropriate delegate method after cropping image", ^{
        RSKImageCropViewControllerDelegateObject2 *delegateObject = [[RSKImageCropViewControllerDelegateObject2 alloc] init];
        imageCropViewController.delegate = delegateObject;
        
        id delegateMock = [OCMockObject partialMockForObject:delegateObject];
        
        [[delegateMock expect] imageCropViewController:imageCropViewController didCropImage:OCMOCK_ANY usingCropRect:imageCropViewController.cropRect rotationAngle:imageCropViewController.rotationAngle];
        
        [imageCropViewController cropImage];
        
        [delegateMock verifyWithDelay:1.0];
        [delegateMock stopMocking];
    });
    
    it(@"calls the appropriate delegate method if the user cancel cropping image", ^{
        RSKImageCropViewControllerDelegateObject1 *delegateObject = [[RSKImageCropViewControllerDelegateObject1 alloc] init];
        imageCropViewController.delegate = delegateObject;
        
        id delegateMock = [OCMockObject partialMockForObject:delegateObject];
        
        [[delegateMock expect] imageCropViewControllerDidCancelCrop:imageCropViewController];
        
        [imageCropViewController cancelCrop];
        
        [delegateMock verify];
        [delegateMock stopMocking];
    });
    
    after(^{
        imageCropViewController = nil;
    });
});

describe(@"navigation controller navigation bar", ^{
    it(@"hides navigation bar in viewWillAppear:", ^{
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] init];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imageCropViewController];
        id mock = [OCMockObject partialMockForObject:navigationController];
        
        [[mock expect] setNavigationBarHidden:YES animated:NO];
        
        [imageCropViewController view];
        [imageCropViewController viewWillAppear:NO];
        
        [mock verify];
    });
    
    it(@"restores visibility of the navigation bar in viewWillDisappear:", ^{
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] init];
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imageCropViewController];
        id mock = [OCMockObject partialMockForObject:navigationController];
        
        [imageCropViewController view];
        [imageCropViewController viewWillAppear:NO];
        
        [[mock expect] setNavigationBarHidden:imageCropViewController.originalNavigationControllerNavigationBarHidden animated:NO];
        
        [imageCropViewController viewWillDisappear:NO];
        
        [mock verify];
    });
});

describe(@"original image", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
        [imageCropViewController view];
        [imageCropViewController.view setNeedsUpdateConstraints];
        [imageCropViewController.view updateConstraintsIfNeeded];
        [imageCropViewController.view setNeedsLayout];
        [imageCropViewController.view layoutIfNeeded];
        [imageCropViewController viewWillAppear:NO];
        [imageCropViewController viewDidAppear:NO];
    });
    
    it(@"displays new original image", ^{
        id mockImageCropViewControllerView = [OCMockObject partialMockForObject:imageCropViewController.view];
        [[[mockImageCropViewControllerView stub] andReturn:[[UIWindow alloc] init]] window];
        
        id mockImageCropViewController = [OCMockObject partialMockForObject:imageCropViewController];
        [[[mockImageCropViewController stub] andReturn:mockImageCropViewControllerView] view];
        [[mockImageCropViewController expect] displayImage];
        
        imageCropViewController.originalImage = [UIImage imageNamed:@"photo"];
        
        [mockImageCropViewController verify];
        [mockImageCropViewController stopMocking];
        [mockImageCropViewControllerView stopMocking];
    });
    
    after(^{
        imageCropViewController = nil;
    });
});

describe(@"reset", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:[UIImage imageNamed:@"photo"]];
        // Loads view and calls viewDidLoad.
        [imageCropViewController view];
        
        [imageCropViewController.view setNeedsUpdateConstraints];
        [imageCropViewController.view updateConstraintsIfNeeded];
        
        [imageCropViewController.view setNeedsLayout];
        [imageCropViewController.view layoutIfNeeded];
    });
    
    it(@"should reset rotation", ^{
        CGFloat initialRotationAngle = imageCropViewController.rotationAngle;
        CGFloat testRotationAngle = M_PI_2;
        imageCropViewController.rotationAngle = testRotationAngle;
        [imageCropViewController resetRotation];
        expect(imageCropViewController.rotationAngle).to.equal(initialRotationAngle);
    });
    
    it(@"should reset frame", ^{
        CGRect initialFrame = imageCropViewController.imageScrollView.frame;
        CGRect testFrame = CGRectOffset(imageCropViewController.maskRect, 100, 100);
        imageCropViewController.imageScrollView.frame = testFrame;
        [imageCropViewController resetFrame];
        expect(imageCropViewController.imageScrollView.frame).to.equal(initialFrame);
    });
    
    it(@"should reset zoom scale", ^{
        CGFloat initialZoomScale = imageCropViewController.zoomScale;
        CGFloat testZoomScale = initialZoomScale + 0.1;
        imageCropViewController.imageScrollView.zoomScale = testZoomScale;
        [imageCropViewController resetZoomScale];
        expect(imageCropViewController.zoomScale).to.equal(initialZoomScale);
    });
    
    it(@"should reset content offset", ^{
        CGPoint initialContentOffset = imageCropViewController.imageScrollView.contentOffset;
        CGPoint testContentOffset = CGPointMake(initialContentOffset.x + 50, initialContentOffset.y + 50);
        imageCropViewController.imageScrollView.contentOffset = testContentOffset;
        [imageCropViewController resetContentOffset];
        expect(imageCropViewController.imageScrollView.contentOffset).to.equal(initialContentOffset);
    });
    
    it(@"should reset rotation, frame, zoom scale, content offset", ^{
        CGFloat initialRotationAngle = imageCropViewController.rotationAngle;
        CGRect initialFrame = imageCropViewController.imageScrollView.frame;
        CGFloat initialZoomScale = imageCropViewController.zoomScale;
        CGPoint initialContentOffset = imageCropViewController.imageScrollView.contentOffset;
        
        CGFloat testRotationAngle = M_PI_2;
        CGRect testFrame = CGRectOffset(imageCropViewController.maskRect, 100, 100);
        CGFloat testZoomScale = initialZoomScale + 0.1;
        CGPoint testContentOffset = CGPointMake(initialContentOffset.x + 50, initialContentOffset.y + 50);
        
        imageCropViewController.rotationAngle = testRotationAngle;
        
        CGAffineTransform transform = imageCropViewController.imageScrollView.transform;
        imageCropViewController.imageScrollView.transform = CGAffineTransformIdentity;
        imageCropViewController.imageScrollView.frame = testFrame;
        imageCropViewController.imageScrollView.transform = transform;
        
        imageCropViewController.imageScrollView.zoomScale = testZoomScale;
        imageCropViewController.imageScrollView.contentOffset = testContentOffset;
        
        [imageCropViewController reset:NO];
        
        expect(imageCropViewController.rotationAngle).to.equal(initialRotationAngle);
        expect(imageCropViewController.imageScrollView.frame).to.equal(initialFrame);
        expect(imageCropViewController.zoomScale).to.equal(initialZoomScale);
        expect(imageCropViewController.imageScrollView.contentOffset).to.equal(initialContentOffset);
    });
    
    after(^{
        imageCropViewController = nil;
    });
});

describe(@"rotation", ^{
    __block id mockRotationGestureRecognizer = nil;
    __block CGFloat testRotationAngle;
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        testRotationAngle = M_PI_2;
        
        UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] init];
        mockRotationGestureRecognizer = [OCMockObject partialMockForObject:rotationGestureRecognizer];
        [[[mockRotationGestureRecognizer stub] andReturnValue:@(testRotationAngle)] rotation];
        [[[mockRotationGestureRecognizer stub] andReturnValue:@(UIGestureRecognizerStateEnded)] state];
    });
    
    it(@"enables the rotation", ^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
        BOOL testRotationEnabled = YES;
        
        id mockRotationGestureRecognizer = [OCMockObject partialMockForObject:imageCropViewController.rotationGestureRecognizer];
        [[mockRotationGestureRecognizer expect] setEnabled:testRotationEnabled];
        
        imageCropViewController.rotationEnabled = testRotationEnabled;
        
        [mockRotationGestureRecognizer verify];
        [mockRotationGestureRecognizer stopMocking];
    });
    
    it(@"handles the rotation", ^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
        id mockImageCropViewController = [OCMockObject partialMockForObject:imageCropViewController];
        
        [[mockImageCropViewController expect] setRotationAngle:testRotationAngle];
        [[mockImageCropViewController expect] layoutImageScrollView];
        
        [mockImageCropViewController handleRotation:mockRotationGestureRecognizer];
        
        [mockImageCropViewController verifyWithDelay:kLayoutImageScrollViewAnimationDuration];
        [mockImageCropViewController stopMocking];
    });
    
    it(@"correctly sets the rotation angle", ^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
        imageCropViewController.rotationAngle = testRotationAngle;
        
        expect(imageCropViewController.rotationAngle).to.equal(testRotationAngle);
    });
    
    describe(@"movement rect", ^{
        dispatch_block_t sharedIt = ^{
            [imageCropViewController view];
            
            [imageCropViewController.view setNeedsUpdateConstraints];
            [imageCropViewController.view updateConstraintsIfNeeded];
            
            [imageCropViewController.view setNeedsLayout];
            [imageCropViewController.view layoutIfNeeded];
            
            [imageCropViewController handleRotation:mockRotationGestureRecognizer];
        };
        
        it(@"correctly sets the movement rect after rotation when crop mode is `RSKImageCropModeCircle`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:nil cropMode:RSKImageCropModeCircle];
            
            sharedIt();
            
            expect(imageCropViewController.imageScrollView.frame).after(kLayoutImageScrollViewAnimationDuration).to.equal(imageCropViewController.maskRect);
        });
        
        it(@"correctly sets the movement rect after rotation when crop mode is `RSKImageCropModeSquare`", ^{
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:nil cropMode:RSKImageCropModeSquare];
            
            sharedIt();
            
            expect(imageCropViewController.imageScrollView.frame).after(kLayoutImageScrollViewAnimationDuration).to.equal(imageCropViewController.maskRect);
        });
        
        it(@"correctly sets the movement rect after rotation when crop mode is `RSKImageCropModeCustom`", ^{
            RSKImageCropViewControllerDataSourceObject1 *dataSourceObject = [[RSKImageCropViewControllerDataSourceObject1 alloc] init];
            imageCropViewController = [[RSKImageCropViewController alloc] initWithImage:nil cropMode:RSKImageCropModeCustom];
            imageCropViewController.dataSource = dataSourceObject;
            
            sharedIt();
            
            expect(imageCropViewController.imageScrollView.frame).after(kLayoutImageScrollViewAnimationDuration).to.equal([dataSourceObject imageCropViewControllerCustomMovementRect:imageCropViewController]);
        });
        
        after(^{
            imageCropViewController = nil;
        });
    });
    
    after(^{
        [mockRotationGestureRecognizer stopMocking];
        imageCropViewController = nil;
    });
});

describe(@"status bar", ^{
    it(@"hides status bar in viewWillAppear:", ^{
        UIApplication *application = [UIApplication sharedApplication];
        id mock = [OCMockObject partialMockForObject:application];
        
        [[mock expect] setStatusBarHidden:YES];
        
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] init];
        [imageCropViewController view];
        [imageCropViewController viewWillAppear:NO];
        
        [mock verify];
    });
    
    it(@"restores visibility of the status bar in viewWillDisappear:", ^{
        RSKImageCropViewController *imageCropViewController = [[RSKImageCropViewController alloc] init];
        
        UIApplication *application = [UIApplication sharedApplication];
        id mock = [OCMockObject partialMockForObject:application];
        
        [imageCropViewController view];
        [imageCropViewController viewWillAppear:NO];
        
        [[mock expect] setStatusBarHidden:imageCropViewController.originalStatusBarHidden];
        
        [imageCropViewController viewWillDisappear:NO];
        
        [mock verify];
    });
});

describe(@"taps", ^{
    __block RSKImageCropViewController *imageCropViewController = nil;
    
    before(^{
        imageCropViewController = [[RSKImageCropViewController alloc] init];
    });
    
    it(@"handles double tap on the image", ^{
        id mock = [OCMockObject partialMockForObject:imageCropViewController];
        [[mock expect] reset:YES];
        
        [imageCropViewController handleDoubleTap:nil];
        
        [mock verify];
    });
    
    it(@"handles tap on the cancel button", ^{
        id mock = [OCMockObject partialMockForObject:imageCropViewController];
        [[mock expect] cancelCrop];
        
        [imageCropViewController onCancelButtonTouch:nil];
        
        [mock verify];
    });
    
    it(@"handles tap on the choose button", ^{
        id mock = [OCMockObject partialMockForObject:imageCropViewController];
        [[mock expect] cropImage];
        
        [imageCropViewController onChooseButtonTouch:nil];
        
        [mock verify];
    });
    
    after(^{
        imageCropViewController = nil;
    });
});

SpecEnd
