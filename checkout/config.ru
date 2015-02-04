require 'sinatra_app'

use Rack::ShowExceptions
use Rack::Logger

run SinatraApp.new
