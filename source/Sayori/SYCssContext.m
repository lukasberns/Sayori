/*
SYCssContext.m

Author: Makoto Kinoshita, Hajime Nakamura

Copyright 2010-2013 HMDT. All rights reserved.
*/

#import "SYCssContext.h"

// Default sizes
static css_hint_length _baseSizes[] = {
    { FLTTOFIX(6.75), CSS_UNIT_PT },
    { FLTTOFIX(7.50), CSS_UNIT_PT },
    { FLTTOFIX(9.75), CSS_UNIT_PT },
    { FLTTOFIX(12.0), CSS_UNIT_PT },
    { FLTTOFIX(13.5), CSS_UNIT_PT },
    { FLTTOFIX(18.0), CSS_UNIT_PT },
    { FLTTOFIX(24.0), CSS_UNIT_PT }
};

//--------------------------------------------------------------//
#pragma mark -- LWC string --
//--------------------------------------------------------------//

@interface NSString (wapcaplet)

+ (NSString*)stringWithLWCString:(struct lwc_string_s*)str;
- (struct lwc_string_s*)LWCString;

@end

@implementation NSString (wapcaplet)

+ (NSString*)stringWithLWCString:(lwc_string*)str
{
    return [[NSString alloc] 
            initWithBytes:lwc_string_data(str) 
            length:lwc_string_length(str) 
            encoding:NSUTF8StringEncoding];
}

- (lwc_string*)LWCString
{
    NSData*     data;
    lwc_string* str = NULL;
    data = [self dataUsingEncoding:NSUTF8StringEncoding];
    lwc_intern_string((const char*)[data bytes], [data length], &str);
    
    return str;
}

@end

//--------------------------------------------------------------//
#pragma mark -- Utility --
//--------------------------------------------------------------//

static void* _cssRealloc(
        void* ptr, 
        size_t size, 
        void* pw)
{
#if 1
    if (size > 0) {
        void*   reallocPtr;
        reallocPtr = realloc(ptr, size);
        
        return reallocPtr;
    }
    
    free(ptr);
    
    return NULL;
#else
    return CFAllocatorReallocate(
            kCFAllocatorDefault, ptr, (CFIndex)size, 0);
#endif
}

static css_error _urlResolver(
        void* pw, 
        const char* base, 
        lwc_string* rel, 
        lwc_string** abs)
{
    *abs = lwc_string_ref(rel);
    
    return CSS_OK;
}

//--------------------------------------------------------------//
#pragma mark -- Handler --
//--------------------------------------------------------------//

static css_error _nodeName(
        void* pw, 
        void* node, 
        css_qname* qname)
{
    // Get node name
    NSString*   nodeName;
#if TARGET_OS_IPHONE
    nodeName = [(__bridge HMXMLNode*)node name];
#elif TARGET_OS_MAC
    nodeName = [(__bridge NSXMLNode*)node name];
#endif
    if (!nodeName) {
        // Set NULL
        qname->ns = NULL;
        qname->name = NULL;
        
        return CSS_OK;
    }
    
    // Set name as LWC string
    lwc_string* name;
    name = [nodeName LWCString];
    qname->name = name;
    qname->ns = NULL;
    
	return CSS_OK;
}

static css_error _nodeClasses(
        void* pw, 
        void* node, 
        lwc_string*** classes, 
        uint32_t* n_classes)
{
    // Get class name
    NSString*   className;
#if TARGET_OS_IPHONE
    className = [(__bridge HMXMLElement*)node attributeForName:@"class"];
#elif TARGET_OS_MAC
    className = [[(__bridge NSXMLElement*)node attributeForName:@"class"] stringValue];
#endif
    if (!className) {
        // Set NULL
        *classes = NULL;
        *n_classes = 0;
        
        return CSS_OK;
    }
    
    // Get componets of class
    NSArray*    components;
    NSUInteger  count;
    components = [className componentsSeparatedByString:@" "];
    count = [components count];
    
    // Set class as LWC string array
    lwc_string**    lwcStrs = NULL;
    lwcStrs = _cssRealloc(lwcStrs, sizeof(lwc_string*) * count, NULL);
    *classes = lwcStrs;
    *n_classes = (u_int32_t)count;
    
    for (NSString* name in components) {
        lwc_string*     lwcStr;
        lwcStr = [name LWCString];
        *lwcStrs++ = lwcStr;
    }
    
    return CSS_OK;
}

static css_error _nodeId(
        void* pw, 
        void* node, 
        lwc_string** id)
{
    // Get identifier
    NSString*   identifier;
#if TARGET_OS_IPHONE
    identifier = [(__bridge HMXMLElement*)node attributeForName:@"id"];
#elif TARGET_OS_MAC
    identifier = [[(__bridge NSXMLElement*)node attributeForName:@"id"] stringValue];
#endif
    if (!_nodeId) {
        // Set NULL
        *id = NULL;
        
        return CSS_OK;
    }
    
    // Set identifier as LWC string
	*id = [identifier LWCString];
    
	return CSS_OK;
}

static css_error named_ancestor_node(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        void** ancestor)
{
	*ancestor = NULL;
    
	return CSS_OK;
}

static css_error named_parent_node(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        void** parent)
{
	*parent = NULL;
    
	return CSS_OK;
}

static css_error named_sibling_node(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        void **sibling)
{
	*sibling = NULL;
    
	return CSS_OK;
}

static css_error _namedGenericSiblingNode(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        void **sibling)
{
	*sibling = NULL;
    
	return CSS_OK;
}

static css_error _parentNode(
        void* pw, 
        void* node, 
        void** parent)
{
#if TARGET_OS_IPHONE
    HMXMLNode*  parentNode = NULL;
    
    // For not body
    if (![[(__bridge HMXMLNode*)node name] isEqualToString:@"body"]) {
        // Get parent node
        parentNode = [(__bridge HMXMLNode*)node parent];
    }
#elif TARGET_OS_MAC
    NSXMLNode*  parentNode = NULL;
    
    // For not body
    if (![[(__bridge NSXMLNode*)node name] isEqualToString:@"body"]) {
        // Get parent node
        parentNode = [(__bridge NSXMLNode*)node parent];
    }
#endif
    
    // Set parent node
    *parent = (__bridge void*)(parentNode);
    
	return CSS_OK;
}

static css_error sibling_node(
        void* pw, 
        void* node, 
        void** sibling)
{
	*sibling = NULL;
    
	return CSS_OK;
}

