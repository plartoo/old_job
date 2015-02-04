#!/usr/bin/env ruby

# ouputs a list of the active fetcher names according the Launcher class
# usage: list-fetchers.rb

require 'rubygems'
require 'lib/launcher'

ENV['RAILS_ENV'] ||= "fb"

fetchers = Launcher.new.fetchers
order_to_run = fetchers.sort_by{|x| x[:priority] || 0}.reverse
puts order_to_run.map{|x| x[:name]}.join("\n")
