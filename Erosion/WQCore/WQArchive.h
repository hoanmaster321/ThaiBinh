//
//  WQArchive.h
//  Thái Bình (ErosionWQ)
//
//  Minimal ZIP writer and reader (stored and deflate, via zlib) from WQFiles v0.9.
//  Files are read through a small I/O table, so the same code works on other apps'
//  containers (through WQAccess) and on plain files.
//

#import <Foundation/Foundation.h>
#import <sys/stat.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQArchiveIO : NSObject
@property (nonatomic, copy) BOOL (^stat)(NSString *path, struct stat *st);
@property (nonatomic, copy) NSArray<NSString *> *_Nullable (^list)(NSString *dir);
@property (nonatomic, copy) int (^openRead)(NSString *path);
@end

WQArchiveIO *wq_archive_posix_io(void);
WQArchiveIO *wq_app_archive_io(void);

typedef BOOL (^WQArchiveCancelled)(void);
typedef void (^WQArchiveProgress)(unsigned long long bytes);

BOOL wq_zip_write(NSArray<NSString *> *paths, NSString *zipPath, WQArchiveIO *io,
                  WQArchiveCancelled _Nullable cancelled, WQArchiveProgress _Nullable progress,
                  NSUInteger *_Nullable skipped, NSString *_Nullable *_Nullable errorText);

BOOL wq_zip_extract(NSString *zipPath, NSString *outDir, WQArchiveIO *io, unsigned long long maxBytes,
                    WQArchiveCancelled _Nullable cancelled, WQArchiveProgress _Nullable progress,
                    NSUInteger *_Nullable files, NSUInteger *_Nullable skipped,
                    NSString *_Nullable *_Nullable errorText);

NSString *_Nullable wq_zip_safe_entry_path(NSString *name);

// High-level helpers for Swift UI (compresses paths into destZipPath via temp dir + wq_create_file_from;
// extracts zipPath into new folder destFolderPath via temp dir + wq_create_dir + wq_copy_contents).
BOOL wq_compress_items(NSArray<NSString *> *paths, NSString *destZipPath,
                       NSUInteger *_Nullable skippedOut, NSString *_Nullable *_Nullable errorText);

BOOL wq_extract_zip(NSString *zipPath, NSString *destFolderPath,
                    NSUInteger *_Nullable filesOut, NSUInteger *_Nullable skippedOut,
                    NSString *_Nullable *_Nullable errorText);

NS_ASSUME_NONNULL_END
