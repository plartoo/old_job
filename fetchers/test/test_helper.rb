$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")

require 'fetcher'
require 'test/unit'
require 'mocha'


require File.dirname(__FILE__) + '/../fetchers/victoriassecret/victoriassecret.rb'
Victoriassecret.log = Logger.new(STDOUT)
Victoriassecret.i18n_version = 'us'