static css_error _nodeHasName(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        bool* match)
{
//NSLog(@"%s", __PRETTY_FUNCTION__);
    // Get node name
    NSString*   nodeName;
#if TARGET_OS_IPHONE
    nodeName = [(__bridge HMXMLNode*)node name];
#elif TARGET_OS_MAC
    nodeName = [(__bridge NSXMLNode*)node name];
#endif
    if (!nodeName) {
        // Not match
        *match = NO;
        
        return CSS_OK;
    }
    
    // Compare strings
    lwc_string* name;
    name = [nodeName LWCString];
    lwc_string_caseless_isequal(name, qname->name, match);
    lwc_string_unref(name);
    //lwc_string_destroy(name);
    
    return CSS_OK;
}

static css_error _nodeHasClass(
        void* pw, 
        void* n, 
        lwc_string* name, 
        bool* match)
{
//NSLog(@"%s, name %@", __PRETTY_FUNCTION__, [NSString stringWithLWCString:name]);
    // Get class name
    NSString*   className;
#if TARGET_OS_IPHONE
    className = [(__bridge HMXMLElement*)n attributeForName:@"class"];
#elif TARGET_OS_MAC
    className = [[(__bridge NSXMLElement*)n attributeForName:@"class"] stringValue];
#endif
    if (!className) {
        // Not math
        *match = NO;
        
        return CSS_OK;
    }
    
    // Get componets of class
    NSArray*    components;
    NSUInteger  count;
    components = [className componentsSeparatedByString:@" "];
    count = [components count];
    
    // Compare strings
    *match = NO;
    for (NSString* component in components) {
        lwc_string*     lwcStr;
        lwcStr = [component LWCString];
        lwc_string_caseless_isequal(lwcStr, name, match);
        lwc_string_unref(lwcStr);
        
        if (*match) {
            break;
        }
    }
    
	return CSS_OK;
}

static css_error _nodeHasId(
        void* pw, 
        void* node, 
        lwc_string* name, 
        bool* match)
{
//NSLog(@"%s", __PRETTY_FUNCTION__);
    // Get identifier
    NSString*   identifier;
#if TARGET_OS_IPHONE
    identifier = [(__bridge HMXMLElement*)node attributeForName:@"id"];
#elif TARGET_OS_MAC
    identifier = [[(__bridge NSXMLElement*)node attributeForName:@"id"] stringValue];
#endif
    if (!identifier) {
        // Not math
        *match = NO;
        
        return CSS_OK;
    }
    
    // Compare strings
    lwc_string* idString;
    idString = [identifier LWCString];
	lwc_string_caseless_isequal(idString, name, match);
    lwc_string_unref(idString);
    //lwc_string_destroy(idString);
    
	return CSS_OK;
}

static css_error node_has_attribute(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        bool* match)
{
//NSLog(@"### node_has_attribute");
	*match = false;
	return CSS_OK;
}

static css_error node_has_attribute_equal(
        void* pw, 
        void* n, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### node_has_attribute_equal");
	*match = false;
	return CSS_OK;
}

static css_error node_has_attribute_dashmatch(
        void* pw, 
        void* n, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### node_has_attribute_dashmatch");
	*match = false;
	return CSS_OK;
}

static css_error node_has_attribute_includes(
        void* pw, 
        void* n, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### node_has_attribute_includes");
	*match = false;
	return CSS_OK;
}

static css_error _nodeHasAttributePrefix(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### _nodeHasAttributePrefix");
	*match = false;
	return CSS_OK;
}

static css_error _nodeHasAttributeSufffix(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### _nodeHasAttributeSufffix");
	*match = false;
	return CSS_OK;
}

static css_error _nodeHasAttributeSubstring(
        void* pw, 
        void* node, 
        const css_qname* qname, 
        lwc_string* value, 
        bool* match)
{
//NSLog(@"### _nodeHasAttributeSubstring");
	*match = false;
	return CSS_OK;
}

static css_error _nodeIsRoot(
        void* pw, 
        void* node, 
        bool* match)
{
    // Get parent
    void*   parent;
    if (_parentNode(pw, node, &parent) != CSS_OK) {
        *match = false;
        return CSS_OK;
    }
    
    // Set match
    *match = parent == NULL;
    
	return CSS_OK;
}

static css_error _nodeCountSiblings(
        void* pw, 
        void* node, 
        bool sameName, 
        bool after, 
        int32_t* count)
{
//NSLog(@"### _nodeCountSiblings");
	*count = 0;
    return CSS_OK;
}

static css_error _nodeIsEmpty(
        void* pw, 
        void* node, 
        bool* match)
{
//NSLog(@"### _nodeIsEmpty");
	*match = false;
	return CSS_OK;
}

static css_error node_is_link(void *pw, void *n, bool *match)
{
//NSLog(@"### node_is_link");
	*match = false;
	return CSS_OK;
}

static css_error node_is_visited(void *pw, void *n, bool *match)
{
//NSLog(@"### node_is_visited");
	*match = false;
	return CSS_OK;
}

static css_error node_is_hover(void *pw, void *n, bool *match) 
{
//NSLog(@"### node_is_hover");
	*match = false;
	return CSS_OK;
}

static css_error node_is_active(void *pw, void *n, bool *match)
{
//NSLog(@"### node_is_active");
	*match = false;
	return CSS_OK;
}

static css_error node_is_focus(void *pw, void *n, bool *match)
{
//NSLog(@"### node_is_focus");
	*match = false;
	return CSS_OK;
}

static css_error _nodeIsEnabled(
        void* pw, 
        void* node, 
        bool* match)
{
//NSLog(@"### _nodeIsEnabled");
	*match = false;
	return CSS_OK;
}

static css_error _nodeIsDisabled(
        void* pw, 
        void* node, 
        bool* match)
{
//NSLog(@"### _nodeIsDisabled");
	*match = false;
	return CSS_OK;
}

static css_error _nodeIsChecked(
        void* pw, 
        void* node, 
        bool* match)
{
//NSLog(@"### _nodeIsChecked");
	*match = false;
	return CSS_OK;
}

static css_error _nodeIsTarget(
        void* pw, 
        void* node, 
        bool* match)
{
//NSLog(@"### _nodeIsTarget");
	*match = false;
	return CSS_OK;
}

static css_error node_is_lang(void *pw, void *n, lwc_string *lang,
                              bool *match)
{
//NSLog(@"### node_is_lang");
	*match = false;
	return CSS_OK;
}

