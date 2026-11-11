//
//  WQSyntax.h
//  Thái Bình (ErosionWQ)
//
//  Syntax highlighter for the text viewer from WQFiles v0.9: one regular expression
//  per language finds comments, strings, numbers, keywords and tags left to right.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, WQSyntaxKind) {
    WQSyntaxComment = 1,
    WQSyntaxString,
    WQSyntaxKey,          // JSON keys, CSS properties, INI/YAML keys
    WQSyntaxKeyword,
    WQSyntaxNumber,
    WQSyntaxTag,          // XML/HTML tag names, CSS selectors
    WQSyntaxAttribute,    // XML attributes
    WQSyntaxPreprocessor, // #include, @media, shebang
};

typedef struct {
    NSRange range;
    WQSyntaxKind kind;
} WQSyntaxToken;

extern const NSUInteger kWQSyntaxMaxLength;

NSString *_Nullable wq_syntax_language(NSString *fileName, NSString *_Nullable text);

NSData *_Nullable wq_syntax_tokens(NSString *text, NSString *language, BOOL (^_Nullable cancelled)(void));

// High-level helper returning a colored NSAttributedString for SwiftUI/UIKit viewers.
NSAttributedString *_Nullable wq_syntax_highlight(NSString *text, NSString *language, UIFont *font);

NS_ASSUME_NONNULL_END
