//
//  JMRequestNetWorkCache.m
//  ssss
//
//  Created by 雷建民 on 16/9/25.
//  Copyright © 2016年 雷建民. All rights reserved.
//

#import "JMRequestNetWorkCache.h"
#import "YTKKeyValueStore.h"
#import "AFHTTPSessionManager.h"
#import "Reachability.h"

#        define BaseURL              @"https://api.test.hooclub.com/"
#define PATH_OF_NetWork    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define NSLog(format, ...) printf("\n[%s] %s\n [第%d行] ➡️➡️➡️\n %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else
#define NSLog(format, ...)
#endif



typedef NS_ENUM(NSUInteger, JMNetworkStatus) {
    JMNetworkStatusUnknown,  //未知的网络
    JMNetworkStatusNotNetWork, //没有网络
    JMNetworkStatusReachableViaWWAN,//手机蜂窝数据网络
    JMNetworkStatusReachableViaWiFi //WIFI 网络
};


@interface JMRequestNetWorkCache ()
@end

@implementation JMRequestNetWorkCache

static NSString *const  httpCache = @"NetworkCache";
static YTKKeyValueStore *_store;
static NSString         *_baseUrl;
static AFHTTPSessionManager *manager;
static JMRequestNetWorkCache *sharedMethod;

+ (JMRequestNetWorkCache *)sharedMethod
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMethod = [[JMRequestNetWorkCache alloc]init];
        manager = [AFHTTPSessionManager manager];
    });
    return sharedMethod;
}

- (void)setIsLoading:(BOOL)isLoading
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible =  isLoading;
}

- (void)setIsDebug:(BOOL)isDebug
{
    _isDebug =  isDebug;
}

- (AFSecurityPolicy*)getCustomHttpsPolicy:(AFHTTPSessionManager*)manager
{
    
    NSString *certFilePath;
    
    //https 公钥证书配置
    
    if ([BaseURL hasPrefix:@"https://api.p"]) {
        
        certFilePath = [[NSBundle mainBundle] pathForResource:@"ca_p" ofType:@"der"];
        
    }else if ([BaseURL hasPrefix:@"https://api.test"]) {
        
        certFilePath = [[NSBundle mainBundle] pathForResource:@"ca_test" ofType:@"der"];
        
    }else if ([BaseURL hasPrefix:@"https://rest"]) {
        
        certFilePath = [[NSBundle mainBundle] pathForResource:@"ca_rest" ofType:@"der"];
        
    }
    
    NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
    
    NSSet *certSet = [NSSet setWithObject:certData];
    
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
    
    policy.allowInvalidCertificates = YES;// 是否允许自建证书或无效证书（重要！！！）
    
    return policy;
    
}

/**
 创建网络缓存数据库和表
 */
- (void)creatNetWorkDataBase
{
    _store = [[YTKKeyValueStore alloc] initDBWithName:httpCache];
    [_store createTableWithName:httpCache];
    [JMRequestNetWorkCache updateBaseUrl:BaseURL];//设置 baseurl
}

+ (AFHTTPSessionManager *)manager
{
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    //设置请求的超时时间
    manager.requestSerializer.timeoutInterval = 20.f;
    //设置服务器返回结果的类型:JSON (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                         @"application/json",
                                                         @"text/html",
                                                         @"charset=UTF-8",
                                                         @"text/json",
                                                         @"text/plain",
                                                         @"text/javascript",
                                                         @"text/xml",
                                                         @"image/*",
                                                         @"multipart/form-data",nil];
    [JMRequestNetWorkCache sharedMethod].isDebug = YES;
    return manager;
}

/**
 设置网络请求的baseUrl
 
 @param baseUrl 服务器的baseUrl
 */
+ (void)updateBaseUrl:(NSString *)baseUrl
{
    _baseUrl = baseUrl;
}

+(NSString *)setRequestURLWithPath:(NSString *)path
{
    if (!_baseUrl || _baseUrl.length == 0) {
        if (!path || path.length == 0) {
            NSLog(@"baseURL by appending path  is  not exist！");
            return nil;
        }else if ([path hasPrefix:@"http"] || [path hasPrefix:@"https"]) {
            return path;
        }
        
    }else if ([_baseUrl hasPrefix:@"http"] || [_baseUrl hasPrefix:@"https"]) {
        return [_baseUrl stringByAppendingString:path];
    }
    return nil;
}

/**
 设置 请求和响应类型和超时时间
 
 @param requestType  默认为请求类型为JSON格式
 @param responseType 默认响应格式为JSON格式
 @param timeOut      请求超时时间 默认为20秒
 */
