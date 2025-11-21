/*! Supported orientations for in-app messages. */
typedef NS_ENUM(NSInteger, SwrveInterfaceOrientation) {
    /*! App supports landscape only. */
    SWRVE_ORIENTATION_LANDSCAPE = 0,
    
    /*! App supports portrait only. */
    SWRVE_ORIENTATION_PORTRAIT = 1,
    
    /*! App supports both landscape and portrait. */
    SWRVE_ORIENTATION_BOTH = 3
};
