//
//  ZLCollectionCell.m
//  多选相册照片
//
//  Created by long on 15/11/25.
//  Copyright © 2015年 long. All rights reserved.
//

#import "ZLCollectionCell.h"
#import "ZLPhotoModel.h"
#import "ZLPhotoManager.h"
#import "ZLDefine.h"
#import "ToastUtils.h"

@implementation ZLCollectionCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.btnSelect.frame = CGRectMake(GetViewWidth(self.contentView)-26, 5, 23, 23);
//    self.topView.frame = self.bounds;
    self.videoBottomView.frame = CGRectMake(0, GetViewHeight(self)-15, GetViewWidth(self), 15);
    self.videoImageView.frame = CGRectMake(5, 1, 16, 12);
    self.timeLabel.frame = CGRectMake(30, 1, GetViewWidth(self)-35, 12);
    [self.contentView sendSubviewToBack:self.imageView];
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UIButton *)btnSelect
{
    if (!_btnSelect) {
        _btnSelect = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnSelect setBackgroundImage:GetImageWithName(@"btn_unselected.png") forState:UIControlStateNormal];
        [_btnSelect setBackgroundImage:GetImageWithName(@"btn_selected.png") forState:UIControlStateSelected];
        [_btnSelect addTarget:self action:@selector(btnSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.btnSelect];
    }
    return _btnSelect;
}

- (UIImageView *)videoBottomView
{
    if (!_videoBottomView) {
        _videoBottomView = [[UIImageView alloc] initWithImage:GetImageWithName(@"videoView")];
        [_videoBottomView addSubview:self.videoImageView];
        [_videoBottomView addSubview:self.timeLabel];
        [self.contentView addSubview:_videoBottomView];
    }
    return _videoBottomView;
}

- (UIImageView *)videoImageView
{
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc] init];
        _videoImageView.image = GetImageWithName(@"video");
    }
    return _videoImageView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.font = [UIFont systemFontOfSize:13];
        _timeLabel.textColor = [UIColor whiteColor];
    }
    return _timeLabel;
}

//- (UIView *)topView
//{
//    if (!_topView) {
//        _topView = [[UIView alloc] init];
//        _topView.backgroundColor = [UIColor whiteColor];
//        _topView.alpha = 0.5;
//        _topView.userInteractionEnabled = NO;
//        _topView.hidden = YES;
//        [self.contentView addSubview:_topView];
//        [self.contentView bringSubviewToFront:_topView];
//    }
//    return _topView;
//}

- (void)setModel:(ZLPhotoModel *)model
{
    _model = model;
    
    if (self.cornerRadio > .0) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = self.cornerRadio;
    }
    
    if (model.type == ZLAssetMediaTypeVideo) {
        self.btnSelect.hidden = YES;
        self.videoBottomView.hidden = NO;
        self.videoImageView.hidden = NO;
        self.timeLabel.hidden = NO;
        self.timeLabel.text = model.duration;
//        if (self.isSelectedImage) {
//            self.topView.hidden = !self.isSelectedImage();
//        }
    } else if (model.type == ZLAssetMediaTypeGif) {
        self.btnSelect.hidden = self.allSelectGif?:!self.showSelectBtn;
        self.videoBottomView.hidden = !self.allSelectGif;
        self.videoImageView.hidden = YES;
        self.timeLabel.hidden = NO;
        self.timeLabel.text = @"GIF";
//        if (self.allSelectGif && self.isSelectedImage) {
//            self.topView.hidden = self.allSelectGif && !self.isSelectedImage();
//        }
    } else {
        self.btnSelect.hidden = !self.showSelectBtn;
        self.videoBottomView.hidden = YES;
//        self.topView.hidden = YES;
    }
    
    self.btnSelect.selected = model.isSelected;
    
    CGSize size;
    size.width = GetViewWidth(self) * 2.5;
    size.height = GetViewHeight(self) * 2.5;
    
    weakify(self);
    [ZLPhotoManager requestImageForAsset:model.asset size:size completion:^(UIImage *image, NSDictionary *info) {
        strongify(weakSelf);
        strongSelf.imageView.image = image;
    }];
}

- (void)btnSelectClick:(UIButton *)sender {
    if (!self.btnSelect.selected) {
        [self.btnSelect.layer addAnimation:GetBtnStatusChangedAnimation() forKey:nil];
    }
    if (self.selectedBlock) {
        self.selectedBlock(self.btnSelect.selected);
    }
}

@end


//////////////////////////////////////
@import AVFoundation;

@interface ZLTakePhotoCell ()

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutPut;

@end

@implementation ZLTakePhotoCell

- (void)dealloc
{
    [self.session stopRunning];
    self.session = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithImage:GetImageWithName(@"takePhoto")];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat width = GetViewHeight(self)/3;
        self.imageView.frame = CGRectMake(0, 0, width, width);
        self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [self addSubview:self.imageView];
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
    return self;
}

- (void)startCapture
{
    if (self.session && [self.session isRunning]) {
        return;
    }
    [self.session stopRunning];
    [self.session removeInput:self.videoInput];
    [self.session removeOutput:self.stillImageOutPut];
    self.session = nil;
    
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self backCamera] error:nil];
    self.stillImageOutPut = [[AVCaptureStillImageOutput alloc] init];
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    NSDictionary *dicOutputSetting = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [self.stillImageOutPut setOutputSettings:dicOutputSetting];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutPut]) {
        [self.session addOutput:self.stillImageOutPut];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.contentView.layer setMasksToBounds:YES];
    
    previewLayer.frame = self.contentView.layer.bounds;
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.contentView.layer insertSublayer:previewLayer atIndex:0];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
    });
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

@end

