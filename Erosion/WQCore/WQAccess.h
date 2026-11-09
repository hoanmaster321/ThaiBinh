//
//  WQAccess.h
//  ErosionWQ
//
//  File access outside the sandbox through the worse_query technique by
//  Taj C (forcequit), https://github.com/forcequitOS/worse_query,
//  GPL-3.0-or-later. Combined with Erosion customization toolbox.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/stat.h>

NS_ASSUME_NONNULL_BEGIN

// Log shared with the UI.
void wq_log(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
NSString *wq_log_text(void);

// Picks the app group the signer actually gave us. Nil when there is none.
NSString *_Nullable wq_app_group(void);

// Asks for a sandbox extension covering path (once per path). Returns YES
// when one is held for it.
BOOL wq_grant(NSString *path);

// Directory listing; asks for access when the plain call is refused.
NSArray<NSString *> *_Nullable wq_list(NSString *dir, NSString *_Nullable *_Nullable errorText);

// Reads a whole file (up to maxBytes; 0 = no limit).
NSData *_Nullable wq_read(NSString *path, NSUInteger maxBytes, NSString *_Nullable *_Nullable errorText);

// Overwrites a file in place (same inode, owner and xattrs). The previous
// contents are backed up first when the file is outside our own container.
BOOL wq_write(NSString *path, NSData *data, NSString *_Nullable *_Nullable errorText);

// Creates a new file or folder inside dir.
BOOL wq_create_file(NSString *path, NSData *data, NSString *_Nullable *_Nullable errorText);
BOOL wq_create_dir(NSString *path, NSString *_Nullable *_Nullable errorText);

// Deletes a file (backed up first) or an empty folder.
BOOL wq_delete(NSString *path, NSString *_Nullable *_Nullable errorText);
BOOL wq_rename(NSString *path, NSString *newName, NSString *_Nullable *_Nullable errorText);

// lstat with access retry. Returns NO if the item does not exist.
BOOL wq_stat(NSString *path, struct stat *st);

// Discovers direct children of dir by brute-forcing inode numbers with
// fsgetpath (not sandbox-gated), the way KAMUI/bad_query_list do. Needs no
// token on dir. maxInode bounds the scan; progress is called off the main
// thread. Returns absolute child paths.
NSArray<NSString *> *_Nullable wq_enumerate(NSString *dir, int64_t maxInode,
                                            void (^_Nullable progress)(int64_t done, int64_t total, NSUInteger found));

// Total byte size of a directory tree (grants access as needed). 0 if missing.
unsigned long long wq_dir_size(NSString *dir);

// Deletes every item *inside* dir (dir itself stays). No backup — for caches.
// Adds freed bytes to *freed. Returns NO if some items could not be removed.
BOOL wq_purge_contents(NSString *dir, unsigned long long *freed);

// Copies every item inside srcDir into dstDir (replacing same-named items).
// Either side may be another app's container. Returns NO if anything failed.
BOOL wq_copy_contents(NSString *srcDir, NSString *dstDir, NSString *_Nullable *_Nullable errorText);

// MCM container identifier (bundle or group id) of a container folder.
NSString *_Nullable wq_container_label(NSString *dir);

// Human app name for a bundle id, from LaunchServices' database (read from
// lsd's container), a built-in table of Apple services, or the parent app.
NSString *_Nullable wq_display_name(NSString *_Nullable bundleID);

// Backups of overwritten or deleted files, mirrored by original path.
NSString *wq_backup_root(void);
NSString *_Nullable wq_backup_original_path(NSString *backupPath);

// Device & iOS version line for display (e.g. "iPhone 16 Pro · iOS 27.0.1 (24A446)")
NSString *wq_device_line(void);

// Formats byte count to readable string
NSString *wq_size_text(unsigned long long size);

// Formatted hex dump
NSString *wq_hex_dump(NSData *data);

// App icon helper (real icon or system tile)
UIImage *_Nullable wq_app_icon(NSString *bundleID);

// Serial background queue for WQ operations
dispatch_queue_t wq_io_queue(void);

// App Backups helpers
NSString *wq_app_backup_root(NSString *bundleID);
NSString *_Nullable wq_latest_app_backup(NSString *bundleID);

// Zip and share folder via native Share Sheet
void wq_share_folder(UIViewController *host, NSString *dir, NSString *zipName, UIView *_Nullable source);
void wq_share_file(UIViewController *host, NSString *path, UIView *_Nullable source);

// App data backup, restore, clear
BOOL wq_clear_app_data(NSString *containerDir, unsigned long long *freedBytes);
BOOL wq_backup_app_data(NSString *containerDir, NSString *bundleID, NSString *_Nullable *_Nullable outStampDir, NSString *_Nullable *_Nullable outError);
BOOL wq_restore_app_data(NSString *stampDir, NSString *containerDir, NSString *_Nullable *_Nullable outError);

NS_ASSUME_NONNULL_END
