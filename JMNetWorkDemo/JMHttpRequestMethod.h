//
//  JMHttpRequestMethod.h
//  ssss
//
//  Created by 雷建民 on 16/9/25.
//  Copyright © 2016年 雷建民. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *该类默认只要导入头文件就会自动检测网络状态，且会在没有网络和未知网络的时候，自动从本地数据库中读取缓存。
 *数据库网络缓存是基于猿题库公司对FMDB进行封装的轻量级 key-value 存储框架
 *详情请见 https://github.com/yuantiku/YTKKeyValueStore
 *对该类如有疑问可以拉个issues
 */
@interface JMHttpRequestMethod : NSObject

typedef NS_ENUM(NSUInteger, JMRequestSerializer) {
    JMRequestSerializerJSON,     // 设置请求数据为JSON格式
    JMRequestSerializerPlainText    // 设置请求数据为普通 text/html
};

typedef NS_ENUM(NSUInteger, JMResponseSerializer) {
    JMResponseSerializerJSON,    // 设置响应数据为JSON格式
    JMResponseSerializerHTTP,    // 设置响应数据为二进制格式
    JMResponseSerializerXML      // 设置响应数据为XML格式
};


/**
 单例方法
 
 @return self
 */
+ (JMHttpRequestMethod *)sharedMethod;



@property (nonatomic ,assign) BOOL isLoading;
@property (nonatomic ,assign) BOOL isDebug;  //是否打印 请求信息。 默认YES
#pragma mark - 程序入口设置网络请求头API  一般调用一次即可

/**
 创建网络缓存 数据库
 */
- (void)creatNetWorkDataBase;

/**
 设置网络请求的baseUrl
 
 @param baseUrl 服务器的baseUrl
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;

/**
 设置 请求和响应类型和超时时间
 
 @param requestType  默认为请求类型为JSON格式
 @param responseType 默认响应格式为JSON格式
 @param timeOut      请求超时时间 默认为20秒
 */
+(void)setTimeOutWithTime:(NSTimeInterval)timeOut
              requestType:(JMRequestSerializer)requestType
             responseType:(JMResponseSerializer)responseType;

/**
 设置 请求头
 
 @param httpBody 根据服务器要求 配置相应的请求体
 */
+ (void)setHttpBodyWithDic:(NSDictionary *)httpBody;

#pragma mark - 网络工具 API
/**
 获取当前的网络状态
 
 @return YES 有网  NO 没有联网
 */
+(BOOL)getCurrentNetWorkStatus;

/**
 获取网络缓存 文件大小
 
 @return size  单位M 默认保留两位小数 如: 0.12M
 */
+ (NSString *)fileSizeWithDBPath;
/**
 清除所有网络缓存
 */
+ (void)cleanNetWorkRefreshCache;

#pragma mark -  GET 请求API

/**
 GET 请求  不用传参 API
 
 @param url          请求的url
 @param refreshCache 是否对该页面进行缓存
 @param success      请求成功回调
 @param fail         请求失败回调
 
 
 */
+ (void )getWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail;

/**
 GET 请求 传参数的API
 
 @param url          请求的url
 @param refreshCache 是否对该页面进行缓存
 @param params       请求数据向服务器传的参数
 @param success        请求成功回调
 @param fail         请求失败回调
 
 
 */
+ (void )getWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
             params:(NSDictionary *)params
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail;

/**
 GET 请求 带有进度回调的 API
 
 @param url               请求的url
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
               fail:(void(^)(NSError *error))fail;


#pragma mark -  POST 请求API


/**
 POST 请求API
 
 @param url          请求的url
 @param refreshCache 是否对该页面进行缓存
 @param params       请求数据向服务器传的参数
 @param success      请求成功回调
 @param fail         请求失败回调
 
 
 */
+ (void )postWithUrl:(NSString *)url
        refreshCache:(BOOL)refreshCache
              params:(NSDictionary *)params
             success:(void(^)(id responseObject))success
                fail:(void(^)(NSError *error))fail;


/**
 POST 请求 带有进度回调的 API
 
 @param url               请求的url
 @param refreshCache 是否对该页面进行缓存
 @param params       请求数据向服务器传的参数
 @param progress     请求进度回调
 @param success      请求成功回调
 @param fail         请求失败回调
 
 
 */
+ (void)postWithUrl:(NSString *)url
       refreshCache:(BOOL)refreshCache
             params:(NSDictionary *)params
           progress:(void(^)(int64_t bytesRead, int64_t totalBytesRead))progress
            success:(void(^)(id responseObject))success
               fail:(void(^)(NSError *error))fail;




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
               fail:(void(^)(NSError *error))fail;



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
                  fail:(void(^)(NSError *error))fail;






/**
 
 
 @param url
 @param param
 @param fileUrl
 @param name
 @param fileName
 @param progress
 @param success
 @param fail
 */

/**
 表单提交 单图上传接口

 @param url 请求url
 @param param 请求参数
 @param fileUrl 请求图片url路径
 @param name 后台图片名字字段
 @param fileName 图片名字
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
                       fail:(void(^)(NSError *error))fail;

/**
 表单提交 多图上传接口
 
 @param url 请求url
 @param params 请求参数
 @param urls 求图片url路径数组
 @param name 后台字段数组
 @param fileName 图片名字数组
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
                       fail:(void(^)(NSError *error))fail;

@end
