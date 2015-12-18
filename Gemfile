source "http://rubygems.org"

gemspec

gem 'refinerycms', '~> 3.0.0'
gem 'refinerycms-blog', git: 'https://github.com/refinery/refinerycms-blog', branch: 'master'
gem 'refinerycms-authentication-devise', '~> 1.0.4'
gem 'acts-as-taggable-on'
gem 'globalize'

gem 'shortcode', '0.1.2'

gem 'sqlite3'

group :development, :test do
  gem 'debase'
  gem 'ruby-debug-ide'
  gem 'rspec-rails'
  gem 'rspec-collection_matchers'
  gem 'factory_girl_rails'
  gem 'generator_spec'
  gem 'fantaskspec'

  gem 'guard-rspec'
  gem 'ffi'
  gem 'guard-bundler'
  gem 'fakeweb'
  gem 'libnotify' if  RUBY_PLATFORM =~ /linux/i

  require 'rbconfig'

  platforms :mswin, :mingw do
    gem 'win32console'
    gem 'rb-fchange', '~> 0.0.5'
    gem 'rb-notifu', '~> 0.0.4'
  end

  platforms :ruby do
    gem 'spork'
    gem 'guard-spork'

    unless ENV['TRAVIS']
      if RbConfig::CONFIG['target_os'] =~ /darwin/i
        gem 'rb-fsevent', '>= 0.3.9'
        gem 'growl',      '~> 1.0.3'
      end
      if RbConfig::CONFIG['target_os'] =~ /linux/i
        gem 'rb-inotify', '>= 0.5.1'
        gem 'libnotify',  '~> 0.1.3'
      end
    end
  end
end

