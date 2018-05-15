//
//  ZHSegmentTagView.m
//
//  Created by 张行 on 16/4/7.
//

#import <Masonry/Masonry.h>
#import "ZHSegmentTagView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 默认没有选中文本的颜色

 @return UIColor
 */
#define SegmentNomarlTextColor [UIColor colorWithRed:0.200 green:0.200 blue:0.200 alpha:1.00] 
/**
 选中文本的颜色

 @return UIColor
 */
#define SegmentSelectedTextColor [UIColor colorWithRed:1.000 green:0.400 blue:0.149 alpha:1.00]



static CGFloat const kSOASegmentSelectedLineViewHeight = 2; ///> 选中下标线的高度
static CGFloat const KSOASegmentTitleButtonSpace = 25.0; ///> Title 之间的间距

@interface ZHSegmentTagView()

/**
    栏目的名称数组
 */
@property (nonatomic, strong) NSArray<NSString *> *tagNames;
/**
    导航栏的滚动试图
 */
@property (nonatomic, strong) UIScrollView *segmentScrollView;
/**
    导航栏的按钮数组
 */
@property (nonatomic, strong) NSMutableArray<UIButton *> *segmentTagButtons;
/**
    下面的线试图 可以自定义
 */
@property (nonatomic, strong) UIView *bottomLineView;
/**
    选中下面的线
 */
@property (nonatomic, strong) UIView *lineView;
/**
    储存标题的宽度
 */
@property (nonatomic, strong) NSMutableArray *titleWidths;
/**
    底部线的约束
 */
@property (nonatomic, strong) MASConstraint *bottomLineWithHeightConstraint;

@end

@implementation ZHSegmentTagView {
    CGFloat _minLineWidth;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _showBottomLine = NO;
        _segmentTitleSpace = KSOASegmentTitleButtonSpace;
        _minLineWidth = 1.0 / [UIScreen mainScreen].scale;
    }
    return self;
}

#pragma mark - Public Function
/**
 已经添加到父试图 进行自动刷新试图
 */
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self reloadSegmentTagView];
}
/**
 刷新试图
 */
- (void)reloadSegmentTagView {
    /*!
     * 上一次选中的标签名称 为了防止 当删除其中一个标签 导致索引会越界 对应不准确的问题
     */
    NSString *oldTagName;
    if (self.tagNames.count > self.currentIndex) {
       oldTagName = self.tagNames[self.currentIndex];
    }else {
        self.currentIndex = 0;
    }
    /*!
     * 重新获取最新的数据源
     */
    self.tagNames = [self.dataSource segmentTagViewTagNames:self]; /// 获取数据源
    for (int i = 0; i < self.tagNames.count; i ++) {
        /*!
         * 查找之前选择的在最新数据源的位置 如果查找不到就回到最初的位置
         */
        if (oldTagName && [oldTagName isEqualToString:self.tagNames[i]]) {
            self.currentIndex = i;
        }
    }
    /*!
     * 如果不存在数据源就隐藏这个试图
     */
    self.hidden = self.tagNames.count == 0; /// 如果数据源不存在就隐藏
    if (self.tagNames.count > 0) {
        /// 只有数据源存在才会绘制试图
        [self drawInitView];
    }
}

/**
 滚动到指定的位置

 @param index 指定的位置
 */
- (void)scrollToIndex:(NSInteger)index {
    [self scrollToIndex:index animation:YES];
}

- (void)scrollToIndex:(NSInteger)index
            animation:(BOOL)animation {
    [self changeStatueAtIndex:index
                    animation:animation]; /// 改变选中的状态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(animation ? 0.25 : 0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
            /// 0.25秒动画之后 去通知外面的接受者
        if (self.delegate && [self.delegate respondsToSelector:@selector(segmentIndexChangedWithView:atIndex:)]) {
            [self.delegate segmentIndexChangedWithView:self
                                               atIndex:index];
        }
        [self scrollToCenterWithIndex:index]; /// 让当前选中的位置滚动到试图的中心
    });
    self.currentIndex = index; /// 设置当前的位置 为指定的位置
}

#pragma mark - Privte Function
/**
 绘制试图
 */
