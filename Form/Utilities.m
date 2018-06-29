//
//  Utilities.m
//  Form
//
//  Created by Måns Bernhardt on 2016-11-03.
//  Copyright © 2016 iZettle. All rights reserved.
//

#import "Utilities.h"

void __setReturnKeyType(id<UITextInputTraits> traits, UIReturnKeyType returnKeyType) {
    traits.returnKeyType = returnKeyType;
}

@implementation UIImage (Construction)

+ (UIImage *)imageWith__image:(UIImage *)image {
    return image;
}

@end

