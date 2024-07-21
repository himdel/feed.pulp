#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'cgi';
require 'nokogiri'
require 'open-uri'

FEED_TITLE = "Pulp Changes"
FEED_SOURCES = [
  "https://docs.pulpproject.org/pulpcore/changes.html",
  "https://docs.pulpproject.org/pulp_ansible/changes.html",
  "https://docs.pulpproject.org/pulp_container/changes.html",
]

def items
  sections = FEED_SOURCES.map do |source|
    what = source.split('/')[-2]
    list = Nokogiri::HTML(URI.open(source)) / "#changelog"

    (list / "> section").map do |section|
      title = (section / "> h2").children.first.to_s
      date = if title.match?(/\(\d{4}-\d{2}-\d{2}\)/) then title.sub(/^.*\((.*)\).*$/, '\1') else nil end

      {
        :title => what + ' ' + title,
        :date => date,
        :href => source + '#' + CGI.escape(title),
        :html => section.to_html,
      }
    end
  end.flatten.sort_by { |x| x[:date] || '' }.reverse
end

def json_feed(items)
  require 'json'

  JSON.pretty_generate({
    :version => "https://jsonfeed.org/version/1",
    :home_page_url => FEED_SOURCES[0],
    :title => FEED_TITLE,
    :items => items.map do |item|
      {
        :id => item[:href],
        :url => item[:href],
        :title => item[:title],
        :content_html => item[:html],
        :date_published => item[:date],
      }
    end,
  })
end

puts json_feed(items)
