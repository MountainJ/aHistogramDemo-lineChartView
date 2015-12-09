//
//  JAYLineChart.m
//  JAYChartDemo
//
//  Created by JayZY on 14-7-24.
//  Copyright (c) 2014年 MountainJ. All rights reserved.
//

#import "JAYLineChart.h"
#import "JAYColor.h"
#import "JAYChartLabel.h"

/*
 1.需要根据正常值的范围，画出正常值的背景色； 已经给出了背景渲染
 
 2.值不在正常范围的数据点颜色进行特殊备注；
 
 3.两组曲线的时候，底部添加图线的说明；
 
 4.横轴时间的数值显示格式；
 
 */


#define kMaxXLabels 6  //单屏显示最多数据条数
#define kMinXLabelS  4  //单屏显示最少数据条数
#define kDotWH 8 //画图点的宽高

#define kYLableNumbers (5.0) //纵轴显示数值单位个数

@interface JAYLineChart ()
{
    UIScrollView *_myScrollView;
    CGFloat  _xAxisLengh;
}

@end

@implementation JAYLineChart {
    NSHashTable *_chartLabelsForX;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsToBounds = YES;
        _myScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
//        _myScrollView.backgroundColor = [UIColor orangeColor];
//        _myScrollView.contentSize = CGSizeMake(frame.size.width, 0);
        _myScrollView.contentOffset = CGPointMake(0, 0);
        [self addSubview:_myScrollView];

    }
    return self;
}

-(void)setYValues:(NSArray *)yValues
{
    _yValues = yValues;
    [self setYLabels:yValues];
}

-(void)setYLabels:(NSArray *)yLabels
{
    NSInteger max = 0;
    NSInteger min = 1000000000;

    for (NSArray * ary in yLabels) {
        for (NSString *valueString in ary) {
            NSInteger value = [valueString integerValue];
            if (value > max) {
                max = value;
            }
            if (value < min) {
                min = value;
            }
        }
    }
    if (max < 5) {
        max = 5;
    }
    if (self.showRange) {
        _yValueMin = min;
    }else{
        _yValueMin = 0;
    }
    _yValueMax = (int)max;
    
    if (_chooseRange.max!=_chooseRange.min) {
        _yValueMax = _chooseRange.max;
        _yValueMin = _chooseRange.min;
    }
   //Y轴设置5个标度
    float level = (_yValueMax-_yValueMin) /(kYLableNumbers-1);
    CGFloat chartCavanHeight = self.frame.size.height - JAYLabelHeight*3;
    CGFloat levelHeight = chartCavanHeight /(kYLableNumbers-1);
#warning 这里设置Y轴显示的数值个数
    for (int i=0; i<kYLableNumbers; i++) {
        JAYChartLabel * label = [[JAYChartLabel alloc] initWithFrame:CGRectMake(0.0,chartCavanHeight-i*levelHeight+JAYLabelHeight/2.0, JAYYLabelwidth, JAYLabelHeight)];
//        label.backgroundColor = [UIColor yellowColor];
		label.text = [NSString stringWithFormat:@"%d",(int)(level * i+_yValueMin)];
		[self addSubview:label];
    }
#pragma mark -这里设置正常范围需要突出的背景色
//    if ([super respondsToSelector:@selector(setMarkRange:)]) {
//        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, (1-(_markRange.max-_yValueMin)/(_yValueMax-_yValueMin))*chartCavanHeight+JAYLabelHeight,_xAxisLengh, (_markRange.max-_markRange.min)/(_yValueMax-_yValueMin)*chartCavanHeight)];
//        view.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.1];
//        [_myScrollView addSubview:view];
//    }
    if ([super respondsToSelector:@selector(setGroupMarkRange:)]) {
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, (1-(_groupMarkRange.range1.max-_yValueMin)/(_yValueMax-_yValueMin))*chartCavanHeight+JAYLabelHeight,_xAxisLengh, (_groupMarkRange.range1.max-_groupMarkRange.range1.min)/(_yValueMax-_yValueMin)*chartCavanHeight)];
        
        view.backgroundColor = [_colors[0] colorWithAlphaComponent:0.4];
        [_myScrollView addSubview:view];
        //
        UIView *view2 = [[UIView alloc]initWithFrame:CGRectMake(0, (1-(_groupMarkRange.range2.max-_yValueMin)/(_yValueMax-_yValueMin))*chartCavanHeight+JAYLabelHeight,_xAxisLengh, (_groupMarkRange.range2.max-_groupMarkRange.range2.min)/(_yValueMax-_yValueMin)*chartCavanHeight)];
        view2.backgroundColor = [_colors[1] colorWithAlphaComponent:0.4];
        [_myScrollView addSubview:view2];
    }
    //画横线
    for (int i=0; i<kYLableNumbers; i++) {
        if ([_ShowHorizonLine[i] integerValue]>0) {
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(JAYYLabelwidth,JAYLabelHeight+i*levelHeight)];
            [path addLineToPoint:CGPointMake(self.frame.size.width,JAYLabelHeight+i*levelHeight)];
            [path closePath];
            shapeLayer.path = path.CGPath;
            shapeLayer.strokeColor = [[[UIColor blackColor] colorWithAlphaComponent:0.8] CGColor];
            shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
            shapeLayer.lineWidth = 0.1;
            [self.layer addSublayer:shapeLayer];
        }
    }
}

