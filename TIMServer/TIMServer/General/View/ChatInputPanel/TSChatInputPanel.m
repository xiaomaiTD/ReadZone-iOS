//
//  TSChatInputPanel.m
//  TIMServer
//
//  Created by 谢立颖 on 2018/11/21.
//  Copyright © 2018 Viomi. All rights reserved.
//

#import "TSChatInputPanel.h"

@implementation TSChatInputPanel

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.KVOController unobserveAll];
}

- (instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardDidShow:) name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    return self;
}

- (instancetype)initRichChatInputPanel
{
    if (self = [self init])
    {
        
        [self.KVOController unobserve:_toolBar keyPath:@"contentHeight"];
        [_toolBar removeFromSuperview];
        
        _toolBar = [[TSRichChatInputToolBar alloc] init];
        _toolBar.toolBarDelegate = self;
        [self addSubview:_toolBar];
        
        __weak TSChatInputPanel *ws = self;
        [self.KVOController observe:_toolBar keyPath:@"contentHeight" options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionOld block:^(id observer, id object, NSDictionary *change) {
            [ws onToolBarContentHeightChanged:change];
        }];
    }
    return self;
}

- (void)setInputText:(NSString *)text
{
    [_toolBar setInputText:text];
}

- (void)setChatDelegate:(id<TSChatInputAbleViewDelegate>)delegate
{
    _chatDelegate = delegate;
    _toolBar.chatDelegate = delegate;
}

- (void)onKeyboardWillHide:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    NSInteger contentHeight = [_toolBar contentHeight] + [_panel contentHeight];
    
    if (_contentHeight != contentHeight)
    {
        CGRect rect = self.frame;
        CGFloat navHeight = kIsiPhoneX ? 88 : 64;
        rect.origin.y = kScreenHeight - navHeight - contentHeight;
        rect.size.height = contentHeight;
        
        [UIView animateWithDuration:duration animations:^{
            self.frame = rect;
            self.contentHeight = contentHeight;
        } completion:^(BOOL finished) {
            self.frame = rect;
            self.contentHeight = contentHeight;
        }];
    }
}


- (void)onKeyboardDidShow:(NSNotification *)notification
{
    if ([_toolBar isEditing])
    {
        NSDictionary *userInfo = notification.userInfo;
        CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        NSInteger contentHeight = endFrame.size.height + [_toolBar contentHeight];
        if (contentHeight != _contentHeight)
        {
            CGRect rect = self.frame;
            CGFloat navHeight = kIsiPhoneX ? 88 : 64;
            rect.origin.y = endFrame.origin.y - [_toolBar contentHeight] - navHeight;
            if (kIsiPhoneX) {
                rect.origin.y = endFrame.origin.y - [_toolBar contentHeight] - navHeight + 34;
            }
            rect.size.height = contentHeight;
            
            [UIView animateWithDuration:duration animations:^{
                self.frame = rect;
                self.contentHeight = contentHeight;
            } completion:^(BOOL finished) {
                self.frame = rect;
                self.contentHeight = contentHeight;
            }];
        }
    }
    
}

- (void)addOwnViews
{
    _toolBar = [[TSChatInputToolBar alloc] init];
    _toolBar.toolBarDelegate = self;
    [self addSubview:_toolBar];
    
    self.KVOController = [FBKVOController controllerWithObserver:self];
    __weak TSChatInputPanel *ws = self;
    [self.KVOController observe:_toolBar keyPath:@"contentHeight" options:NSKeyValueObservingOptionNew |NSKeyValueObservingOptionOld block:^(id observer, id object, NSDictionary *change) {
        [ws onToolBarContentHeightChanged:change];
    }];
}

- (void)onToolBarContentHeightChanged:(NSDictionary *)change
{
    NSInteger nv = [change[NSKeyValueChangeNewKey] integerValue];
    NSInteger ov = [change[NSKeyValueChangeOldKey] integerValue];
    if (nv != ov)
    {
        NSInteger off = nv - ov;
        CGRect rect = self.frame;
        rect.origin.y -= off;
        rect.size.height += off;
        
        self.frame = rect;
        [UIView animateWithDuration:0.25 animations:^{
            self.contentHeight = self->_contentHeight + off;
        }];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self relayoutFrameOfSubViews];
}