+(void)setTimeOutWithTime:(NSTimeInterval)timeOut
              requestType:(JMRequestSerializer)requestType
             responseType:(JMResponseSerializer)responseType
{
    
    
    manager.requestSerializer.timeoutInterval = timeOut;
    switch (requestType) {
        case JMRequestSerializerJSON:
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case JMRequestSerializerPlainText:
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
    }
    switch (responseType) {
        case JMResponseSerializerJSON:
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case JMResponseSerializerHTTP:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case JMResponseSerializerXML:
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
    }
}
/**
 设置 请求头
 
 @param httpBody 根据服务器要求 配置相应的请求体
 */
+ (void)setHttpBodyWithDic:(NSDictionary *)httpBody
{
    for (NSString *key in httpBody.allKeys) {
        if (httpBody[key] != nil) {
            [manager.requestSerializer setValue:httpBody[key] forHTTPHeaderField:key];
        }
    }
}


/**
 获取当前的网络状态
 
 @return YES 有网  NO 没有联网
 */
+(BOOL)getCurrentNetWorkStatus
{
    BOOL isExistenceNetwork;
    Reachability *reachability = [Reachability reachabilityWithHostName:@"www.apple.com"];
    switch([reachability currentReachabilityStatus]){
        case NotReachable: isExistenceNetwork = FALSE;
            break;
        case ReachableViaWWAN: isExistenceNetwork = TRUE;
            break;
        case ReachableViaWiFi: isExistenceNetwork = TRUE;
            break;
    }
    return isExistenceNetwork;
}

/**
 获取单个文件大小
 
 @param path 文件路径
 @return 大小size
 */
+(float)fileSizeAtPath:(NSString *)path{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:path]){
        long long size=[fileManager attributesOfItemAtPath:path error:nil].fileSize;
        return size/1024.0/1024.0;
    }
    return 0;
}
/**
 获取网络缓存 文件大小
 
 @return size  单位M
 */
+ (NSString *)fileSizeWithDBPath
{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    float folderSize = 0.0;
    if ([fileManager fileExistsAtPath:PATH_OF_NetWork]) {
        NSArray *childerFiles=[fileManager subpathsAtPath:PATH_OF_NetWork];
        for (NSString *fileName in childerFiles) {
            NSString *absolutePath=[PATH_OF_NetWork stringByAppendingPathComponent:fileName];
            folderSize += [JMRequestNetWorkCache fileSizeAtPath:absolutePath];
        }
        //SDWebImage框架自身计算缓存的实现
        //folderSize+=[[SDImageCache sharedImageCache] getSize]/1024.0/1024.0;
        return [NSString stringWithFormat:@"%.2fM",folderSize];
    }
    return @"0.00M";
}

/**
 清除所有网络缓存
 */
+ (void)cleanNetWorkRefreshCache
{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:PATH_OF_NetWork]) {
        NSArray *childerFiles=[fileManager subpathsAtPath:PATH_OF_NetWork];
        for (NSString *fileName in childerFiles) {
            NSString *absolutePath=[PATH_OF_NetWork stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:absolutePath error:nil];
        }
    }
    //[[SDImageCache sharedImageCache] cleanDisk];
}

#pragma mark -  /**************GET 请求API ******************/

+ (void )getWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail
{
    [self getWithUrl:url refreshCache:refreshCache params:nil success:success fail:fail];
}
// 多一个params参数
+ (void )getWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
             params:(NSDictionary *)params
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail
{
    [self getWithUrl:url refreshCache:refreshCache params:params progress:nil success:success fail:fail];
}
/**
 GET 请求 带有进度回调的 API
 
 @param url          请求的url
 @param refreshCache 是否对该页面进行缓存
 @param params       请求数据向服务器传的参数
 @param progress     请求进度回调
 @param success      请求成功回调
 @param fail         请求失败回调
 
 
 */

