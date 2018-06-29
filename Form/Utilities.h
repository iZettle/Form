//
//  Utilities.h
//  Form
//
//  Created by Måns Bernhardt on 2016-11-03.
//  Copyright © 2016 iZettle. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Private helper to set the optional protocol property returnKeyType on UITextInputTrais as there is
/// currently now way to do that in Swift: `traits.returnKeyType? = newValue` won't compile
void __setReturnKeyType(id<UITextInputTraits> traits, UIReturnKeyType returnKeyType);

@interface UIImage (Construction)
/// Private helper to construct an image from another image, e.g. one with capinsets.
+ (UIImage *)imageWith__image:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