static css_error _nodePresentationalHint(
        void* pw, 
        void* node, 
        uint32_t property, 
        css_hint* hint)
{
    // For root
    bool    match;
    _nodeIsRoot(pw, node, &match);
    if (match) {
        switch (property) {
        case CSS_PROP_BORDER_TOP_WIDTH:
        case CSS_PROP_BORDER_RIGHT_WIDTH:
        case CSS_PROP_BORDER_BOTTOM_WIDTH:
        case CSS_PROP_BORDER_LEFT_WIDTH:
        {
            hint->data.fixed = 0;
            hint->status = CSS_BORDER_WIDTH_WIDTH;
            
            return CSS_OK;
        }
        }
    }
    
    // Set INHERIT
    hint->status = 0;
    
    return CSS_OK;
}

static css_error ua_default_for_property(
        void* pw, 
        uint32_t property, 
        css_hint* hint)
{
	if (property == CSS_PROP_COLOR) {
		hint->data.color = 0xff000000;
		hint->status = CSS_COLOR_COLOR;
        
        return CSS_OK;
	}
    else if (property == CSS_PROP_BACKGROUND_COLOR) {
		hint->data.color = 0xffffffff;
		hint->status = CSS_COLOR_COLOR;
        
        return CSS_OK;
	}
    else if (property == CSS_PROP_BORDER_BOTTOM_WIDTH) {
NSLog(@"### ua_default_for_property");
        hint->data.fixed = 0;
        hint->status = CSS_BORDER_WIDTH_WIDTH;
        
        return CSS_OK;
    }
    else if (property == CSS_PROP_FONT_FAMILY) {
		hint->data.strings = NULL;
		hint->status = CSS_FONT_FAMILY_SANS_SERIF;
        
        return CSS_OK;
	}
    else if (property == CSS_PROP_QUOTES) {
		hint->data.strings = NULL;
		hint->status = CSS_QUOTES_NONE;
        
        return CSS_OK;
	}
    else if (property == CSS_PROP_VOICE_FAMILY) {
		hint->data.strings = NULL;
		hint->status = 0;
        
        return CSS_OK;
	}
    
    return CSS_INVALID;
}

static css_error _computeFontSize(
        void* pw, 
        const css_hint* parent, 
        css_hint* size)
{
//NSLog(@"### _computeFontSize, parent %p", parent);
    // Decide parent size, defaulting to medium if none
	const css_hint_length*  parent_size;
    if (!parent) {
		parent_size = &_baseSizes[CSS_FONT_SIZE_MEDIUM - 1];
	} else {
		parent_size = &parent->data.length;
	}
    
	if (size->status < CSS_FONT_SIZE_LARGER) {
//NSLog(@"_computeFontSize, < LARGER");
		// Keyword -- simple
		size->data.length = _baseSizes[size->status - 1];
	}
    else if (size->status == CSS_FONT_SIZE_LARGER) {
//NSLog(@"_computeFontSize, LARGER");
		size->data.length.value = (css_fixed)FMUL(parent_size->value, FLTTOFIX(1.2));
		size->data.length.unit = parent_size->unit;
	}
    else if (size->status == CSS_FONT_SIZE_SMALLER) {
//NSLog(@"_computeFontSize, SMALLER");
		size->data.length.value = (css_fixed)FMUL(parent_size->value, FLTTOFIX(1.2));
		size->data.length.unit = parent_size->unit;
	}
    else if (size->data.length.unit == CSS_UNIT_EM ||
			 size->data.length.unit == CSS_UNIT_EX)
    {
//NSLog(@"_computeFontSize, EM or EX");
		size->data.length.value = (css_fixed)FMUL(size->data.length.value, parent_size->value);
		if (size->data.length.unit == CSS_UNIT_EX) {
			size->data.length.value = (css_fixed)FMUL(size->data.length.value, FLTTOFIX(0.6));
		}
		size->data.length.unit = parent_size->unit;
	}
    else if (size->data.length.unit == CSS_UNIT_PCT) {
//NSLog(@"_computeFontSize, PCT");
		size->data.length.value = (css_fixed)FDIV(FMUL(size->data.length.value,
                                        parent_size->value), FLTTOFIX(100));
		size->data.length.unit = parent_size->unit;
	}
    
	size->status = CSS_FONT_SIZE_DIMENSION;
    
	return CSS_OK;
}

css_select_handler _handler = {
    CSS_SELECT_HANDLER_VERSION_1, 
	_nodeName, 
	_nodeClasses, 
	_nodeId, 
	named_ancestor_node, 
	named_parent_node, 
	named_sibling_node, 
    _namedGenericSiblingNode, 
	_parentNode, 
	sibling_node, 
	_nodeHasName, 
	_nodeHasClass, 
	_nodeHasId, 
	node_has_attribute, 
	node_has_attribute_equal, 
	node_has_attribute_dashmatch, 
	node_has_attribute_includes, 
    _nodeHasAttributePrefix, 
    _nodeHasAttributeSufffix, 
    _nodeHasAttributeSubstring, 
    _nodeIsRoot, 
    _nodeCountSiblings, 
    _nodeIsEmpty, 
	node_is_link, 
	node_is_visited, 
	node_is_hover, 
	node_is_active, 
	node_is_focus, 
    _nodeIsEnabled, 
    _nodeIsDisabled, 
    _nodeIsChecked, 
    _nodeIsTarget, 
	node_is_lang, 
	_nodePresentationalHint, 
	ua_default_for_property, 
	_computeFontSize
};

//--------------------------------------------------------------//
#pragma mark -- Functions --
//--------------------------------------------------------------//

float _fixToFloat(
        css_fixed fixed, 
        css_unit unit, 
        float fontSize)
{
    // Calc value
    float   value;
    value = FIXTOFLT(fixed);
    if (unit == CSS_UNIT_EX) {
        value = fontSize * 0.6f * value; // For x-height
    }
    else if (unit == CSS_UNIT_EM) {
        value = fontSize * value;
    }
    else if (unit == CSS_UNIT_PCT) {
        value = fontSize * (value / 100.0f);
    }
    
    return value;
}

