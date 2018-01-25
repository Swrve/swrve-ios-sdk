#import "SwrveUITableViewCell.h"
#import "SwrveConversationStyler.h"

@implementation SwrveUITableViewCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    // Avoid cropping of the label
    CGRect frame = self.textLabel.frame;
    frame.size.height = [SwrveConversationStyler textHeight:self.textLabel.text withFont:self.textLabel.font withMaxWidth:(float)self.frame.size.width];
    // Adjust vertical position for new height
    frame.origin.y = (self.frame.size.height - frame.size.height)/2;
    self.textLabel.frame = frame;
}

@end
