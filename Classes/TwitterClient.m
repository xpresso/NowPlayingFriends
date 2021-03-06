//
//  TwitterClient.m
//  NowPlayingFriends
//
//  Created by Hiroe Shin on 10/08/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "JSON/JSON.h"
#import "OAuthConsumer/OAConsumer.h"
#import "OAuthConsumer/OADataFetcher.h"
#import "OAuthConsumer/OAMutableURLRequest.h"
#import "OAuthConsumer/OARequestParameter.h"
#import "TwitterClient.h"
#import "TwitterFriendsGetter.h"


@interface TwitterClient (Local) 

- (OAMutableURLRequest *)authenticatedRequest:(NSURL *)url;
- (NSURL*)authenticatedURL:(NSURL *)url;

- (NSString *)urlEncodedString:(NSString *)str;
- (NSArray *)arrayOfRemoteJson:(NSString *)urlString;
- (NSDictionary *)dictionaryOfRemoteJson:(NSString *)urlString;
- (NSString *)stringOfRemoteJson:(NSString *)urlString;
- (void)logJsonData:(NSArray *)jsonArray;

@end


@implementation TwitterClient

#pragma mark -
#pragma Twitter Get TimeLine Methods

/**
 * @brief フォローしているユーザのリストを取得して保存します。
 */
- (void)saveFriends {

  NSFileManager *fileManager = [NSFileManager defaultManager];
  TwitterFriendsGetter *getter = [[TwitterFriendsGetter alloc] init];

  NSString *tmpFilePath = [getter tmpFilePath];

  [getter release];

  if ([fileManager fileExistsAtPath:tmpFilePath]) {
    NSError *error;
    [fileManager removeItemAtPath:tmpFilePath error:&error];
  }

  [self saveFriendsWithCursor:[NSNumber numberWithInteger:-1]];
}

- (void)saveFriendsWithCursor:(NSNumber *)cursorNumber {

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kTwitterFrindsSearchUrl,
			  [self username], cursorNumber];

  NSURL *baseUrl = [NSURL URLWithString:urlString];
  OAMutableURLRequest *request = [self authenticatedRequest:baseUrl];
  [request setHTTPMethod:@"GET"];

  /* このインスタンスのリリースは自分でやらせています 
     ticket:didFinishWithData 内。
   */
  TwitterFriendsGetter *getter = [[TwitterFriendsGetter alloc] init];

  OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
  [fetcher fetchDataWithRequest:request
	   delegate:getter
	   didFinishSelector:@selector(ticket:didFinishWithData:)
	   didFailSelector:@selector(ticket:didFailWithError:)];
}

/**
 * @brief 指定されたユーザをフォローします。
 */
- (void)followUser:(NSString *)usernameOrId delegate:(id)aDelegate {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kCreateFriendURL, usernameOrId];

  NSURL *baseUrl = [NSURL URLWithString:urlString];
  OAMutableURLRequest *request = [self authenticatedRequest:baseUrl];

  OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
  [fetcher fetchDataWithRequest:request
	   delegate:aDelegate
	   didFinishSelector:@selector(ticket:didFinishWithData:)
	   didFailSelector:@selector(ticket:didFailWithError:)];
}

/**
 * @brief 指定されたユーザを既にフォローしている場合はYESを返します。
 */
- (BOOL)checkFollowing:(NSString *)username {

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kCheckFriendShipURL, username];

  NSDictionary *response = [self dictionaryOfRemoteJson:urlString];
  NSDictionary *relationship = [response objectForKey:@"relationship"];
  NSDictionary *target = [relationship objectForKey:@"target"];
  NSInteger result = [[target objectForKey:@"following"] integerValue];

  return (result == 1);
}


/**
 * @brief 指定されたユーザのタイムラインを取得します。
 */
- (NSArray *)getHomeTimeLine:(NSString *)username 
		     sinceId:(NSNumber *)sinceId; {

  NSInteger aCount = 50;
  NSString *params = nil;

  if (sinceId == nil) {
    params = [[NSString alloc] initWithFormat:@"?count=%d", aCount];
  } else {
    params = [[NSString alloc] initWithFormat:@"?since_id=%@&count=%d", 
			       sinceId, aCount];
  }

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kHomeTimelineURL, username, params];

  [params release];
  return [self arrayOfRemoteJson:urlString];
}

- (NSArray *)getUserTimeLine:(NSString *)username
		     sinceId:(NSNumber *)sinceId {

  NSInteger aCount = 40;
  NSString *params = nil;

  if (sinceId == nil) {
    params = [[NSString alloc] initWithFormat:@"?count=%d", aCount];
  } else {
    params = [[NSString alloc] initWithFormat:@"?since_id=%@&count=%d", 
			       sinceId, aCount];
  }

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kUserTimelineURL, username, params];
  [params release];
  return [self arrayOfRemoteJson:urlString];
}

