//
//  COCTextField.m
//  linphone
//
//  Created by Anton Pomozov on 29.09.14.
//
//

#import "COCTextField.h"

@implementation COCTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        self.editable = YES;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self.edgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:) || action == @selector(cut:)) {
        return self.editable;
    }
    return [super canPerformAction:action withSender:sender];
}

@end
