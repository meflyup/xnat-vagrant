#!/usr/bin/ruby
require 'yaml'

destination = ARGV[0]
ARGV.shift
hash = eval ARGV.join ' '
hash.each { |key, params|
  `#{params['type']} clone #{params['url']} #{destination}/#{key}`
}