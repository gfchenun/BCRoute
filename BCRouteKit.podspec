

Pod::Spec.new do |s|
  s.name             = "BCRoute"
  s.version          = "1.0.0"
  s.summary          = "iOS Routekit"
  s.description      = <<-DESC.gsub(/^\s*\|?/,'')
                       An optional longer description of BCRoute

                       | * Markdown format.
                       | * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/gfchenun/BCRoute"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = { :type => 'MIT' }
  s.author           = { "chasel" => "chasel.chen@qq.com" }
  s.source           = { :git => "https://github.com/gfchenun/DCDBHandler.git", :branch => "develop" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.default_subspec = 'Core'

  #路由模块
  s.subspec 'Core' do |core|
      core.public_header_files = 'Core/**/BCRouteKit.h', 'Core/**/BCRouteKitPublic.h', 'Core/**/BCRouteUtils.h', 'Core/**/BCRouteRequest.h', 'Core/**/BCRouterProtocol.h', 'Core/**/BCRouter.h', 'Core/**/ZHWebPage.h'
      core.source_files = 'Core/**/*.{h,m}'
      core.resource_bundles = {
          'BCRouteKit' => ['Core/Assets/*.png','Core/Assets/*.jpg','Core/Assets/*.wav']
      }
      core.dependency 'BCFoundation'
      core.dependency 'BCUIKit'
  end
  
  
  
  
  
 

end
