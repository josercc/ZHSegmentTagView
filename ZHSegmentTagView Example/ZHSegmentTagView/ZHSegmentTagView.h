//
//  ZHSegmentTagView.h
//
//  Created by 张行 on 16/4/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZHSegmentTagView;

/**
 ZHSegmentTagView 数据源
 */
@protocol ZHSegmentTagViewDataSource <NSObject>
@required
/**
 获取显示的标题的数组

 @param segmentTagView ZHSegmentTagView
 @return NSArray<NSString *>
 */
- (NSArray<NSString *> *)segmentTagViewTagNames:(ZHSegmentTagView *)segmentTagView;

@end

/**
 ZHSegmentTagView 代理时间
 */
@protocol ZHSegmentTagViewDelegate <NSObject>
@optional

/**
 点击对应的栏目的索引

 @param segmentTagView ZHSegmentTagView
 @param index 点击的索引
 */
- (void)segmentTagView:(ZHSegmentTagView *)segmentTagView
      didSelectAtIndex:(NSUInteger)index;

/**
 栏目已经切换的代理

 @param segmentView ZHSegmentTagView
 @param index 切换的索引位置
 */
- (void)segmentIndexChangedWithView:(ZHSegmentTagView *)segmentView
                            atIndex:(NSUInteger)index;

@end


/*
     栏目1  栏目2  栏目3  栏目4
     ————
 */

/**
 切换导航栏目的控件
 */
@interface ZHSegmentTagView : UIView

/**
 栏目的名称数组
 */
@property (nonatomic, strong, readonly) NSArray<NSString *> *tagNames;
/**
 导航栏的滚动试图
 */
@property (nonatomic, strong, readonly) UIScrollView *segmentScrollView;
/**
 导航栏的按钮数组
 */
@property (nonatomic, strong, readonly) NSMutableArray<UIButton *> *segmentTagButtons;
/**
 代理
 */
@property (nonatomic, weak, nullable) id <ZHSegmentTagViewDelegate> delegate;
/**
 数据源
 */
@property (nonatomic, weak, nullable) id <ZHSegmentTagViewDataSource> dataSource;
/**
 当前所在的索引
 */
@property (nonatomic, assign) NSUInteger currentIndex;

/**
 是否展示最下面的线 默认为 NO
 */
@property (nonatomic, assign, getter=isShowBottomLine) BOOL showBottomLine;

/**
 下面的线试图 可以自定义
 */
@property (nonatomic, strong, readonly) UIView *bottomLineView;

/**
    标题之间的距离
 */
@property (nonatomic, assign) CGFloat segmentTitleSpace;
/*!
 *  @brief 是否显示下面进度线
 */
@property (nonatomic, assign) BOOL showIndexLine;
@property (nonatomic, assign) BOOL showSelectColor;

/**
 重新刷新数据
 */
- (void)reloadSegmentTagView;
/**
 滑动到指定的位置

 @param index 指定的位置
 */
- (void)scrollToIndex:(NSInteger)index __deprecated_msg("请替换为-(void)scroolToIndex:(NSInteger)index animation:(BOOL)animation");

/**
 滑动到指定的位置

 @param index 指定的位置
 @param animation 是否有动画
 */
- (void)scrollToIndex:(NSInteger)index
            animation:(BOOL)animation;

@end

NS_ASSUME_NONNULL_END
