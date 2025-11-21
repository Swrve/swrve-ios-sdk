
/*! Enumerates the possible types of action that can be associated with tapping a message button. */
typedef NS_ENUM (NSInteger, SwrveActionType){
    kSwrveActionDismiss,     /*!< Cancel the message display */
    kSwrveActionCustom,      /*!< Handle the custom action string associated with the button */
    kSwrveActionInstall,     /*!< Go to the url specified in the button’s action string */
    kSwrveActionClipboard,   /*!< Add Dynamic Text in place of the image */
    kSwrveActionCapability,  /*!< Request IAM capability*/
    kSwrveActionPageLink,     /*!< Link to another page in the message */
    kSwrveActionOpenSettings, /*!< Open App settings*/
    kSwrveActionOpenNotificationSettings,  /*!< Open Notification settings */
    kSwrveActionStartGeo      /*!< Start SwrveGeoSDK*/
};
