Pod::Spec.new do |s|
    s.name         = 'JMRequestNetWorkCache'
    s.version      = '0.1'
    s.summary      = '网络请求封装'
    s.homepage     = 'https://github.com/leijianmin/JMRequestNetWorkCache'
    s.description  = <<-DESC
                                      网络请求封装之便携式网络缓存
                   DESC
    s.license      = 'MIT'
    s.authors      = {'leijianmin': 'ljm774256119@gamil.com'}
    s.platform     = :ios, '7.0'
    s.source       = {:git => 'https://github.com/leijianmin/JMRequestNetWorkCache.git', :tag => s.version}
    s.source_files = 'JMNetWorkDemo/JMNetWorkTest/JMRequestNetWorkCache/*.{h,m}'
    s.dependency "AFNetworking", "~> 3.0"
    s.requires_arc = true
end