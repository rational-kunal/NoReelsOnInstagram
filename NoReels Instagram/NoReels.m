//
//  NoReels.m
//  NoReels Instagram
//
//  Created by Kunal Kamble on 21/07/24.
//

#import "NoReels.h"
#import <FLEX.h>
#import <objc/runtime.h>
#import <AVKit/AVKit.h>
#import <SDWebImage/SDWebImage.h>

#pragma mark - MemeImageViewController

@interface MemeImageViewController : UIViewController
@end

@implementation MemeImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.blackColor;
    
    // Create and configure the image view
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    
    [imageView sd_setImageWithURL:[NSURL URLWithString:@"https://media1.tenor.com/m/q2eL6vNVKf4AAAAC/bhai-kya-kar-raha-hai-tu-ashneer-grover.gif"]];
}

@end

#pragma mark - NoReels

@implementation NoReels

+ (void)load {
    NSLog(@"[##] NoReels Loaded");

    // After 2s launch flex tool
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [FLEXManager.sharedManager showExplorer];
    });

    // Swizzle `-[IGTabBarController _discoverVideoButtonPressed]` to call our implementation
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class igTabBarControllerClass = NSClassFromString(@"IGTabBarController");
        
        SEL originalSelector = NSSelectorFromString(@"_discoverVideoButtonPressed");
        SEL swizzledSelector = @selector(swizzled_discoverVideoButtonPressed);
        
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);

        class_addMethod(igTabBarControllerClass,
                        method_getName(swizzledMethod),
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        Method originalMethod = class_getInstanceMethod(igTabBarControllerClass, originalSelector);
        Method addedMethod = class_getInstanceMethod(igTabBarControllerClass, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, addedMethod);
    });
}

// Launch a meme view controller
- (void)swizzled_discoverVideoButtonPressed {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    UIViewController *memeVC = [[MemeImageViewController alloc] init];
    [topController presentViewController:memeVC animated:YES completion:nil];
}

@end

#pragma mark - NSFileManager (Swizzling)

@interface NSFileManager (Swizzling)
@end

@implementation NSFileManager (Swizzling)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:);
        SEL swizzledSelector = @selector(swizzled_enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (NSDirectoryEnumerator<NSURL *> *)swizzled_enumeratorAtURL:(NSURL *)url
     includingPropertiesForKeys:(NSArray<NSURLResourceKey> *)keys
                        options:(NSDirectoryEnumerationOptions)mask
                   errorHandler:(BOOL (^)(NSURL *url, NSError *error))handler {
    if (url == nil) {
        NSLog(@"[NoReels] enumeratorAtURL called with nil url");
        return nil;
    }

    return [self swizzled_enumeratorAtURL:url includingPropertiesForKeys:keys options:mask errorHandler:handler];
}

@end

