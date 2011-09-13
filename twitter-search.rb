#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'twitter'
require 'date'
require 'cgi'
require 'csv'

QUERIES = ['toothache', 'tooth ache', 'dental pain', 'tooth pain']

FIELDS = [
  ['id',         lambda {|s| s}],
  ['from_user',  lambda {|s| s}],
  ['created_at', lambda {|s| DateTime.parse(s).strftime('%F %T')}],
  ['geo',        lambda {|s| s['coordinates'].join(', ') rescue ''}],
  ['text',       lambda {|s| CGI.unescapeHTML(s)}]
]

get "/" do
<<-HTML
<!doctype html>
<html>
  <style>
    body { font-size: 120%; text-align: center; }
    input[type="text"] { width: 300px; }
  </style>
<head>
</head>
<body>
  <form action="/" method="post">
    <p>Enter twitter search terms, separated by commas:</p>
    <input type="text" name="q" placeholder="#{QUERIES.join(", ")}" value="#{params[:q]}" />
    
    <p>Search for tweets on this day:</p>
    <input type="date" name="d" value="#{Date.today - 1}">
    
    <input type="submit" name="submit" value="Search" />
  </form>
</body>
</html>
HTML
end

post "/" do
  date = Date.parse(params[:d])
  results = {}

  params[:q].split(",").each do |query|
    query.strip!

    puts "Searching for '#{query}' on #{date.strftime('%a, %x')}"

    search = Twitter::Search.new.
      containing(query).
      result_type(:recent).
      since_date(date).
      until_date(date + 1).
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

  puts "Finished #{results.size} tweets"

  attachment "#{params[:q]} (#{date.to_s}).csv"

  CSV.generate do |csv|
    csv << FIELDS.map(&:first)
    results.each do |id, result|
      csv << FIELDS.map {|name, formatter| formatter.call(result[name])}
    end
  end
end
