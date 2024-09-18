
Pod::Spec.new do |s|
  s.name             = 'JQPopView'
  s.version          = '0.0.2'
  s.summary          = 'JQPopView是一个iOS万能弹窗组件'
  s.description      = 'JQPopView 万能弹窗,功能强大,易于拓展,性能优化和内存控制让其运行更加的流畅和稳健, JQPopView的出现,可以让我们更专注弹窗页面的布局. 省心省力 ! 提高开发效率 !'
  s.homepage         = 'https://github.com/JJQ700/JQPopView.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JJQ700' => '378689628@qq.com' }
  s.source           = { :git => 'https://github.com/JJQ700/JQPopView.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'
  
  s.requires_arc = true
    s.default_subspec = 'Code'
  s.subspec 'Code' do |code|
      code.source_files = 'Source/**/*'
      code.frameworks = 'UIKit'
  end
  s.swift_version = '5.0'

end
