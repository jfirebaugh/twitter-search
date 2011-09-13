#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'cgi'
require 'csv'

get "/" do
  "Hello World!"
end

post "/" do
  QUERIES = ['toothache', 'tooth ache', 'dental pain', 'tooth pain']

  FIELDS = [
    ['id',         lambda {|s| s}],
    ['from_user',  lambda {|s| s}],
    ['created_at', lambda {|s| DateTime.parse(s).strftime('%F %T')}],
    ['geo',        lambda {|s| s['coordinates'].join(', ') rescue ''}],
    ['text',       lambda {|s| CGI.unescapeHTML(s)}]
  ]

  yesterday = Date.today - 1
  results = {}

  QUERIES.each do |query|
    puts "Searching for '#{query}' on #{yesterday.strftime('%a, %x')}"

    search = Twitter::Search.new.
      containing(query).
      result_type(:recent).
      since_date(yesterday).
      until_date(yesterday + 1).
      per_page(50)

    page = 0
    search.fetch

    begin
      puts "Page #{page += 1}"
      search.each do |result|
        results[result['id'].to_i] = result
      end
    end while search.fetch_next_page  
  end


  filename = "#{yesterday.to_s}.csv"

  CSV.open(filename, 'wb') do |csv|
    csv << FIELDS.map(&:first)
    results.each do |id, result|
      csv << FIELDS.map {|name, formatter| formatter.call(result[name])}
    end
  end

  puts "Finished. #{results.size} tweets written to #{filename}"
end