SYCssContext* SYCssContextCreate()
{
    // Allocate CSS context
    SYCssContext*   cssContext;
    cssContext = malloc(sizeof(SYCssContext));
    
    // Create contenxt
    css_error   error;
    error = css_select_ctx_create(&_cssRealloc, NULL, &(cssContext->context));
    if (error != CSS_OK) {
        NSLog(@"Failed to craete css select context, error %d", error);
    }
    
    // Add default CSS data
    NSString*   path;
    path = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"css"];
    if (path) {
        SYCssContextAddStylesheetData(
                cssContext, [NSData dataWithContentsOfFile:path]);
    }
    
    return cssContext;
}

void SYCssContextRelease(
        SYCssContext* cssContext)
{
    css_error   error;
    
    // Check argument
    if (!cssContext) {
        return;
    }
    
    // Release style sheets
    uint32_t    count;
    error = css_select_ctx_count_sheets(cssContext->context, &count);
    if (error == CSS_OK) {
        int i;
        for (i = 0; i < count; i++) {
            const css_stylesheet*   sheet = NULL;
            error = css_select_ctx_get_sheet(cssContext->context, i, &sheet);
            if (error == CSS_OK) {
                error = css_select_ctx_remove_sheet(cssContext->context, sheet);
                error = css_stylesheet_data_done((css_stylesheet*)sheet);
                error = css_stylesheet_destroy((css_stylesheet*)sheet);
            }
        }
    }
    
    // Release context
    css_select_ctx_destroy(cssContext->context);
    
    // Free CSS context
    free(cssContext), cssContext = NULL;
}

void SYCssContextSetBaseFontSize(
        SYCssContext* cssContext, 
        float baseFontSize)
{
    // Set base font size
    cssContext->baseFontSize = baseFontSize;
    
    // Update font sizes
    int i;
    for (i = 0; i < sizeof(_baseSizes) / sizeof(css_hint_length); i++) {
        // Decide ratio
        float   ratio = 1.0f;
        if (i == 0) { ratio = 0.5625f; }
        else if (i == 0) { ratio = 0.5625f; }
        else if (i == 1) { ratio = 0.625f; }
        else if (i == 2) { ratio = 0.8125f; }
        else if (i == 3) { ratio = 1.0f; }
        else if (i == 4) { ratio = 1.125f; }
        else if (i == 5) { ratio = 1.5f; }
        else if (i == 5) { ratio = 2.0f; }
        
        // Set value
        _baseSizes[i].value = FLTTOFIX(baseFontSize * ratio);
    }
}

void SYCssContextAddStylesheetData(
        SYCssContext* cssContext, 
        NSData* data)
{
    css_error   error;
    
    // Check argument
    if ([data length] == 0) {
        return;
    }
    
    // Prepare params
    css_stylesheet_params   params;
    params.params_version = CSS_STYLESHEET_PARAMS_VERSION_1;
    params.level = CSS_LEVEL_DEFAULT;
    params.charset = "UTF-8";
    params.url = "";
    params.title = NULL;
    params.allow_quirks = NO;
    params.inline_style = NO;
    params.resolve = _urlResolver;
    params.resolve_pw = NULL;
    params.import = NULL;
    params.import_pw = NULL;
    params.color = NULL;
    params.color_pw = NULL;
    params.font = NULL;
    params.font_pw = NULL;
    
    // Create stylesheet
    css_stylesheet* stylesheet;
    error = css_stylesheet_create(
            &params, &_cssRealloc, cssContext, &stylesheet);
    if (error != CSS_OK) {
        NSLog(@"Failed to craete stylesheet, error %d", error);
        
        return;
    }
    
    // Append data
    error = css_stylesheet_append_data(
            stylesheet, (const uint8_t*)[data bytes], [data length]);
    if (error != CSS_OK && error != CSS_NEEDDATA) {
        NSLog(@"Failed to append stylesheet data, error %d", error);
        
        return;
    }
    
    // Add stylesheet
    error = css_select_ctx_append_sheet(
            cssContext->context, stylesheet, CSS_ORIGIN_AUTHOR, CSS_MEDIA_ALL);
    if (error != CSS_OK) {
        NSLog(@"Failed to add stylesheet, error %d", error);
        
        return;
    }
}

void _selectBorderStyle(
    SYTextBorder* borderLeft, 
    SYTextBorder* borderTop, 
    SYTextBorder* borderRight, 
    SYTextBorder* borderBottom, 
    css_computed_style* computedStyle, 
    float fontSize)
{
    css_fixed   fixed;
    css_unit    unit;
    css_color   color;
    uint8_t     result;
    
    // Set border left width
    result = css_computed_border_left_width(computedStyle, &fixed, &unit);
    if (result != CSS_BORDER_WIDTH_INHERIT) {
        // For width
        if (result == CSS_BORDER_WIDTH_WIDTH) {
            // Set value
            borderLeft->value = FIXTOFLT(fixed);
            borderLeft->unit = unit;
        }
    }
    
    // Set border top width
    result = css_computed_border_top_width(computedStyle, &fixed, &unit);
    if (result != CSS_BORDER_WIDTH_INHERIT) {
        // For width
        if (result == CSS_BORDER_WIDTH_WIDTH) {
            // Set value
            borderTop->value = FIXTOFLT(fixed);
            borderTop->unit = unit;
        }
    }
    
    // Set border right width
    result = css_computed_border_right_width(computedStyle, &fixed, &unit);
    if (result != CSS_BORDER_WIDTH_INHERIT) {
        // For width
        if (result == CSS_BORDER_WIDTH_WIDTH) {
            // Set value
            borderRight->value = FIXTOFLT(fixed);
            borderRight->unit = unit;
        }
    }
    
    // Set border bottom width
    result = css_computed_border_bottom_width(computedStyle, &fixed, &unit);
    if (result != CSS_BORDER_WIDTH_INHERIT) {
        // For width
        if (result == CSS_BORDER_WIDTH_WIDTH) {
            // Set value
            borderBottom->value = FIXTOFLT(fixed);
            borderBottom->unit = unit;
        }
    }
    
    // Set border left color
    result = css_computed_border_left_color(computedStyle, &color);
    if (result != CSS_COLOR_INHERIT) {
        if (result == CSS_COLOR_COLOR) {
            borderLeft->color.colorAlpha = (color & 0xff000000) >> 24;
            borderLeft->color.colorRed = (color & 0xff0000) >> 16;
            borderLeft->color.colorGreen = (color & 0xff00) >> 8;
            borderLeft->color.colorBlue = color & 0xff;
        }
    }
    
    // Set border top color
    result = css_computed_border_top_color(computedStyle, &color);
    if (result != CSS_COLOR_INHERIT) {
        if (result == CSS_COLOR_COLOR) {
            borderTop->color.colorAlpha = (color & 0xff000000) >> 24;
            borderTop->color.colorRed = (color & 0xff0000) >> 16;
            borderTop->color.colorGreen = (color & 0xff00) >> 8;
            borderTop->color.colorBlue = color & 0xff;
        }
    }
    
    // Set border right color
    result = css_computed_border_right_color(computedStyle, &color);
    if (result != CSS_COLOR_INHERIT) {
        if (result == CSS_COLOR_COLOR) {
            borderRight->color.colorAlpha = (color & 0xff000000) >> 24;
            borderRight->color.colorRed = (color & 0xff0000) >> 16;
            borderRight->color.colorGreen = (color & 0xff00) >> 8;
            borderRight->color.colorBlue = color & 0xff;
        }
    }
    
    // Set border bottom color
    result = css_computed_border_bottom_color(computedStyle, &color);
    if (result != CSS_COLOR_INHERIT) {
        if (result == CSS_COLOR_COLOR) {
            borderBottom->color.colorAlpha = (color & 0xff000000) >> 24;
            borderBottom->color.colorRed = (color & 0xff0000) >> 16;
            borderBottom->color.colorGreen = (color & 0xff00) >> 8;
            borderBottom->color.colorBlue = color & 0xff;
        }
    }
    
    // Set border left style
    result = css_computed_border_left_style(computedStyle);
    if (result != CSS_BORDER_STYLE_INHERIT) {
        borderLeft->style = result;
    }
    
    // Set border top style
    result = css_computed_border_top_style(computedStyle);
    if (result != CSS_BORDER_STYLE_INHERIT) {
        borderTop->style = result;
    }
    
    // Set border right style
    result = css_computed_border_right_style(computedStyle);
    if (result != CSS_BORDER_STYLE_INHERIT) {
        borderRight->style = result;
    }
    
    // Set border bottom style
    result = css_computed_border_bottom_style(computedStyle);
    if (result != CSS_BORDER_STYLE_INHERIT) {
        borderBottom->style = result;
    }
}

