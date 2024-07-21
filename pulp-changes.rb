#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'cgi';
require 'nokogiri'
require 'open-uri'

FEED_TITLE = "Pulp Changes"
FEED_SOURCES = [
  "https://pulpproject.org/pulpcore/changes/",
  "https://pulpproject.org/pulp_ansible/changes/",
  "https://pulpproject.org/pulp_container/changes/",
  "https://pulpproject.org/pulp_deb/changes/",
  "https://pulpproject.org/pulp_gem/changes/",
  "https://pulpproject.org/pulp_maven/changes/",
  "https://pulpproject.org/pulp_ostree/changes/",
  "https://pulpproject.org/pulp_python/changes/",
  "https://pulpproject.org/pulp_rpm/changes/",
  "https://pulpproject.org/pulp-operator/changes/",
  "https://pulpproject.org/pulp-cli/changes/",
]

def items
  sections = FEED_SOURCES.map do |source|
    what = source.split('/')[-2]
    list = Nokogiri::HTML(URI.open(source)) / ".md-content"

    # remove all those ¶
    list.search('.headerlink').remove

    items = []
    item = nil
    (list / "> article > *").map do |child|
      # [start of version
      if child.name == 'h2'
        version = child[:id]
        title = child.children.first.to_s
        date = if title.match?(/\(\d{4}-\d{2}-\d{2}\)/) then
          title.sub(/^.*\((.*)\).*$/, '\1')
        else
          nil
        end
        child = nil

        item = {
          :title => what + ' ' + title,
          :date => date,
          :href => source + '#' + CGI.escape(version),
          :html => '',
        }

        items << item
      end
      # end of version)
      if child and child.name == 'hr'
        item = nil
      end

      item[:html] << child.to_html unless item.nil? or child.nil?
    end
    items
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
