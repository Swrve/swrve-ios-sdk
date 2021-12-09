#import "SwrveInputMultiValue.h"
#import "SwrveConversationStyler.h"
#import "SwrveUITableViewCell.h"

@implementation SwrveInputMultiValue

@synthesize values;
@synthesize description;
@synthesize selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveInputMultiValue andDictionary:dict];
    if(self) {
        self.description = [dict objectForKey:@"description"];
        self.selectedIndex = -1;

        // v1/v2/v3 of conversations have no font_file, text_size, alignment
        NSMutableDictionary *style = [[dict objectForKey:kSwrveKeyStyle] mutableCopy];
        if (![style objectForKey:kSwrveKeyFontFile]) {
            [style setObject:@"" forKey:kSwrveKeyFontFile];
        }
        if (![style objectForKey:kSwrveKeyTextSize]) {
            [style setObject:kSwrveDefaultMultiValueDescriptionFontSize forKey:kSwrveKeyTextSize];
        }
        self.style = style;

        // v1/v2/v3 of conversations have no style definitions in values
        NSMutableArray *valuesMutable = [NSMutableArray new];
        for (NSDictionary *valueJson in [dict objectForKey:kSwrveKeyValues]) {
            if ([valueJson objectForKey:kSwrveKeyStyle]) {
                [valuesMutable addObject:valueJson];
            } else {
                NSMutableDictionary *styleValue = [style mutableCopy]; // copy parent style (containing colors)
                [styleValue setObject:kSwrveDefaultMultiValueCellFontName forKey:kSwrveKeyFontFile];
                [styleValue setObject:kSwrveDefaultMultiValueCellFontSize forKey:kSwrveKeyTextSize];
                NSMutableDictionary *valueJsonMutable = [valueJson mutableCopy];
                [valueJsonMutable setObject:styleValue forKey:kSwrveKeyStyle]; // add new style default
                [valuesMutable addObject:valueJsonMutable];
            }
        }
        self.values = valuesMutable;
    }
    return self;
}

-(void)setSelectedIndex:(NSInteger)inx {
    selectedIndex = inx;
}

- (UITableViewCell *)cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (![self hasDescription] || row > 0) {
        return [self fetchStandardCellForRow:row];
    } else {
        return [self fetchDescriptionCell:tableView];
    }
}

-(NSString *) userResponse {
    if(self.selectedIndex <= 0) {
        return @"";
    }
    NSUInteger inx = (NSUInteger)(self.selectedIndex - 1);
    NSDictionary *dict = [self.values objectAtIndex:inx];
    return [dict valueForKey:kSwrveKeyAnswerId];
}

-(void) loadViewWithContainerView:(UIView*)cw {
#pragma unused (cw)
    // Note: A multivalue can only be used in a table, so it doesn't load a view as such
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(BOOL)hasDescription {
    return self.description != nil;
}

-(NSUInteger) numberOfRowsNeeded {
    if(self.values != ((id)[NSNull null])) {
        return self.values.count + ([self hasDescription] ? 1 : 0);
    } else {
        return 0;
    }
}

-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    float tableWidth = (float)tableView.bounds.size.width;
    
    if (row == 0) {
        return UITableViewAutomaticDimension;
    } else {
        NSUInteger finalRow = row - ([self hasDescription]? 1 : 0);
        NSDictionary *dict = [self.values objectAtIndex:finalRow];
        NSString *cellText = [dict objectForKey:kSwrveKeyAnswerText];
        NSDictionary *cellStyle;
        if ([dict objectForKey:kSwrveKeyStyle]) {
            cellStyle = [dict objectForKey:kSwrveKeyStyle];
        }
        UIFont *fallbackFont = [UIFont fontWithName:kSwrveDefaultMultiValueCellFontName size:[kSwrveDefaultMultiValueCellFontSize floatValue]];
        UIFont *cellFont = [SwrveConversationStyler fontFromStyle:cellStyle withFallback:fallbackFont];

        return [SwrveConversationStyler textHeight:cellText withFont:cellFont withMaxWidth:tableWidth] + 22;
    }
}

- (UITableViewCell *)fetchDescriptionCell:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"descriptionCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    UIFont *fallbackFont = [UIFont boldSystemFontOfSize:[kSwrveDefaultMultiValueDescriptionFontSize floatValue]];
    UIFont *descriptionFont = [SwrveConversationStyler fontFromStyle:self.style withFallback:fallbackFont];
    [cell.textLabel setFont:descriptionFont];
    [cell.textLabel setText:self.description];
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [cell.textLabel setNumberOfLines:0];
    [SwrveConversationStyler styleView:cell withStyle:self.style];
    return cell;
}

- (UITableViewCell *)fetchStandardCellForRow:(NSUInteger)row {
    NSString *cellId = [NSString stringWithFormat:@"%@CellId", self.type];
    UITableViewCell *cell = [[SwrveUITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    if(self.selectedIndex == (NSInteger)row) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }

    NSUInteger finalRow = row - ([self hasDescription]? 1 : 0);
    NSDictionary *dict = [self.values objectAtIndex:finalRow];

    NSDictionary *cellStyle;
    if ([dict objectForKey:kSwrveKeyStyle]) {
        cellStyle = [dict objectForKey:kSwrveKeyStyle];
    }
    UIFont *fallbackFont = [UIFont fontWithName:kSwrveDefaultMultiValueCellFontName size:[kSwrveDefaultMultiValueCellFontSize floatValue]];
    UIFont *cellFont = [SwrveConversationStyler fontFromStyle:cellStyle withFallback:fallbackFont];
    [cell.textLabel setFont:cellFont];
    NSString* cellText = [dict objectForKey:kSwrveKeyAnswerText];
    [cell.textLabel setText:cellText];
    [cell.textLabel setNumberOfLines:0];
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [SwrveConversationStyler styleView:cell withStyle:cellStyle];
    return cell;
}

@end