void SYCssContextSelectStyle(
        SYCssContext* cssContext, 
#if TARGET_OS_IPHONE
        HMXMLNode* node, 
#elif TARGET_OS_MAC
        NSXMLNode* node, 
#endif
        int writingMode, 
        SYTextInlineStyle* inlineStyle, 
        SYTextBlockStyle* blockStyle)
{
//NSLog(@"node %@, class %@", node.name, [(HMXMLElement*)node attributeForName:@"class"]);
    css_error   error;
    css_fixed   fixed;
    css_unit    unit;
    uint8_t     result;
    
    // Select style
    css_select_results* results;
    error = css_select_style(
            cssContext->context, 
            (__bridge void *)(node), 
            CSS_MEDIA_SCREEN, 
            NULL, 
            &_handler, 
            cssContext, 
            &results);
    if (error != CSS_OK) {
        NSLog(@"Failed to select style, error %d", error);
        
        return;
    }
    
    // Get computed style
    css_computed_style* computedStyle;
    computedStyle = results->styles[0];
    
    // For block
    if (blockStyle) {
        // Set background color
        css_color   color;
        result = css_computed_background_color(computedStyle, &color);
        if (result == CSS_COLOR_INHERIT) {
            // Set alpha 0 as no color
            blockStyle->backgroundColor.colorAlpha = 0;
        }
        else {
            if (result == CSS_COLOR_COLOR) {
                blockStyle->backgroundColor.colorAlpha = (color & 0xff000000) >> 24;
                blockStyle->backgroundColor.colorRed = (color & 0xff0000) >> 16;
                blockStyle->backgroundColor.colorGreen = (color & 0xff00) >> 8;
                blockStyle->backgroundColor.colorBlue = color & 0xff;
            }
        }
        
        // Clear margin
        blockStyle->marginLeft = 0;
        blockStyle->marginTop = 0;
        blockStyle->marginRight = 0;
        blockStyle->marginBottom = 0;
        
        // Set margin left
        result = css_computed_margin_left(computedStyle, &fixed, &unit);
        if (result != CSS_MARGIN_INHERIT) {
            blockStyle->marginLeft = FIXTOFLT(fixed);
            blockStyle->marginLeftUnit = unit;
        }
        
        // Set margin top
        result = css_computed_margin_top(computedStyle, &fixed, &unit);
        if (result != CSS_MARGIN_INHERIT) {
            blockStyle->marginTop = FIXTOFLT(fixed);
            blockStyle->marginTopUnit = unit;
        }
        
        // Set margin right
        result = css_computed_margin_right(computedStyle, &fixed, &unit);
        if (result != CSS_MARGIN_INHERIT) {
            blockStyle->marginRight = FIXTOFLT(fixed);
            blockStyle->marginRightUnit = unit;
        }
        
        // Set margin bottom
        result = css_computed_margin_bottom(computedStyle, &fixed, &unit);
        if (result != CSS_MARGIN_INHERIT) {
            blockStyle->marginBottom = FIXTOFLT(fixed);
            blockStyle->marginBottomUnit = unit;
        }
        
        // Clear padding
        blockStyle->paddingLeft = 0;
        blockStyle->paddingTop = 0;
        blockStyle->paddingRight = 0;
        blockStyle->paddingBottom = 0;
        
        // Set padding left
        result = css_computed_padding_left(computedStyle, &fixed, &unit);
        if (result != CSS_PADDING_INHERIT) {
            blockStyle->paddingLeft = FIXTOFLT(fixed);
            blockStyle->paddingLeftUnit = unit;
        }
        
        // Set padding top
        result = css_computed_padding_top(computedStyle, &fixed, &unit);
        if (result != CSS_PADDING_INHERIT) {
            blockStyle->paddingTop = FIXTOFLT(fixed);
            blockStyle->paddingTopUnit = unit;
        }
        
        // Set padding right
        result = css_computed_padding_right(computedStyle, &fixed, &unit);
        if (result != CSS_PADDING_INHERIT) {
            blockStyle->paddingRight = FIXTOFLT(fixed);
            blockStyle->paddingRightUnit = unit;
        }
        
        // Set padding bottom
        result = css_computed_padding_bottom(computedStyle, &fixed, &unit);
        if (result != CSS_PADDING_INHERIT) {
            blockStyle->paddingBottom = FIXTOFLT(fixed);
            blockStyle->paddingBottomUnit = unit;
        }
        
        // Set width
        result = css_computed_width(computedStyle, &fixed, &unit);
        if (result != CSS_WIDTH_INHERIT) {
            blockStyle->width = FIXTOFLT(fixed);
            blockStyle->widthUnit = unit;
        }
        
        // Set height
        result = css_computed_height(computedStyle, &fixed, &unit);
        if (result != CSS_WIDTH_INHERIT) {
            blockStyle->height = FIXTOFLT(fixed);
            blockStyle->heightUnit = unit;
        }
        
        // Set text align
        result = css_computed_text_align(computedStyle);
        if (result != CSS_TEXT_ALIGN_INHERIT) {
            switch (result) {
            case CSS_TEXT_ALIGN_LEFT: { blockStyle->textAlign = SYStyleTextAlignLeft; break; }
            case CSS_TEXT_ALIGN_RIGHT: { blockStyle->textAlign = SYStyleTextAlignRight; break; }
            case CSS_TEXT_ALIGN_CENTER: { blockStyle->textAlign = SYStyleTextAlignCenter; break; }
            case CSS_TEXT_ALIGN_JUSTIFY: { blockStyle->textAlign = SYStyleTextAlignJustify; break; }
            }
        }
        
        // Clear border
        memset(&blockStyle->borderLeft, 0, sizeof(SYTextBorder));
        memset(&blockStyle->borderTop, 0, sizeof(SYTextBorder));
        memset(&blockStyle->borderRight, 0, sizeof(SYTextBorder));
        memset(&blockStyle->borderBottom, 0, sizeof(SYTextBorder));
        
        // Select border style
        _selectBorderStyle(
                &blockStyle->borderLeft, 
                &blockStyle->borderTop, 
                &blockStyle->borderRight, 
                &blockStyle->borderBottom, 
                computedStyle, 
                inlineStyle->fontSize);
        
        // Set writing mode
        blockStyle->writingMode = writingMode;
    }
    
    // For inline
    if (inlineStyle) {
        // Set font
        lwc_string**    names;
        result = css_computed_font_family(computedStyle, &names);
        if (result != CSS_FONT_FAMILY_INHERIT) {
            if (result == CSS_FONT_FAMILY_SERIF) {
                inlineStyle->fontFamily = SYStyleFontFamilySerif;
            }
            else if (result == CSS_FONT_FAMILY_SANS_SERIF) {
                inlineStyle->fontFamily = SYStyleFontFamilySansSerif;
            }
            else if (result == CSS_FONT_FAMILY_MONOSPACE) {
                inlineStyle->fontFamily = SYStyleFontFamilyMonospace;
            }
            else if (result == CSS_FONT_FAMILY_CURSIVE) {
                inlineStyle->fontFamily = SYStyleFontFamilyCursive;
            }
            else if (result == CSS_FONT_FAMILY_FANTASY) {
                inlineStyle->fontFamily = SYStyleFontFamilyFantasy;
            }
        }
        
        // Set font size
        result = css_computed_font_size(computedStyle, &fixed, &unit);
        if (result != CSS_FONT_SIZE_INHERIT) {
            // For dimension
            if (result == CSS_FONT_SIZE_DIMENSION) {
                // Calculate font size immediately
                if (unit == CSS_UNIT_EX) {
                    inlineStyle->fontSize *= FIXTOFLT(fixed) * 0.6f; // For x-height
                }
                else if (unit == CSS_UNIT_EM) {
                    inlineStyle->fontSize *= FIXTOFLT(fixed);
                }
                else if (unit == CSS_UNIT_PCT) {
                    inlineStyle->fontSize *= FIXTOFLT(fixed) / 100.0f;
                }
                else {
                    inlineStyle->fontSize = FIXTOFLT(fixed);
                }
            }
            // For other
            else {
                // Decide font size
                float   fontSize;
                fontSize = FIXTOFLT(fixed);
                switch (result) {
                case CSS_FONT_SIZE_XX_SMALL: { fontSize = FIXTOFLT(_baseSizes[0].value); break; }
                case CSS_FONT_SIZE_X_SMALL: { fontSize = FIXTOFLT(_baseSizes[1].value); break; }
                case CSS_FONT_SIZE_SMALL: { fontSize = FIXTOFLT(_baseSizes[2].value); break; }
                case CSS_FONT_SIZE_MEDIUM: { fontSize = FIXTOFLT(_baseSizes[3].value); break; }
                case CSS_FONT_SIZE_LARGE: { fontSize = FIXTOFLT(_baseSizes[4].value); break; }
                case CSS_FONT_SIZE_X_LARGE: { fontSize = FIXTOFLT(_baseSizes[5].value); break; }
                case CSS_FONT_SIZE_XX_LARGE: { fontSize = FIXTOFLT(_baseSizes[6].value); break; }
                case CSS_FONT_SIZE_LARGER: { fontSize *= 1.1f; break; }
                case CSS_FONT_SIZE_SMALLER: { fontSize *= 0.9f; break; }
                }
            }
        }
        
        // Set font weight
        int fontWeight = SYStyleFontWeightNormal;
        result = css_computed_font_weight(computedStyle);
        if (result != CSS_FONT_WEIGHT_INHERIT) {
            // Switch by result
            switch (result) {
            case CSS_FONT_WEIGHT_NORMAL: { fontWeight = SYStyleFontWeightNormal; break; }
            case CSS_FONT_WEIGHT_BOLD: { fontWeight = SYStyleFontWeightBold; break; }
            case CSS_FONT_WEIGHT_BOLDER: { fontWeight = SYStyleFontWeightBolder; break; }
            case CSS_FONT_WEIGHT_LIGHTER: { fontWeight = SYStyleFontWeightLighter; break; }
            case CSS_FONT_WEIGHT_100: { fontWeight = 100; break; }
            case CSS_FONT_WEIGHT_200: { fontWeight = 200; break; }
            case CSS_FONT_WEIGHT_300: { fontWeight = 300; break; }
            case CSS_FONT_WEIGHT_400: { fontWeight = 400; break; }
            case CSS_FONT_WEIGHT_500: { fontWeight = 500; break; }
            case CSS_FONT_WEIGHT_600: { fontWeight = 600; break; }
            case CSS_FONT_WEIGHT_700: { fontWeight = 700; break; }
            case CSS_FONT_WEIGHT_800: { fontWeight = 800; break; }
            case CSS_FONT_WEIGHT_900: { fontWeight = 900; break; }
            }
            inlineStyle->fontWeight = fontWeight;
        }
        
        inlineStyle->fontStyle = SYStyleFontStyleNormal;
        inlineStyle->fontVariant = SYStyleFontVariantNormal;
        
        // Set line height
        result = css_computed_line_height(computedStyle, &fixed, &unit);
        if (result != CSS_LINE_HEIGHT_INHERIT) {
            // For dimension
            if (result == CSS_LINE_HEIGHT_DIMENSION) {
                // Get font size
                float   fontSize;
                fontSize = inlineStyle->fontSize;
                
                // Calc with font size
                if (unit == CSS_UNIT_EX) {
                    inlineStyle->lineHeight = FIXTOFLT(fixed) * 0.6f / fontSize; // For x-height
                }
                else if (unit == CSS_UNIT_EM) {
                    inlineStyle->lineHeight = FIXTOFLT(fixed);
                }
                else if (unit == CSS_UNIT_PCT) {
                    inlineStyle->lineHeight = FIXTOFLT(fixed) / 100.0f;
                }
                else {
                    inlineStyle->lineHeight = FIXTOFLT(fixed) / fontSize;
                }
            }
        }
        
        // Set color
        css_color   color;
        result = css_computed_color(computedStyle, &color);
        if (result != CSS_COLOR_INHERIT) {
            if (result == CSS_COLOR_COLOR) {
                inlineStyle->color.colorAlpha = (color & 0xff000000) >> 24;
                inlineStyle->color.colorRed = (color & 0xff0000) >> 16;
                inlineStyle->color.colorGreen = (color & 0xff00) >> 8;
                inlineStyle->color.colorBlue = color & 0xff;
            }
        }
        
        // Clear border
        memset(&inlineStyle->borderLeft, 0, sizeof(SYTextBorder));
        memset(&inlineStyle->borderTop, 0, sizeof(SYTextBorder));
        memset(&inlineStyle->borderRight, 0, sizeof(SYTextBorder));
        memset(&inlineStyle->borderBottom, 0, sizeof(SYTextBorder));
        
        // For no block style
        if (!blockStyle) {
            // Select border style
            _selectBorderStyle(
                    &inlineStyle->borderLeft, 
                    &inlineStyle->borderTop, 
                    &inlineStyle->borderRight, 
                    &inlineStyle->borderBottom, 
                    computedStyle, 
                    inlineStyle->fontSize);
        }
        
        // Set vertical align
        result = css_computed_vertical_align(computedStyle, &fixed, &unit);
        if (result != CSS_VERTICAL_ALIGN_INHERIT) {
            // Switch by result
            switch (result) {
            case CSS_VERTICAL_ALIGN_BASELINE: { inlineStyle->verticalAlign = SYStyleVerticalAlignBaseLine; break; }
            case CSS_VERTICAL_ALIGN_MIDDLE: { inlineStyle->verticalAlign = SYStyleVerticalAlignMiddle; break; }
            case CSS_VERTICAL_ALIGN_SUB: { inlineStyle->verticalAlign = SYStyleVerticalAlignSub; break; }
            case CSS_VERTICAL_ALIGN_SUPER: { inlineStyle->verticalAlign = SYStyleVerticalAlignSuper; break; }
            case CSS_VERTICAL_ALIGN_TEXT_TOP: { inlineStyle->verticalAlign = SYStyleVerticalAlignTextTop; break; }
            case CSS_VERTICAL_ALIGN_TEXT_BOTTOM: { inlineStyle->verticalAlign = SYStyleVerticalAlignTextBottom; break; }
            case CSS_VERTICAL_ALIGN_TOP: { inlineStyle->verticalAlign = SYStyleVerticalAlignTop; break; }
            case CSS_VERTICAL_ALIGN_BOTTOM: { inlineStyle->verticalAlign = SYStyleVerticalAlignBottom; break; }
            }
        }
        
        // Set float mode
        inlineStyle->floatMode = SYStyleFloatNone;
        
        // Set writing mode
        inlineStyle->writingMode = writingMode;
    }
    
    // Release computed style
    int i;
    for (i = 0; i < CSS_PSEUDO_ELEMENT_COUNT; i++) {
        if (results->styles[i]) {
            css_computed_style_destroy(results->styles[i]);
        }
    }
}

