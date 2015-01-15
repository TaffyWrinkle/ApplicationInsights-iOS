#import "MSAIChannel.h"
#import "MSAIClientContext.h"
#import "MSAIEnvelope.h"
#import "MSAIHTTPOperation.h"
#import "MSAIAppClient.h"
#import "AppInsightsPrivate.h"
#import "MSAIData.h"

@implementation MSAIChannel{
  MSAIClientContext *_clientContext;
  MSAIAppClient *_appClient;
}

- (instancetype)initWithAppClient:(MSAIAppClient *) appClient clientContext:(MSAIClientContext *)clientContext{
  
  if ((self = [self init])) {
    _clientContext = clientContext;
    _appClient = appClient;
  }
  return self;
}

- (void)sendDataItem:(MSAITelemetryData *)dataItem{
  
  [dataItem setVersion:@(2)];
  
  MSAIData *data = [MSAIData new];
  [data setBaseData:dataItem];
  [data setBaseType:[dataItem dataTypeName]];
  
  MSAIEnvelope *envelope = [MSAIEnvelope new];
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  [envelope setTime:[dateFormatter stringFromDate:[NSDate date]]];
  [envelope setIKey:[_clientContext instrumentationKey]];
  [envelope setData:data];
  [envelope setName:[dataItem envelopeTypeName]];
  // set date & tags
  
  NSURLRequest *request = [self requestForDataItem:envelope];
  [self enqueueRequest:request];
}

- (NSURLRequest *)requestForDataItem:(MSAIEnvelope *)dataItem {
  
  NSMutableURLRequest *request = [_appClient requestWithMethod:@"POST"
                                                          path:[_clientContext endpointPath]
                                                    parameters:nil];
  
  NSString *dataString = [dataItem serializeToString];
  NSData *requestData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
  [request setHTTPBody:requestData];
  
  [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
  NSString *contentType = @"application/json";
  [request setValue:contentType forHTTPHeaderField:@"Content-type"];
  
  return request;
}

- (void)enqueueRequest:(NSURLRequest *)request{
  
  MSAIHTTPOperation *operation = [_appClient
                                  operationWithURLRequest:request
                                  completion:^(MSAIHTTPOperation *operation, NSData* responseData, NSError *error) {
                                    
                                    NSInteger statusCode = [operation.response statusCode];
                                    
                                    if (nil == error) {
                                      if (nil == responseData || [responseData length] == 0) {
                                        NSLog(@"Sending failed with an empty response!");
                                      } else{
                                        NSLog(@"Sent data with status code: %ld", (long)statusCode);
                                        NSLog(@"Response data:\n%@", [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil]);
                                      }
                                    }else{
                                      NSLog(@"Sending failed");
                                    }
                                  }];
  
  [_appClient enqeueHTTPOperation:operation];
}

@end