+ (void )getWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
             params:(NSDictionary *)params
           progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail
{
    
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    NSString *requestURL = [self setRequestURLWithPath:url];
    if (!requestURL || requestURL.length == 0) { NSLog(@"url is not exist"); return ; }
    // https 验证 manager.securityPolicy = [sharedMethod getCustomHttpsPolicy:manager];
    
    if ([self getCurrentNetWorkStatus]) {
        if (!refreshCache) {
            [self requestNotCacheWithHttpMethod:0 url:requestURL params:params progress:progress success:success fail:fail];
        }else {
            NSDictionary *dict =   [_store getObjectById:requestURL  fromTable:httpCache];
            if (dict) {
               if ([JMRequestNetWorkCache sharedMethod].isDebug)  NSLog(@"取出本地缓存成功dic = %@",dict);
                [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                success(dict);
            }else {
                [ manager GET:requestURL parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                    progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [_store putObject:responseObject withId:requestURL intoTable:httpCache];
                    success(responseObject);
                    if ([JMRequestNetWorkCache sharedMethod].isDebug) NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",requestURL,params,responseObject);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    fail(error);
                 if ([JMRequestNetWorkCache sharedMethod].isDebug)  NSLog(@"\nRequest error, URL: %@\n params:%@\n error:%@",url,params,error.description);
                }];
            }
        }
    }else {
        NSDictionary *dict =   [_store getObjectById:requestURL  fromTable:httpCache];
        if (dict) {
            success(dict);
        }else {
           if ([JMRequestNetWorkCache sharedMethod].isDebug)  NSLog(@"当前为无网络状态，本地也没有缓存数据");
        }
    }
}
#pragma mark - /*********************** POST 请求API **********************/

+ (void )postWithUrl:(NSString *)url
        refreshCache:(BOOL)refreshCache
              params:(NSDictionary *)params
             success:(void(^)(id responseObject))success
                fail:(void(^)(NSError *error))fail
{
    [self postWithUrl:url refreshCache:refreshCache params:params progress:nil success:success fail:fail];
}

+ (void)postWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
             params:(NSDictionary *)params
           progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail
{
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    NSString *requestURL = [self setRequestURLWithPath:url];
    if (!requestURL || requestURL.length == 0) { NSLog(@"url is not exist"); return ; }
    manager.securityPolicy = [sharedMethod getCustomHttpsPolicy:manager];
    if ([self getCurrentNetWorkStatus]) {
        if (!refreshCache) {
            [self requestNotCacheWithHttpMethod:1 url:requestURL params:params progress:progress success:success fail:fail];
        }else {
            NSDictionary *dict =   [_store getObjectById:requestURL  fromTable:httpCache];
            if (dict) {
              if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"取出本地缓存成功dic = %@",dict);
                success(dict);
            }else {
                [manager POST:requestURL parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                    progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    [_store putObject:responseObject withId:requestURL intoTable:httpCache];
                    [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                    success(responseObject);
                  if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",url,params,responseObject);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                    fail(error);
                  if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest error, URL: %@\n params:%@\n error:%@",url,params,error.description);
                }];
            }
        }
    }else {
        NSDictionary *dict =   [_store getObjectById:requestURL  fromTable:httpCache];
        if (dict) {
            [JMRequestNetWorkCache sharedMethod].isLoading = NO;
            success(dict);
        }else {
            NSError *error;
            [JMRequestNetWorkCache sharedMethod].isLoading = NO;
            fail(error);
           if ([JMRequestNetWorkCache sharedMethod].isDebug)  NSLog(@"当前为无网络状态，本地也没有缓存数据");
        }
    }
}

/**
 不进行缓存时，进行网络请求的方法
 
 @param httpMethod  0 ： 代表GET请求     1：代表POST请求
 @param url        请求的url
 @param params     请求参数
 @param progress   请求进度回调
 @param success    请求成功回调
 @param fail       请求失败回调
 */
+ (void )requestNotCacheWithHttpMethod:(NSInteger)httpMethod
                                   url:(NSString *)url
                                params:(NSDictionary *)params
                              progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
                               success:(void(^)(id responseObject))success
                                  fail:(void(^)(NSError *error))fail
{
    if (!url || url.length == 0) {
        NSLog(@"url is not exist");
        return ;
    }
    if (httpMethod == 0) {
        [manager GET:url parameters:params progress:nil
             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                 [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                 success(responseObject);
               if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",url,params,responseObject);
             } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                 [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                 fail(error);
               if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest error, URL: %@\n params:%@\n error:%@",url,params,error.description);
             }];
    }else {
        [manager POST:url parameters:params progress:nil
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                  [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                  success(responseObject);
               if ([JMRequestNetWorkCache sharedMethod].isDebug)    NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",url,params,responseObject);
              } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                  [JMRequestNetWorkCache sharedMethod].isLoading = NO;
                  fail(error);
                if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest error, URL: %@\n params:%@\n error:%@",url,params,error.description);
              }];
        
    }
    
}



/**
 PUT 请求  API
 
 @param url          请求的url
 @param params       请求数据向服务器传的参数
 @param success      请求成功回调
 @param fail         请求失败回调
 
 */
+ (void )putWithUrl:(NSString *)url
             params:(NSDictionary *)params
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail
{
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    NSString *requestURL = [self setRequestURLWithPath:url];
    if (!requestURL || requestURL.length == 0) {
        NSLog(@"url is not exist");
        return ;
    }
    [ manager PUT:requestURL parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
        success(responseObject);
      if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",requestURL,params,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
      if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"request error = %@",error.description);
        fail(error);
    }];
}