- (void)relayoutFrameOfSubViews
{
    CGRect rect = self.bounds;
    [_toolBar sizeWith:CGSizeMake(rect.size.width, _toolBar.contentHeight)];
    [_toolBar relayoutFrameOfSubViews];
    
    [_panel setFrameAndLayout:CGRectMake(0, _toolBar.contentHeight, rect.size.width, rect.size.height - _toolBar.contentHeight)];
}

- (BOOL)resignFirstResponder
{
    [_toolBar resignFirstResponder];
    [self onHideAddtionalPanel:_panel completion:^{
        [self onSwitchPanel];
    }];
    return [super resignFirstResponder];
}

- (void)onSwitchPanel
{
    if (_panel)
    {
        [_panel removeFromSuperview];
    }
    
    _panel = nil;
}

#pragma mark -

- (void)onToolBarClickPhoto:(TSChatInputToolBar *)bar show:(BOOL)isShow
{
    if (isShow)
    {
        if (!_emojPanel)
        {
//            ChatEmojView *emojPanel = [[ChatEmojView alloc] init];
//            emojPanel.chatDelegate = self.chatDelegate;
//            emojPanel.delegate = _toolBar;
//            _emojPanel = emojPanel;
        }
        
        [self onShowPanel:_emojPanel];
    }
    else
    {
        [self onHideAddtionalPanel:_panel completion:^{
            [self onSwitchPanel];
        }];
    }
}

- (void)onShowPanel:(UIView<TSChatInputAbleView> *)panel
{
    NSInteger oldPanelContentHeight = [_panel contentHeight];
    [self onSwitchPanel];
    
    NSInteger contentHeight = [panel contentHeight];
    [panel setFrameAndLayout:CGRectMake(0, 0, self.bounds.size.width, contentHeight)];
    [self addSubview:panel];
    _panel = panel;
    
    [self onShowAddtionalPanel:panel withOff:contentHeight - oldPanelContentHeight];
}

- (void)onToolBarClickMovie:(TSChatInputToolBar *)bar show:(BOOL)isShow
{
    if (isShow)
    {
        if (!_funcPanel)
        {
//            _funcPanel = [[TSChatFunctionPanel alloc] init];
//            _funcPanel.chatDelegate = self.chatDelegate;
        }
        
//        [self onShowPanel:_funcPanel];
    }
    else
    {
        [self onHideAddtionalPanel:_panel completion:^{
            [self onSwitchPanel];
        }];
    }
    
}

- (void)onShowAddtionalPanel:(UIView<TSChatInputAbleView> *)panel withOff:(NSInteger)offer
{
    if (offer == 0)
    {
        // 说明没有切换
        return;
    }
    
    CGRect rect = self.frame;
    rect.origin.y -= offer;
    rect.size.height += offer;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = rect;
        self.contentHeight += offer;
    }];
    
    
}

- (void)onHideAddtionalPanel:(UIView<TSChatInputAbleView> *)panel completion:(CommonVoidBlock)block
{
    NSInteger contentHeight = [panel contentHeight];
    CGRect rect = self.frame;
    rect.origin.y += contentHeight;
    rect.size.height -= contentHeight;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = rect;
        self.contentHeight -= contentHeight;
    } completion:^(BOOL finished) {
        if (block)
        {
            block();
        }
    }];
}

- (TSIMMsg *)getMsgDraft
{
    return [(TSRichChatInputToolBar *)_toolBar getMsgDraft];
}

- (void)setMsgDraft:(TSIMMsg *)draft
{
    [(TSRichChatInputToolBar *)_toolBar setMsgDraft:draft];
}

@end

@implementation TSRichChatInputPanel

- (void)onToolBarClickPhoto:(TSChatInputToolBar *)bar show:(BOOL)isShow
{
//    if (isShow)
//    {
//        if (!_emojPanel)
//        {
//            ChatSystemFaceView *emojPanel = [[ChatSystemFaceView alloc] init];
//            emojPanel.chatDelegate = self.chatDelegate;
//            emojPanel.inputDelegate = _toolBar;
//            _emojPanel = emojPanel;
//        }
//
//        [self onShowPanel:_emojPanel];
//    }
//    else
//    {
//        [self onHideAddtionalPanel:_panel completion:^{
//            [self onSwitchPanel];
//        }];
//    }
}

@end