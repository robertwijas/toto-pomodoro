
require 'rubygems'
require 'toto'
require 'coderay'
require 'rack/codehighlighter'

require './lib/pomodoro.rb'

Toto::Pomodoro.label_synonyms = [
  ['Awesome Project', 'p'],
  ['Email', 'e'],
  ['Writing', 'w']
]

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger
use Rack::Codehighlighter, :coderay, :markdown => true, :element => "pre>code", :pattern => /\A:::(\w+)\s*(\n|&#x000A;)/i, :logging => true

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
else
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['admin', 'admin']
  end
end

#
# Create and configure a toto instance
#
toto = Toto::Server.new do
  # Add your settings here
  # set [:setting], [value]
  # 
  # set :author,    ENV['USER']                               # blog author
  # set :title,     Dir.pwd.split('/').last                   # site title
  # set :root,      "index"                                   # page to load on /
  # set :date,      lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  # set :markdown,  :smart                                    # use markdown + smart-mode
  # set :disqus,    false                                     # disqus id, or false
  # set :summary,   :max => 150, :delim => /~/                # length of article summary and delimiter
  # set :ext,       'txt'                                     # file extension for articles
  # set :cache,      28800                                    # cache duration, in seconds

  set :url, ENV['TOTO_URL']
  set :date, lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
  set :ext, 'md'
end

run toto