@implementation SYCss

// Property
@synthesize cssData = _cssData;
@synthesize baseFontSize = _baseFontSize;
@synthesize cssContext = _cssContext;

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Initialize instance variables
    _baseFontSize = 17.0f;
    _needsToParse = YES;
    _cssContext = NULL;
    _cacheDict = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)dealloc
{
    // Release CSS context
    if (_cssContext) {
        SYCssContextRelease(_cssContext), _cssContext = NULL;
    }
}

//--------------------------------------------------------------//
#pragma mark -- Property --
//--------------------------------------------------------------//

- (void)setCssData:(NSData*)cssData
{
    // Set CSS data
    _cssData = cssData;
    
    // Set flag
    _needsToParse = YES;
}

- (void)setBaseFontSize:(float)baseFontSize
{
    // Set base font size
    _baseFontSize = baseFontSize;
    
    // Set flag
    _needsToParse = YES;
}

- (SYCssContext*)cssContext
{
    // Check flag
    if (!_needsToParse && _cssContext) {
        return _cssContext;
    }
    
    // Release old CSS context
    if (_cssContext) {
        SYCssContextRelease(_cssContext), _cssContext = NULL;
    }
    
    // Parse CSS data
    _cssContext = SYCssContextCreate();
    SYCssContextSetBaseFontSize(_cssContext, _baseFontSize);
    SYCssContextAddStylesheetData(_cssContext, _cssData);
    
    // Clear flag
    _needsToParse = NO;
    
    return _cssContext;
}