- (NSArray *)getMentionsTimeLineSince:(NSNumber *)sinceId {

  if (![self oAuthTokenExist]) {
    return [NSArray array];
  }

  NSInteger aCount = 40;
  NSString *params = nil;

  if (sinceId == nil) {
    params = [[NSString alloc] initWithFormat:@"?count=%d", aCount];
  } else {
    params = [[NSString alloc] initWithFormat:@"?since_id=%@&count=%d", 
			       sinceId, aCount];
  }

  NSString *urlString = [[NSString alloc] initWithFormat:kMenthonsTimelineURL,
			 params];
  NSLog(@"url: %@", urlString);
  [params release];
  return [self arrayOfRemoteJson:urlString];
}

- (void)updateStatus:(NSString *)message
   inReplyToStatusId:(NSNumber *)replayToStatusId
	    delegate:(id)aDelegate {

  if (![self oAuthTokenExist]) {
    return;
  }

  NSURL *baseUrl = [NSURL URLWithString:kUpdateStatusURL];
  OAMutableURLRequest *request = [self authenticatedRequest:baseUrl];


  CFStringRef ignoreString = CFSTR(";,/?:@&=+$#");
  NSMutableString *bodyString = 
    [NSMutableString stringWithFormat:@"status=%@",
		     (NSString *)CFURLCreateStringByAddingPercentEscapes(  
						       kCFAllocatorDefault,
						       (CFStringRef)message,
						       NULL,
                                                       ignoreString,
                                                       kCFStringEncodingUTF8)];
  if (replayToStatusId != nil) {
    NSMutableString *replyParameter = [[NSMutableString alloc] 
				     initWithString:@"&in_reply_to_status_id="];
    [replyParameter appendString:[replayToStatusId stringValue]];
    [bodyString appendString:replyParameter];
    [replyParameter release];
  }

  [request setHTTPBody:[bodyString dataUsingEncoding:NSUTF8StringEncoding]];

  OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
  [fetcher fetchDataWithRequest:request
	   delegate:aDelegate
	   didFinishSelector:@selector(ticket:didFinishWithData:)
	   didFailSelector:@selector(ticket:didFailWithError:)];

}

- (NSArray *)getSearchTimeLine:(NSString *)searchString, ... {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  NSString *eachObject;
  va_list argumentList;
  NSMutableString *urlString;
  NSString *encodedString;

  if (searchString) {
    encodedString = [self urlEncodedString:searchString];
    urlString = [[NSMutableString alloc] 
		  initWithFormat:kSearchURL, encodedString];
    
    va_start(argumentList, searchString);
    
    while(eachObject = va_arg(argumentList, id)) {
      encodedString = [self urlEncodedString:eachObject];
      [urlString appendString:@"+"];
      [urlString appendString:encodedString];
    }    
    va_end(argumentList);
  }

  NSURL *url = [NSURL URLWithString:urlString];
  [urlString release];

  NSString *jsonString = [[NSString alloc] initWithContentsOfURL:url
					   encoding:NSUTF8StringEncoding
					   error:nil];

  NSDictionary *jsonDictionary = [jsonString JSONValue];
  NSArray *jsonArray = [jsonDictionary objectForKey:@"results"];
  [jsonString release];

  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  return jsonArray;
}

/**
 * @brief ツイッターユーザの情報を返します。
 */
- (NSDictionary *)userInformation:(NSString *)username {

  NSString *urlString = [[NSString alloc] 
			  initWithFormat:kUserInformationURL, username];

  NSDictionary *user = [self dictionaryOfRemoteJson:urlString];
  [urlString release];

  return user;
}

/**
 * @brief URLエンコードされた文字列を返します。
 */
- (NSString *)urlEncodedString:(NSString *)str {
  
  CFStringRef ignoreString = CFSTR(";,/?:@&=+$#");
  NSString *encodedString = 
    (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  
							(CFStringRef)str,
							NULL,  
							ignoreString,
							kCFStringEncodingUTF8);
  return [encodedString autorelease];
}

/**
 * @brief 認証情報を埋めこんだRequestオブジェクトを生成する。
 */
- (id)authenticatedRequest:(NSURL *)url {

  if (![self oAuthTokenExist]) {
    NSMutableURLRequest *notAuthencticatedRequest = 
      [NSMutableURLRequest requestWithURL:url];

    return notAuthencticatedRequest;
  }

  OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kConsumerKey
					     secret:kConsumerSecret];
  [consumer autorelease];

  NSDictionary *token = [self oAuthToken];

  OAToken *accessToken =
    [[[OAToken alloc] initWithKey:[token objectForKey:@"oauth_token"]
		      secret:[token objectForKey:@"oauth_token_secret"]] 
      autorelease];

  OAMutableURLRequest *request = 
    [[OAMutableURLRequest alloc] initWithURL:url
				 consumer:consumer
				 token:accessToken
				 realm:nil
				 signatureProvider:nil];
  [request autorelease];
  [request setHTTPMethod:@"POST"];

  return request;
}

/**
 * @brief 認証がすんでいる場合は認証情報を埋めこんだURLオブジェクトを生成する。
 *        すんでいない場合は引数で与えられたURLをそのまま返す。
 */