/**
 DELETE 请求  API
 
 @param url          请求的url
 @param params       请求数据向服务器传的参数
 @param success      请求成功回调
 @param fail         请求失败回调
 
 */
+ (void )deleteWithUrl:(NSString *)url
                params:(NSDictionary *)params
               success:(void(^)(id responseObject))success
                  fail:(void(^)(NSError *error))fail
{
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    NSString *requestURL = [self setRequestURLWithPath:url];
    if (!requestURL || requestURL.length == 0) {
        NSLog(@"url is not exist");
        return ;
    }
    [manager DELETE:requestURL parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
        success(responseObject);
      if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",requestURL,params,responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
       if ([JMRequestNetWorkCache sharedMethod].isDebug)  NSLog(@"request error = %@",error.description);
        fail(error);
    }];
}

/**
  表单提交 单图上传接口

 @param url url 请求url
 @param param 请求参数
 @param fileUrl 图片url路径
 @param name 后台字段 图片名字
 @param fileName  图片名字
 @param progress 请求进度
 @param success 请求成功回调
 @param fail 请求失败回调
 */
+ (void)postFromDataWithUrl:(NSString *)url
                      param:(NSDictionary *)param
                    fileUrl:(NSString *)fileUrl
                       name:(NSString *)name
                   fileName:(NSString *)fileName
                   progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
                    success:(void(^)(id responseObject))success
                       fail:(void(^)(NSError *error))fail
{
    NSString *requestURL = [self setRequestURLWithPath:url];
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    if (!requestURL || requestURL.length == 0) {
        NSLog(@"url is not exist");
        return ;
    }
    [manager POST:requestURL parameters:param constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error;
        BOOL result  = [formData appendPartWithFileURL:[NSURL fileURLWithPath:fileUrl] name:name fileName:fileName mimeType:@"image/jpeg" error:&error];
        if (result) {
            NSLog(@"表单提交成功");
         if ([JMRequestNetWorkCache sharedMethod].isDebug)    NSLog(@"\n urls = %@ \n name = %@ \n fileName = %@",fileUrl,name,fileName);
        }else {
         if ([JMRequestNetWorkCache sharedMethod].isDebug)    NSLog(@"\n urls = %@ \n name = %@ \n fileName = %@ , \n error = %@",fileUrl,name,fileName,error.description);
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"总进度 %lld  当前进度 %lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
      if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",requestURL,param,responseObject);
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
     if ([JMRequestNetWorkCache sharedMethod].isDebug)    NSLog(@"error = %@",error.description);
        fail(error);
    }];
    
}


/**
 表单提交 多图上传接口

 @param url 请求url
 @param params 请求参数
 @param urls 请求图片urls路径数组
 @param name 后台字段名字数组
 @param fileName  图片名字数组
 @param mimeType 图片类型
 @param progress 请求进度
 @param success 请求成功回调
 @param fail 请求失败回调
 */
+ (void)postFromDataWithUrl:(NSString *)url
                     params:(NSDictionary *)params
                       urls:(NSArray *)urls
                       name:(NSArray *)name
                   fileName:(NSArray *)fileName
                   mimeType:(NSString *)mimeType
                   progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
                    success:(void(^)(id responseObject))success
                       fail:(void(^)(NSError *error))fail
{
    NSString *requestURL = [self setRequestURLWithPath:url];
    [JMRequestNetWorkCache sharedMethod].isLoading = YES;
    if (!requestURL || requestURL.length == 0) {
        NSLog(@"url is not exist");
        return ;
    }
    [manager POST:requestURL parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [urls enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL result  =  [formData appendPartWithFileURL:[NSURL fileURLWithPath:urls[idx]] name:name[idx] fileName:fileName[idx] mimeType:mimeType error:nil];
            if (result) {
                NSLog(@"表单提交成功");
            if ([JMRequestNetWorkCache sharedMethod].isDebug)     NSLog(@"\n urls = %@ \n name = %@ \n fileName = %@, \n mineType = %@",urls,name,fileName,mimeType);
            }else {
                NSLog(@"表单提交成功");
            }
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"总进度 %lld  当前进度 %lld",uploadProgress.completedUnitCount,uploadProgress.totalUnitCount);
        progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
      if ([JMRequestNetWorkCache sharedMethod].isDebug)   NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",requestURL,params,responseObject);
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [JMRequestNetWorkCache sharedMethod].isLoading = NO;
        NSLog(@"error = %@",error.description);
        fail(error);
    }];
}



@end