- (void)drawInitView {
    self.backgroundColor = [UIColor whiteColor]; /// 设置背景颜色为白色
    // 背景滑动
    [self addSubview:self.segmentScrollView];
    [self.segmentScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    // segmentTagButtons
    if (self.segmentTagButtons.count > 0) {
        /// 如果是已经初始化 刷新就移除之前的按钮
        [self.segmentTagButtons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj,
                                                             NSUInteger idx,
                                                             BOOL * _Nonnull stop) {
            [obj removeConstraints:obj.constraints];
            [obj removeFromSuperview];
        }];
        [self.segmentTagButtons removeAllObjects];
    }
    
    // 清除
    [self.titleWidths removeAllObjects];
    [self.lineView removeFromSuperview];
    
    // 背景图
    UIView *backgroundView = [self.segmentScrollView viewWithTag:100]; // 获取滚动试图约束试图
    if (!backgroundView) {
        /// 如果约束的试图不存在就创建
        backgroundView = [[UIView alloc]init];
        backgroundView.tag = 100;
        [self.segmentScrollView addSubview:backgroundView];
    }
    [backgroundView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.segmentScrollView);
        make.height.equalTo(self.segmentScrollView);
    }];
    
    // 标题
    UIButton *firstButton;
    for (NSInteger i = 0; i < self.tagNames.count; i++) {
        UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [titleButton setTitle:self.tagNames[i]
                     forState:UIControlStateNormal] ;
        [titleButton setTitleColor:SegmentNomarlTextColor
                          forState:UIControlStateNormal];
        titleButton.titleLabel.font = [UIFont systemFontOfSize:14];
        titleButton.titleLabel.backgroundColor = self.backgroundColor;
        [titleButton sizeToFit];
        [self.titleWidths addObject:@(CGRectGetWidth(titleButton.frame))];
        [titleButton addTarget:self
                        action:@selector(buttonClick:)
              forControlEvents:UIControlEventTouchUpInside];
        titleButton.tag = i;
        [backgroundView addSubview:titleButton];

        [titleButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(backgroundView);
            if (!firstButton) {
                make.leading.equalTo(backgroundView).offset(self.segmentTitleSpace/2.0);
            }else {
                make.leading.equalTo(firstButton.mas_trailing).offset(self.segmentTitleSpace);
            }
        }];
        firstButton = titleButton;
        [self.segmentTagButtons addObject:titleButton];
    }
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(firstButton.mas_trailing).offset(self.segmentTitleSpace/2.0);
    }];
    UIButton *lasterShowButton = self.segmentTagButtons[self.currentIndex];
    [lasterShowButton setTitleColor:SegmentSelectedTextColor forState:UIControlStateNormal];
    
    // 滑动的线
    [backgroundView addSubview:self.lineView];
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.width.mas_equalTo([self.titleWidths[self.currentIndex] floatValue]);
        make.height.mas_equalTo(kSOASegmentSelectedLineViewHeight);
        make.centerX.equalTo(lasterShowButton.mas_centerX);
    }];

    [self addSubview:self.bottomLineView];
    CGFloat bottomLineViewHeight = self.showBottomLine ? _minLineWidth : 0;
    [self.bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        self.bottomLineWithHeightConstraint = make.height.mas_equalTo(bottomLineViewHeight);
    }];
}

- (void)buttonClick:(UIButton *)button {
    // 如果是当前 Index，不需要动
    if (button.tag  == self.currentIndex) {
        return;
    }
    [self changeStatueAtIndex:button.tag
                    animation:YES];
    [self scrollToCenterWithIndex:button.tag];
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentTagView:didSelectAtIndex:)]) {
        [self.delegate segmentTagView:self
                     didSelectAtIndex:button.tag];
    }
}


/**
 滚动指定的位置到试图的中心
 
 @param index 指定的位置
 */