- (NSURL*)authenticatedURL:(NSURL *)url {

  if (![self oAuthTokenExist]) {
    return url;
  }

  OAMutableURLRequest *request = [self authenticatedRequest:url];
  return [request URL];
}

/**
 * @brief 渡されたURL文字列からJSONデータを取得しArrayにパースして返します。
 */
- (NSArray *)arrayOfRemoteJson:(NSString *)urlString {

  NSString *jsonString = [self stringOfRemoteJson:urlString];
  NSArray *jsonArray = [jsonString JSONValue];
  
  if ([jsonArray isKindOfClass:[NSDictionary class]]) {
    NSLog(@"invalid data received: &@", jsonArray);
    return [NSArray array];
  }

  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  return jsonArray;
}

/**
 * @brief 渡されたURL文字列からJSONデータを取得しNSDictionaryにパースして返します。
 */
- (NSDictionary *)dictionaryOfRemoteJson:(NSString *)urlString {

  NSString *jsonString = [self stringOfRemoteJson:urlString];
  NSDictionary *jsonDictionary = [jsonString JSONValue];
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  return jsonDictionary;
}

/**
 * @brief 渡されたURLから得られたJSON文字列を返します。
 */
- (NSString *)stringOfRemoteJson:(NSString *)urlString {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  OAMutableURLRequest *request = 
    [self authenticatedRequest:[NSURL URLWithString:urlString]];
  [request setHTTPMethod:@"GET"];
  [request prepare];

  NSURLResponse *response;
  NSError *error;
  NSData *data = [NSURLConnection sendSynchronousRequest:request
				  returningResponse:&response
				  error:&error];

  NSString *jsonString = [[NSString alloc] initWithData:data
					   encoding:NSUTF8StringEncoding];  
  return [jsonString autorelease];
}

- (void)logJsonData:(NSArray *)jsonArray {

  for (NSDictionary *dic in jsonArray) {
    NSDictionary *user = [dic valueForKey:@"user"];

    NSLog(@"user: %@", [user objectForKey:@"name"]);
    NSLog(@"image: %@", [user objectForKey:@"profile_image_url"]);
    NSLog(@"text: %@", [dic objectForKey:@"text"]);
    NSLog(@"created_at: %@", [dic objectForKey:@"created_at"]);
  }
}

#pragma mark -
#pragma Twitter Post Methods

#pragma mark -
#pragma Get AccessToken Methods

/**
 * @brief ユーザ名とパスワードからユーザのアクセストークンを取得する。
 */
- (void)getAccessTokenWithUsername:(NSString *)username 
			  password:(NSString *)password
			  delegate:(id)delegate {
  NSURL *url = 
    [NSURL URLWithString:kOAuthTokenUrl];

  OAConsumer *consumer = [[OAConsumer alloc] initWithKey:kConsumerKey
					     secret:kConsumerSecret];
  OAMutableURLRequest 
    *request = [[OAMutableURLRequest alloc] initWithURL:url
					    consumer:consumer
					    token:nil
					    realm:nil
					    signatureProvider:nil];
  [consumer release];

  // 新たに付加するパラメータ
  NSMutableArray *xAuthParameters = [NSMutableArray arrayWithCapacity:3];
  [xAuthParameters addObject:[OARequestParameter 
			       requestParameter:@"x_auth_mode" 
			       value:@"client_auth"]];

  [xAuthParameters addObject:[OARequestParameter 
			       requestParameter:@"x_auth_username" 
			       value:username]];

  [xAuthParameters addObject:[OARequestParameter 
			       requestParameter:@"x_auth_password" 
			       value:password]];

  // 順番が大事！
  [request setHTTPMethod:@"POST"];
  [request setParameters:xAuthParameters];

  OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [fetcher fetchDataWithRequest:request
	   delegate:delegate
	   didFinishSelector:@selector(ticket:didFinishWithData:)
	   didFailSelector:@selector(ticket:didFailWithError:)];

  [request release];
}

- (void)ticket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {

  NSLog(@"didFinishWithData");
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  NSString *dataString = [[NSString alloc] 
			   initWithData:data encoding:NSUTF8StringEncoding];

  NSLog(@"data: %@", dataString);
  [dataString release];
}

- (void)ticket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
  NSLog(@"didFailWithError");
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (NSDictionary *)oAuthToken {

  NSString *filename = [self oAuthAccessTokenFileName];
  NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:filename];
  return [dic autorelease];
}

- (BOOL)oAuthTokenExist {

  BOOL result;

  if ([self oAuthToken] == nil) {
    result = NO;
  } else {
    result = YES;
  }

  return result;
}

- (NSString *)username {
  
  NSDictionary *token = [self oAuthToken];
  NSString *username = nil;

  if (token != nil) {
    username = [token objectForKey:@"screen_name"];
  }

  return username;
}

- (NSString *)oAuthAccessTokenFileName {

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
						       NSUserDomainMask, YES);

  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filename = 
    [documentsDirectory stringByAppendingPathComponent:kOAuthAccetokenFileName];

  return filename;
}

@end
