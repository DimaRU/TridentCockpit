/////
////  TridentCockpitiOS-Bridging-Header.h
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//


#import <UIKit/UIKit.h>

static NSString *const __nonnull HaishinKitIdentifier = @"com.haishinkit.HaishinKit";

// @see http://stackoverflow.com/questions/35119531/catch-objective-c-exception-in-swift
NS_INLINE void nstry(void(^_Nonnull lambda)(void), void(^_Nullable error)(NSException *_Nonnull exception)) {
    @try {
        lambda();
    }
    @catch (NSException *exception) {
        if (error != NULL) {
            @try {
                error(exception);
            }@catch(NSException *exception) {

            }
        }
    }
}