//--------------------------------------------------------------//
#pragma mark -- Cache --
//--------------------------------------------------------------//

#if TARGET_OS_IPHONE
- (NSString*)_cacheKeyWithNode:(HMXMLNode*)node writingMode:(int)writingMode
#elif TARGET_OS_MAC
- (NSString*)_cacheKeyWithNode:(NSXMLNode*)node writingMode:(int)writingMode
#endif
{
    // Create key from name, id and class
    NSString*   key;
    NSString*   name;
    NSString*   identifier;
    NSString*   klass;
    name = node.name;
#if TARGET_OS_IPHONE
    identifier = [(HMXMLElement*)node attributeForName:@"id"];
    klass = [(HMXMLElement*)node attributeForName:@"class"];
#elif TARGET_OS_MAC
    identifier = [[(NSXMLElement*)node attributeForName:@"id"] stringValue];
    klass = [[(NSXMLElement*)node attributeForName:@"class"] stringValue];
#endif
    if (identifier && klass) {
        key = [NSString stringWithFormat:@"%@#%@.%@", name, identifier, klass];
    }
    else if (identifier) {
        key = [NSString stringWithFormat:@"%@#%@", name, identifier];
    }
    else if (klass) {
        key = [NSString stringWithFormat:@"%@.%@", name, klass];
    }
    else {
        key = name;
    }
    if (key) {// Add writing mode as suffix
        key = [NSString stringWithFormat:@"%@_%@", key, writingMode == SYStyleWritingModeLrTb ? @"lrtb" : @"tbrl"];
    }
    
    // Check parent node
#if TARGET_OS_IPHONE
    HMXMLNode*  parentNode;
#elif TARGET_OS_MAC
    NSXMLNode*  parentNode;
#endif
    NSString*   parentName;
    parentNode = node.parent;
    parentName = parentNode.name;
    if (![name isEqualToString:@"body"] && 
        parentName && 
        ![parentName isEqualToString:@"body"])
    {
        return [NSString stringWithFormat:@"%@/%@", [self _cacheKeyWithNode:parentNode writingMode:writingMode], key];
    }
    
    return key;
}