-(void)setXLabels:(NSArray *)xLabels
{
    if( !_chartLabelsForX ){
        _chartLabelsForX = [NSHashTable weakObjectsHashTable];
    }
    _xLabels = xLabels;
    CGFloat num = 0;
    if (xLabels.count>=kMaxXLabels) {
        num=kMaxXLabels;
    }else if (xLabels.count<=kMinXLabelS){
        num=kMinXLabelS;
    }else{
        num = xLabels.count;
    }
    _xLabelWidth = (self.frame.size.width - JAYYLabelwidth)/num;
    _xAxisLengh = _xLabelWidth *(xLabels.count+1)+chartMargin;
    //横坐标
    for (int i=0; i<xLabels.count; i++) {
        NSString *labelText = xLabels[i];
        JAYChartLabel * label = [[JAYChartLabel alloc] initWithFrame:CGRectMake(i * _xLabelWidth+JAYYLabelwidth, self.frame.size.height - JAYLabelHeight, _xLabelWidth, JAYLabelHeight)];
        label.text = labelText;
        [_myScrollView addSubview:label];
        [_chartLabelsForX addObject:label];
    }
    float max = (([xLabels count])*_xLabelWidth + chartMargin)+_xLabelWidth;
    if (_myScrollView.frame.size.width < max-kMaxXLabels) {
        _myScrollView.contentSize = CGSizeMake(max, self.frame.size.height);
    }
    //画竖线
    for (int i=1; i<xLabels.count+1; i++) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(i*_xLabelWidth+kDotWH,JAYLabelHeight)];
        [path addLineToPoint:CGPointMake(i*_xLabelWidth+kDotWH,self.frame.size.height-2*JAYLabelHeight)];
        [path closePath];
        shapeLayer.path = path.CGPath;
        shapeLayer.strokeColor = [[[UIColor blackColor] colorWithAlphaComponent:0.4] CGColor];
        shapeLayer.fillColor = [[UIColor whiteColor] CGColor];
        shapeLayer.lineWidth = 0.4;
        [_myScrollView.layer addSublayer:shapeLayer];
    }
}

-(void)setColors:(NSArray *)colors
{
	_colors = colors;
}

- (void)setMarkRange:(CGRange)markRange
{
    _markRange = markRange;
    //
}

- (void)setGroupMarkRange:(JAYGroupRange)groupMarkRange
{
    _groupMarkRange = groupMarkRange;
}

- (void)setChooseRange:(CGRange)chooseRange
{
    _chooseRange = chooseRange;
}

- (void)setShowHorizonLine:(NSMutableArray *)ShowHorizonLine
{
    _ShowHorizonLine = ShowHorizonLine;
}