- (void)scrollToCenterWithIndex:(NSInteger)index {
    if (self.segmentTagButtons.count < 1) {
        return;
    }
    UIButton *titleButton = self.segmentTagButtons[index]; /// 获取指定位置的按钮
    CGPoint currentPoint = [titleButton convertPoint:CGPointMake(0, 0) toView:self]; /// 获取按钮所在的位置
    CGPoint centerPoint = CGPointMake(CGRectGetWidth(self.frame)/2 - [self.titleWidths[index] floatValue] / 2, 0); /// 获取中心点的位置
    CGFloat moveLenght = centerPoint.x - currentPoint.x; /// 计算要移动的距离
    CGFloat endX = self.segmentScrollView.contentOffset.x - moveLenght; /// 计算结束的x坐标
//    NSLog(@"endX == %f, contentoffsetX == %f, moveLength == %f",endX,self.segmentScrollView.contentOffset.x, moveLenght);
    if ( moveLenght > 0 && endX < 0) {
        /// 如果移动的距离大于0 代表右移动 并且超出屏幕 就要回退
        endX = 0;
    }else if (moveLenght < 0 && endX > self.segmentScrollView.contentSize.width - CGRectGetWidth(self.segmentScrollView.frame)) {
        // 如果移动位置小于零 代表左移动 并且超出屏幕 要回退
        endX = self.segmentScrollView.contentSize.width - CGRectGetWidth(self.segmentScrollView.frame);
    }
    if (endX >= 0) {
        [self.segmentScrollView setContentOffset:CGPointMake(endX, 0)
                                        animated:YES]; /// 滚动到指定的位置
    }
}

- (void)changeStatueAtIndex:(NSInteger)index
                   animation:(BOOL)animation {
    if (self.currentIndex == index) { // if last selected index is will change index nothing to do
        return;
    }
    UIButton *oldButton = self.segmentTagButtons[self.currentIndex];
    UIButton *nowButton = self.segmentTagButtons[index];
    [nowButton setTitleColor:SegmentSelectedTextColor
                    forState:UIControlStateNormal];
    [oldButton setTitleColor:SegmentNomarlTextColor
                    forState:UIControlStateNormal];
    self.currentIndex = index;
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self);
        make.width.equalTo(nowButton.titleLabel.mas_width);
        make.height.mas_equalTo(kSOASegmentSelectedLineViewHeight);
        make.centerX.equalTo(nowButton.mas_centerX);
    }];
    [UIView animateWithDuration:animation ? 0.25 : 0
                     animations:^{
                         [self.lineView layoutIfNeeded];
                     }];
}

- (void)setShowIndexLine:(BOOL)showIndexLine {
    _showIndexLine = showIndexLine;
    self.lineView.hidden = !showIndexLine;
}

- (void)setShowSelectColor:(BOOL)showSelectColor {
    _showSelectColor = showSelectColor;
    if (!showSelectColor && self.segmentTagButtons.count > 0) {
        UIButton *selectButton = self.segmentTagButtons[self.currentIndex];
        [selectButton setTitleColor:SegmentNomarlTextColor
                           forState:UIControlStateNormal];
    }
}

#pragma mark - Setter
- (void)setShowBottomLine:(BOOL)showBottomLine {
    _showBottomLine = showBottomLine;
    if (self.bottomLineWithHeightConstraint) {
        CGFloat bottomLineViewHeight = showBottomLine ? _minLineWidth : 0;
        self.bottomLineWithHeightConstraint.mas_equalTo(bottomLineViewHeight);
    }
}

#pragma mark - Getter
- (UIView *)bottomLineView {
    if (!_bottomLineView) {
        _bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomLineView.backgroundColor = [UIColor colorWithRed:0.882
                                                          green:0.882
                                                           blue:0.882
                                                          alpha:1];
    }
    return _bottomLineView;
}

- (UIScrollView *)segmentScrollView {
    if (!_segmentScrollView) {
        /// 如果滚动试图不存在就创建
        _segmentScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _segmentScrollView.showsHorizontalScrollIndicator = NO; /// 设置横向滚动条隐藏
        _segmentScrollView.scrollsToTop = NO; // 设置不允许滚动到顶部
    }
    return _segmentScrollView;
}

- (NSMutableArray<UIButton *> *)segmentTagButtons {
    if (!_segmentTagButtons) {
        /// 初始化按钮的数组
        _segmentTagButtons = [NSMutableArray array];
    }
    return _segmentTagButtons;
}

- (NSMutableArray *)titleWidths {
    if (!_titleWidths) {
        /// 如果标题的宽度数组不存在就创建
        _titleWidths = [NSMutableArray array];
    }
    return _titleWidths;
}

- (UIView *)lineView {
    if (!_lineView) {
        /// 如果选中的线不存在就创建 设置颜色为选中标题的颜色
        _lineView = [[UIView alloc]initWithFrame:CGRectZero];
        _lineView.backgroundColor = SegmentSelectedTextColor;
    }
    return _lineView;
}

@end

NS_ASSUME_NONNULL_END
