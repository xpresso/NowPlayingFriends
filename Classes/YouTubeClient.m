//
//  YouTubeClient.m
//  NowPlayingFriends
//
//  Created by Hiroe Shin on 10/11/13.
//  Copyright 2010 hiroe_orz17. All rights reserved.
//

#import "YouTubeClient.h"


static void startElementHandler(
        void* ctx, 
        const xmlChar* localname, 
        const xmlChar* prefix, 
        const xmlChar* URI, 
        int nb_namespaces, 
        const xmlChar** namespaces, 
        int nb_attributes, 
        int nb_defaulted, 
        const xmlChar** attributes)
{
    [(YouTubeClient *)ctx 
		      startElementLocalName:localname 
		      prefix:prefix URI:URI 
		      nb_namespaces:nb_namespaces 
		      namespaces:namespaces 
		      nb_attributes:nb_attributes 
		      nb_defaulted:nb_defaulted 
		      attributes:attributes];
}

static void charactersFoundHandler(
        void* ctx, 
        const xmlChar* ch, 
        int len)
{
  [(YouTubeClient *)ctx
		    charactersFoundCharacter:ch
		    len:len];
}

static void endElementHandler(
        void* ctx, 
        const xmlChar* localname, 
        const xmlChar* prefix, 
        const xmlChar* URI)
{
  [(YouTubeClient *)ctx 
		    endElementLocalName:localname 
		    prefix:prefix 
		    URI:URI];
}

static xmlSAXHandler _saxHandlerStruct = {
    NULL,            /* internalSubset */
    NULL,            /* isStandalone   */
    NULL,            /* hasInternalSubset */
    NULL,            /* hasExternalSubset */
    NULL,            /* resolveEntity */
    NULL,            /* getEntity */
    NULL,            /* entityDecl */
    NULL,            /* notationDecl */
    NULL,            /* attributeDecl */
    NULL,            /* elementDecl */
    NULL,            /* unparsedEntityDecl */
    NULL,            /* setDocumentLocator */
    NULL,            /* startDocument */
    NULL,            /* endDocument */
    NULL,            /* startElement*/
    NULL,            /* endElement */
    NULL,            /* reference */
    charactersFoundHandler, /* characters */
    NULL,            /* ignorableWhitespace */
    NULL,            /* processingInstruction */
    NULL,            /* comment */
    NULL,            /* warning */
    NULL,            /* error */
    NULL,            /* fatalError //: unused error() get all the errors */
    NULL,            /* getParameterEntity */
    NULL,            /* cdataBlock */
    NULL,            /* externalSubset */
    XML_SAX2_MAGIC,  /* initialized */
    NULL,            /* private */
    startElementHandler,    /* startElementNs */
    endElementHandler,      /* endElementNs */
    NULL,            /* serror */
};

@interface YouTubeClient (Local)
- (void)startWithRequestString:(NSString *)urlString 
		     parameter:(NSString *)aParameter;
@end

@implementation YouTubeClient

- (void)dealloc {
  [super dealloc];
}

- (void)searchWithTitle:(NSString *)title artist:(NSString *)artist {

  NSString *parameter = [[NSString alloc] initWithFormat:@"%@,%@,Music",
					  artist, title];
  [self startWithRequestString:kYouTubeSearchURL parameter:parameter];
}

#pragma mark -

- (void)startWithRequestString:(NSString *)urlString 
		     parameter:(NSString *)aParameter {
  
  if (![self isCancelled]) {
    _parserContext = xmlCreatePushParserCtxt(&_saxHandlerStruct, self, NULL, 
					     0, NULL);

    CFStringRef ignoreString = CFSTR(";,/?:@&=+$#");
    NSMutableString *bodyString = 
      [NSMutableString stringWithFormat:@"%@category=%@&v=2",
		       urlString,
		       (NSString *)CFURLCreateStringByAddingPercentEscapes(  
						       kCFAllocatorDefault,
						       (CFStringRef)aParameter,
						       NULL,
                                                       ignoreString,
                                                       kCFStringEncodingUTF8)];

    NSLog(@"url: %@", bodyString);
    NSURLRequest *request = [NSURLRequest 
			      requestWithURL:[NSURL URLWithString:bodyString]];

    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isExecuting"]; 
    [NSURLConnection connectionWithRequest:request delegate:self];
  }
}

#pragma mark -
#pragma NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *) data {
  
  xmlParseChunk(_parserContext, (const char*)[data bytes], [data length], 0);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

  xmlParseChunk(_parserContext, NULL, 0, 1);
  NSLog(@"_link: %@", _link);
}


#pragma mark -
#pragma XML Parse Methods

- (void)startElementLocalName:(const xmlChar*)localname 
		       prefix:(const xmlChar*)prefix 
			  URI:(const xmlChar*)URI 
		nb_namespaces:(int)nb_namespaces 
		   namespaces:(const xmlChar**)namespaces 
		nb_attributes:(int)nb_attributes 
		 nb_defaulted:(int)nb_defaulted 
		   attributes:(const xmlChar**)attributes {

  if (strncmp((char*)localname, "entry", sizeof("entry")) == 0) {
    NSLog(@"entry in");
    _isEntry = YES;
    return;
  }

  if (strncmp((char*)localname, "link", sizeof("link")) == 0) {
    NSLog(@"link in");
    _isLink = YES;    
    _link = [NSMutableDictionary dictionary];
    [[_link objectForKey:@"link"] addObject:_currentItem];
    return;
  }
}

- (void)charactersFoundCharacter:(const xmlChar*)ch len:(int)len {
  
  NSLog(@"len:%d", len);

  if (_isEntry && _isLink) {
    printf("ch: %s", ch);
  }
}


- (void)endElementLocalName:(const xmlChar*)localname 
        prefix:(const xmlChar*)prefix URI:(const xmlChar*)URI {

  if (strncmp((char*)localname, "href", sizeof("href")) == 0 || 
      strncmp((char*)localname, "link", sizeof("link")) == 0) {

    NSString*   key;
    key = [NSString stringWithCString:(char*)localname 
		    encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *dict = nil;
    if (_isItem) {
      dict = _currentItem;
    }
    else if (_isEntry && _isLink) {
      dict = _link;
    }
    else if (_isChannel) {
      dict = _channel;
    }
    
    // 文字列を設定する
    if (_currentCharacters != nil) {
      [dict setObject:_currentCharacters forKey:key];
      [_currentCharacters release], _currentCharacters = nil;
    }
  }

  if (strncmp((char*)localname, "entry", sizeof("entry")) == 0) {
    _isEntry = NO;
  }

  if (strncmp((char*)localname, "link", sizeof("link")) == 0) {
    _isLink = NO;    
  }


}

@end