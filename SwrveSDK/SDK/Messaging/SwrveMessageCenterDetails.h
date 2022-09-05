#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SwrveMessageCenterDetails : NSObject

@property(retain, nonatomic) NSString *_Nullable subject;
@property(retain, nonatomic) NSString *_Nullable description;
@property(retain, nonatomic) UIImage *_Nullable image;
@property(retain, nonatomic) NSString *_Nullable imageSha;
@property(retain, nonatomic) NSString *_Nullable imageUrl;
@property(retain, nonatomic) NSString *_Nullable imageAccessibilityText;

NS_ASSUME_NONNULL_BEGIN

- (id)initWithJSON:(NSDictionary *)data;

- (id)initWith:(NSString *)subjectStr description:(NSString *)descriptionStr accessibilityText:(NSString *)accessibilityTextStr
      imageUrl:(NSString *)imageUrlStr imageSha:(NSString *)imageShaStr image:(UIImage *)imageUI;
@end

NS_ASSUME_NONNULL_END