#pragma mark -  描点
-(void)strokeChart
{
    for (int i=0; i<_yValues.count; i++) {
        NSArray *childAry = _yValues[i];
        if (childAry.count==0) {
            return;
        }
        NSInteger max_i =0;
        NSInteger min_i =0;
        //获取最大最小位置
        CGFloat max = [childAry[0] floatValue];
        CGFloat min = [childAry[0] floatValue];
    
        for (int j=0; j<childAry.count; j++){
            CGFloat num = [childAry[j] floatValue];
            if (max<=num){
                max = num;
                max_i = j;
            }
            if (min>=num){
                min = num;
                min_i = j;
            }
        }
        
        //划线
        CAShapeLayer *_chartLine = [CAShapeLayer layer];
        _chartLine.lineCap = kCALineCapRound;
        _chartLine.lineJoin = kCALineJoinBevel;
        _chartLine.fillColor   = [[UIColor whiteColor] CGColor];
        _chartLine.lineWidth   = 2.0;
        _chartLine.strokeEnd   = 0.0;
        [_myScrollView.layer addSublayer:_chartLine];
        
        UIBezierPath *progressline = [UIBezierPath bezierPath];
        CGFloat firstValue = [[childAry objectAtIndex:0] floatValue];
        CGFloat xPosition = (JAYYLabelwidth + _xLabelWidth/2.0);
        CGFloat chartCavanHeight = self.frame.size.height - JAYLabelHeight*3;
        
        float grade = ((float)firstValue-_yValueMin) / ((float)_yValueMax-_yValueMin);
       
        //第一个点
        BOOL isShowMaxAndMinPoint = YES;
        if (self.ShowMaxMinArray) {
            if ([self.ShowMaxMinArray[i] intValue]>0) {
                isShowMaxAndMinPoint = (max_i==0 || min_i==0)?NO:YES;
            }else{
                isShowMaxAndMinPoint = YES;
            }
        }
        [self addPoint:CGPointMake(xPosition, chartCavanHeight - grade * chartCavanHeight+JAYLabelHeight)
                 index:i
                isShow:self.showTextValue
                 value:firstValue];

        
        [progressline moveToPoint:CGPointMake(xPosition, chartCavanHeight - grade * chartCavanHeight+JAYLabelHeight)];
        [progressline setLineWidth:2.0];
        [progressline setLineCapStyle:kCGLineCapRound];
        [progressline setLineJoinStyle:kCGLineJoinRound];
        NSInteger index = 0;
        for (NSString * valueString in childAry)
        {
            float grade =([valueString floatValue]-_yValueMin) / ((float)_yValueMax-_yValueMin);
            if (index != 0) {
                CGPoint point = CGPointMake(xPosition+index*_xLabelWidth, chartCavanHeight - grade * chartCavanHeight+JAYLabelHeight);
                [progressline addLineToPoint:point];
                
                BOOL isShowMaxAndMinPoint = YES;
                
                if (self.ShowMaxMinArray) {
                    if ([self.ShowMaxMinArray[i] intValue]>0) {
                        isShowMaxAndMinPoint = (max_i==index || min_i==index)?NO:YES;
                    }else{
                        isShowMaxAndMinPoint = YES;
                    }
                }
                [progressline moveToPoint:point];
                [self addPoint:point
                         index:i
                        isShow:self.showTextValue
                         value:[valueString floatValue]];
                
            }
            index += 1;
        }
        
        _chartLine.path = progressline.CGPath;
        if ([[_colors objectAtIndex:i] CGColor]) {
            _chartLine.strokeColor = [[_colors objectAtIndex:i] CGColor];
        }else{
            _chartLine.strokeColor = [JAYGreen CGColor];
        }
        //添加数据图线绘画效果
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = childAry.count*0.2;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
        pathAnimation.autoreverses = NO;
        [_chartLine addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        _chartLine.strokeEnd = 1.0;
    }
}

- (void)addPoint:(CGPoint)point index:(NSInteger)index isShow:(BOOL)isHollow value:(CGFloat)value
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kDotWH, kDotWH)];
    view.center = point;
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = 4;
    view.layer.borderWidth = 2;
    view.layer.borderColor = [[_colors objectAtIndex:index] CGColor]?[[_colors objectAtIndex:index] CGColor]:JAYGreen.CGColor;
    view.backgroundColor = [UIColor whiteColor];
     [_myScrollView addSubview:view];
    // 数值的显示
    if (isHollow) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(point.x-JAYTagLabelwidth/2.0, point.y-JAYLabelHeight*1.5, JAYTagLabelwidth, JAYLabelHeight)];
        label.font = [UIFont systemFontOfSize:10];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor =  [_colors objectAtIndex:index]?[_colors objectAtIndex:index] :JAYGreen;
        label.text = [NSString stringWithFormat:@"%d",(int)value];
        [_myScrollView addSubview:label];
        //异常点的标识
        if (value < _markRange.min ||value > _markRange.max) {
            view.backgroundColor = [UIColor redColor];
            view.layer.borderColor = [UIColor redColor].CGColor;
            label.textColor = [UIColor redColor];
            
        }
    }
    
    
}

- (NSArray *)chartLabelsForX
{
    return [_chartLabelsForX allObjects];
}

@end