#ifdef CACHE_AND_NO_COPY
#if TARGET_OS_IPHONE
- (BOOL)cachedInlinStyle:(SYTextInlineStyle**)outInlineStyle 
        blockStyle:(SYTextBlockStyle**)outBlockStyle 
        forNode:(HMXMLNode*)node;
#elif TARGET_OS_MAC
- (BOOL)cachedInlinStyle:(SYTextInlineStyle**)outInlineStyle 
        blockStyle:(SYTextBlockStyle**)outBlockStyle 
        forNode:(NSXMLNode*)node;
#endif
#else
#if TARGET_OS_IPHONE
- (BOOL)cachedInlinStyle:(SYTextInlineStyle*)outInlineStyle 
        blockStyle:(SYTextBlockStyle*)outBlockStyle 
        forNode:(HMXMLNode*)node
        writingMode:(int)writingMode
#elif TARGET_OS_MAC
- (BOOL)cachedInlinStyle:(SYTextInlineStyle*)outInlineStyle 
        blockStyle:(SYTextBlockStyle*)outBlockStyle 
        forNode:(NSXMLNode*)node
        writingMode:(int)writingMode
#endif
#endif
{
    BOOL    result = NO;
    
    // Create key
    NSString*   key;
    key = [self _cacheKeyWithNode:node writingMode:writingMode];
    
    // Get cached inline style
    if (outInlineStyle) {
#ifdef CACHE_AND_NO_COPY
        // Get pointer
        NSNumber*   pointerNumber;
        pointerNumber = [_cacheDict objectForKey:[NSString stringWithFormat:@"%@_inline", key]];
        if (pointerNumber) {
            // Set inline style
            *outInlineStyle = (SYTextInlineStyle*)[pointerNumber unsignedIntegerValue];
            
            // Set flag
            result = YES;
        }
#else
        // Get inline style
        NSValue*    inlineStyleValue;
        inlineStyleValue = [_cacheDict objectForKey:[NSString stringWithFormat:@"%@_inline", key]];
        if (inlineStyleValue) {
            // Get value
            [inlineStyleValue getValue:outInlineStyle];
            
            // Set flag
            result = YES;
        }
#endif
    }
    
    // Get cached block style
    if (outBlockStyle) {
#ifdef CACHE_AND_NO_COPY
        // Get pointer
        NSNumber*   pointerNumber;
        pointerNumber = [_cacheDict objectForKey:[NSString stringWithFormat:@"%@_block", key]];
        if (pointerNumber) {
            // Set block style
            *outBlockStyle = (SYTextBlockStyle*)[pointerNumber unsignedIntegerValue];
            
            // Set flag
            result = YES;
        }
#else
        // Get block style
        NSValue*    blockStyleValue;
        blockStyleValue = [_cacheDict objectForKey:[NSString stringWithFormat:@"%@_block", key]];
        if (blockStyleValue) {
            // Get value
            [blockStyleValue getValue:outBlockStyle];
            
            // Set flag
            result = YES;
        }
#endif
    }
    
    return result;
}

#if TARGET_OS_IPHONE
- (void)cacheInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(HMXMLNode*)node
        writingMode:(int)writingMode
#elif TARGET_OS_MAC
- (void)cacheInlinStyle:(SYTextInlineStyle*)inlineStyle 
        blockStyle:(SYTextBlockStyle*)blockStyle 
        forNode:(NSXMLNode*)node
        writingMode:(int)writingMode
#endif
{
    // Create key
    NSString*   key;
    key = [self _cacheKeyWithNode:node writingMode:writingMode];
    
    // Cache inline style
    if (inlineStyle) {
#ifdef CACHE_AND_NO_COPY
        NSNumber*   pointerNumber;
        pointerNumber = [NSNumber numberWithUnsignedInteger:(NSUInteger)inlineStyle];
        [_cacheDict setObject:pointerNumber forKey:[NSString stringWithFormat:@"%@_inline", key]];
#else
        NSValue*    value;
        value = [NSValue valueWithBytes:inlineStyle objCType:@encode(SYTextInlineStyle)];
        [_cacheDict setObject:value forKey:[NSString stringWithFormat:@"%@_inline", key]];
#endif
    }
    
    // Cache block style
    if (blockStyle) {
#ifdef CACHE_AND_NO_COPY
        NSNumber*   pointerNumber;
        pointerNumber = [NSNumber numberWithUnsignedInteger:(NSUInteger)blockStyle];
        [_cacheDict setObject:pointerNumber forKey:[NSString stringWithFormat:@"%@_block", key]];
#else
        NSValue*    value;
        value = [NSValue valueWithBytes:blockStyle objCType:@encode(SYTextBlockStyle)];
        [_cacheDict setObject:value forKey:[NSString stringWithFormat:@"%@_block", key]];
#endif
    }
}

@end
