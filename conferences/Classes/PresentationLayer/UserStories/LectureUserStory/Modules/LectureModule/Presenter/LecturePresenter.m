// Copyright (c) 2016 RAMBLER&Co
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LecturePresenter.h"
#import "LectureViewInput.h"
#import "LectureInteractorInput.h"
#import "LectureRouterInput.h"
#import "LecturePresenterStateStorage.h"
#import "LectureMaterialPlainObject.h"
#import "LecturePlainObject.h"
#import "SpeakerPlainObject.h"

@implementation LecturePresenter

#pragma mark - LectureModuleInput

- (void)configureCurrentModuleWithLectureObjectId:(NSString *)objectId {
    self.stateStorage.lectureObjectId = objectId;
}

#pragma mark - LectureViewOutput

- (void)setupView {
    [self updateViewWithCurrentLecture];
    [self.view setupViewInitialState];
}

- (void)didTapVideoPreviewWithVideoMaterial:(LectureMaterialPlainObject *)videoMaterial {
    BOOL isVideoCached = [[NSFileManager defaultManager] fileExistsAtPath:videoMaterial.localURL];
    if (isVideoCached) {
        [self.router openLocalVideoPlayerModuleWithPath:videoMaterial.localURL];
        return;
    }
    
    NSURL *videoUrl = [NSURL URLWithString:videoMaterial.link];
    BOOL isYouTube = [self.interactor checkIfVideoIsFromYouTube:videoUrl];
    if (isYouTube) {
        NSString *videoIdentifier = [self.interactor deriveVideoIdFromYouTubeUrl:videoUrl];
        [self.router openYouTubeVideoPlayerModuleWithIdentifier:videoIdentifier];
    } else {
        [self.router openWebBrowserModuleWithUrl:videoUrl];
    }
}

- (void)didTapMaterialWithUrl:(NSURL *)materialUrl {
    [self.router openWebBrowserModuleWithUrl:materialUrl];
}

- (void)didTapSpeakerWithId:(NSString *)speakerId {
    [self.router openSpeakerInfoModuleWithSpeakerObjectId:self.stateStorage.speakerObjectId];
}

- (void)didTapShareButton {
    LecturePlainObject *lecture = [self.interactor obtainLectureWithObjectId:self.stateStorage.lectureObjectId];
    NSArray *activitiyItems = [self.interactor obtainActivityItemsForLecture:lecture];
    
    [self.router openShareModuleWithActivityItems:activitiyItems];
}

#pragma mark - LectureMaterialCacheDelegate

- (void)didTapRemoveFromCacheLectureMaterial:(LectureMaterialPlainObject *)lectureMaterial {
    __block NSError *error;
    ActionAlertBlock actionAlertBlock = ^{
        [self.interactor removeVideoFromCacheWithLectureMaterial:lectureMaterial
                                                           error:&error];
        [self updateViewWithCurrentLecture];

    };
    [self.router showAlertConfirmationRemoveWithActionBlock:actionAlertBlock];
}

- (void)didTapDownloadToCacheLectureMaterial:(LectureMaterialPlainObject *)lectureMaterial {
    ActionAlertBlock actionAlertBlock = ^{
        [self.interactor downloadVideoToCacheWithLectureMaterial:lectureMaterial];
        [self updateViewWithCurrentLecture];
    };
    [self.router showAlertConfirmationDownloadWithActionBlock:actionAlertBlock];
}

- (void)didTriggerEndDownloadingLectureMaterial:(LectureMaterialPlainObject *)lectureMaterial {
    [self updateViewWithCurrentLecture];
    
}

- (void)updateViewWithCurrentLecture {
    LecturePlainObject *lecture = [self.interactor obtainLectureWithObjectId:self.stateStorage.lectureObjectId];
    SpeakerPlainObject *speaker = lecture.speaker;
    self.stateStorage.speakerObjectId = speaker.speakerId;
    [self.view updateViewWithLecture:lecture];
}

@end
