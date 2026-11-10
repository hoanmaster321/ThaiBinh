//
//  WQCore.h
//  ThaiBinh (ErosionWQ)
//
//  GPL-3.0-or-later.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQEditState : NSObject
@property (nonatomic, readonly) NSUInteger revision;
@property (nonatomic, readonly, getter=isDirty) BOOL dirty;
@property (nonatomic, readonly, getter=isSaving) BOOL saving;
- (void)noteChange;
- (NSUInteger)beginSave;
- (void)finishSave:(BOOL)success revision:(NSUInteger)savedRevision;
- (void)discard;
@end

NSData *_Nullable WQParseHex(NSString *text, BOOL allowAngleBrackets);
BOOL WQPatchRangeValid(unsigned long long offset, NSUInteger length, unsigned long long fileSize);
NSDictionary<NSString *, NSNumber *> *WQRestorePlan(BOOL hasDocuments, BOOL hasLibrary);

NS_ASSUME_NONNULL_END
