//
//  WQAccess.h
//  ThaiBinh (ErosionWQ)
//
//  File access outside the sandbox through the worse_query technique by
//  Taj C (forcequit), https://github.com/forcequitOS/worse_query,
//  GPL-3.0-or-later. Updated to WQFiles v0.8 & localized for ThaiBinh.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/stat.h>
#import "WQLaunchServices.h"
#import "WQCore.h"

NS_ASSUME_NONNULL_BEGIN

// Thread-safe cancellation for expensive filesystem scans.
@interface WQScanCancellation : NSObject
@property (atomic, readonly, getter=isCancelled) BOOL cancelled;
- (void)cancel;
@end

typedef NS_ENUM(NSInteger, WQMeasureResult) {
    WQMeasureResultMissing,
    WQMeasureResultKnown,
    WQMeasureResultLimited,
    WQMeasureResultCancelled,
};

// Log shared with the UI.
void wq_log(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
NSString *wq_log_text(void);

// Picks the app group the signer actually gave us. Nil when there is none.
NSString *_Nullable wq_app_group(void);

// NO on iOS 26: worse_query reaches System Data, system groups, and App Groups parent only on iOS 27+.
BOOL wq_system_areas_reachable(void);

// Asks for a sandbox extension covering path (once per path). Returns YES when one is held for it.
BOOL wq_grant(NSString *path);

// Directory listing; asks for access when the plain call is refused.
NSArray<NSString *> *_Nullable wq_list(NSString *dir, NSString *_Nullable *_Nullable errorText);

// Reads a whole file (up to maxBytes; 0 = no limit).
NSData *_Nullable wq_read(NSString *path, NSUInteger maxBytes, NSString *_Nullable *_Nullable errorText);

// Reads `length` bytes at `offset` (fewer at the end of the file).
NSData *_Nullable wq_read_range(NSString *path, unsigned long long offset, NSUInteger length,
                                NSString *_Nullable *_Nullable errorText);

// A file's identity, size and change timestamps, for optimistic concurrency.
NSDictionary<NSString *, NSNumber *> *_Nullable wq_file_version(NSString *path);

// Overwrites a file in place (same inode, owner and xattrs). The previous contents are backed up first.
BOOL wq_write(NSString *path, NSData *data, NSString *_Nullable *_Nullable errorText);
BOOL wq_write_if_unchanged(NSString *path, NSData *data, NSDictionary<NSString *, NSNumber *> *_Nullable expected,
                           NSString *_Nullable *_Nullable errorText);
BOOL wq_write_if_unchanged_get_version(NSString *path, NSData *data,
    NSDictionary<NSString *, NSNumber *> *_Nullable expected,
    NSDictionary<NSString *, NSNumber *> *_Nullable *_Nullable savedVersion,
    NSString *_Nullable *_Nullable errorText);

BOOL wq_write_from_file(NSString *path, NSString *source, NSString *_Nullable *_Nullable errorText);
BOOL wq_create_file_from(NSString *path, NSString *source, NSString *_Nullable *_Nullable errorText);
BOOL wq_copy_to_local(NSString *path, NSString *dest, NSString *_Nullable *_Nullable errorText);

NSString *_Nullable wq_permission_hint(NSString *path, BOOL forWriting);

BOOL wq_patch(NSString *path, NSDictionary<NSNumber *, NSData *> *runs, NSString *_Nullable *_Nullable errorText);
BOOL wq_patch_if_unchanged(NSString *path, NSDictionary<NSNumber *, NSData *> *runs,
                           NSDictionary<NSString *, NSNumber *> *_Nullable expected, NSString *_Nullable *_Nullable errorText);
BOOL wq_patch_if_unchanged_get_version(NSString *path, NSDictionary<NSNumber *, NSData *> *runs,
    NSDictionary<NSString *, NSNumber *> *_Nullable expected,
    NSDictionary<NSString *, NSNumber *> *_Nullable *_Nullable savedVersion,
    NSString *_Nullable *_Nullable errorText);

// Creates a new file or folder inside dir.
BOOL wq_create_file(NSString *path, NSData *data, NSString *_Nullable *_Nullable errorText);
BOOL wq_create_dir(NSString *path, NSString *_Nullable *_Nullable errorText);

// Deletes a file (backed up first) or an empty folder.
BOOL wq_delete(NSString *path, NSString *_Nullable *_Nullable errorText);
BOOL wq_backup_unit_deletable(NSString *path);
BOOL wq_delete_backup(NSString *path, NSString *_Nullable *_Nullable errorText);
BOOL wq_rename(NSString *path, NSString *newName, NSString *_Nullable *_Nullable errorText);
// Moves a file or folder into destDir (same volume), keeping its name. Never
// replaces an existing item; refuses moves into itself and into backups.
BOOL wq_move(NSString *path, NSString *destDir, NSString *_Nullable *_Nullable errorText);
// Read-only descriptor for a regular file (asks for access when refused), or -1.
int wq_open_for_reading(NSString *path);

// Settings: Allow Deleting (on by default) & Show Item Counts (off by default)
BOOL wq_deleting_allowed(void);
void wq_set_deleting_allowed(BOOL allowed);
BOOL wq_show_item_counts(void);
void wq_set_show_item_counts(BOOL show);

// lstat with access retry. Returns NO if the item does not exist.
BOOL wq_stat(NSString *path, struct stat *st);

// Discovers direct children of dir (via container manager, LaunchServices DB, or fsgetpath scan).
// maxInode = 0 uses the fast LaunchServices DB / dynamic volume bound path with persistent cache.
void wq_enumerate_invalidate(void);
NSArray<NSString *> *_Nullable wq_enumerate(NSString *dir, int64_t maxInode,
                                            void (^_Nullable progress)(int64_t done, int64_t total, NSUInteger found));
NSArray<NSString *> *_Nullable wq_enumerate_cancellable(NSString *dir, int64_t maxInode,
                                                        WQScanCancellation *_Nullable cancellation,
                                                        void (^_Nullable progress)(int64_t done, int64_t total, NSUInteger found));

void wq_set_full_scan_ui(BOOL (*_Nullable confirm)(NSString *what, int64_t ids, double seconds),
                         void (*_Nullable progress)(int64_t done, int64_t total, BOOL finished));
void wq_full_scan_stop(void);
BOOL wq_full_scan_was_declined(void);
void wq_set_container_list_provider(NSArray<NSString *> *_Nullable (*_Nullable provider)(NSString *_Nullable storeHint));
void wq_set_container_label_resolver(NSString *_Nullable (*_Nullable resolver)(NSString *path));

// Total byte size of a directory tree (grants access as needed). 0 if missing.
unsigned long long wq_dir_size(NSString *dir);
WQMeasureResult wq_measure_tree(NSString *dir, WQScanCancellation *_Nullable cancellation,
                                unsigned long long *_Nullable bytes);

// Deletes every item *inside* dir (dir itself stays). No backup — for caches.
BOOL wq_purge_contents(NSString *dir, unsigned long long *freed);
BOOL wq_purge_contents_cancellable(NSString *dir, unsigned long long *freed,
                                   WQScanCancellation *_Nullable cancellation);

// Copies every item inside srcDir into dstDir (replacing same-named items).
BOOL wq_copy_contents(NSString *srcDir, NSString *dstDir, NSString *_Nullable *_Nullable errorText);

// MCM container identifier (bundle or group id) of a container folder.
NSString *_Nullable wq_container_label(NSString *dir);

// Backups of overwritten or deleted files, mirrored by original path.
NSString *wq_backup_root(void);
NSString *wq_app_backups_root_dir(void);
BOOL wq_is_backup_storage_path(NSString *path);
NSString *_Nullable wq_backup_original_path(NSString *backupPath);

// Device & iOS version line for display
NSString *wq_device_line(void);

// Formats byte count to readable string
NSString *wq_size_text(unsigned long long size);

// Formatted hex dump
NSString *wq_hex_dump(NSData *data);

// App icon helper (real icon, bundle PNG icon fallback, parent app icon, or system tile)
UIImage *_Nullable wq_app_icon(NSString *bundleID);

// Serial background queue for WQ operations
dispatch_queue_t wq_io_queue(void);

// App Backups helpers
NSString *wq_app_backup_root(NSString *bundleID);
NSString *_Nullable wq_latest_app_backup(NSString *bundleID);
NSArray<NSString *> *wq_all_app_backups(NSString *bundleID);
BOOL wq_delete_app_backup(NSString *stampDir);

// Known SystemGroup paths fallback for iOS 27.0.1+
NSArray<NSString *> *wq_known_system_groups(void);

// Zip and share folder via native Share Sheet
void wq_share_folder(UIViewController *host, NSString *dir, NSString *zipName, UIView *_Nullable source);
void wq_share_file(UIViewController *host, NSString *path, UIView *_Nullable source);

// App data backup, restore, clear
BOOL wq_clear_app_data(NSString *containerDir, unsigned long long *freedBytes);
BOOL wq_backup_app_data(NSString *containerDir, NSString *bundleID, NSString *_Nullable *_Nullable outStampDir, NSString *_Nullable *_Nullable outError);
BOOL wq_restore_app_data(NSString *stampDir, NSString *containerDir, NSString *_Nullable *_Nullable outError);

// SQLite header detection ("SQLite format 3\0")
BOOL wq_is_sqlite_header(NSData *_Nullable header);
BOOL wq_is_sqlite_file(NSString *path);

NS_ASSUME_NONNULL_END
