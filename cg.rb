
# based on Sam Ruby's https://gist.github.com/rubys/81f7246ff5e96b504643

require 'nokogumbo'
require 'date'
require 'json'
require 'uri'

start = Date.today - 105

results = {}
index = URI.parse('http://www.w3.org/community/groups/')
groups_page = Nokogiri::HTML5.get(index)
groups_page.search('div.groupa.cg').each do |group_div|
  group = {}
  group['name'] = group_div.css("header a")[0].text.strip
  participants_str = group_div.css("header em.groupParticipants").text.sub(/ participants/, '')
  group['participants'] = participants_str.to_i
  group['home'] = index + group_div.css("* a.link-home")[0]['href']
  id = group_div.css("header a")[0]['href'].sub(/^#/, '')
  list = "http://lists.w3.org/Archives/Public/public-#{id}"
  doc = Nokogiri::HTML5.get(list)
  group['messages'] = 0
  doc.search('tbody tr').each do |tr|
    next if tr.at('td').text == 'n/a'
    date=Date.parse(tr.at('td').text)
    group['messages'] += tr.search('td').last.text.to_i if date > start
  end
  group['cluster'] = case group['name']
    when /semantic/i then 'semantic Web'
    when /rdf/i then 'semantic Web'
    when /ontology/i then 'semantic Web'
    when /accessible/i then 'a11y'
    when /accessibility/i then 'a11y'
    when /wcag/i then 'a11y'
    when /linked/i then 'semantic Web'
    when /owl/i then 'semantic Web'
    when /browser/i then 'browser'
    when /html/i then 'HTML'
    when /hypertext/i then 'HTML'
    when /xml/i then 'XML'
    when /xforms/i then 'XML'
    when /mobile/i then 'mobile'
    when /open data/i then 'open data'
    when /w3c/i then 'W3C'
    when /process/i then 'process'
    when /voting/i then 'process'
    when /hydra/i then 'semantic Web'
    when /svg/i then 'SVG'
    when /gov/i then 'egov'
    when /media/i then 'media'
    when /audio/i then 'media'
    when /video/i then 'media'
  end
  results[id] = group
end

data = {
  'date_gathered' => Date.today,
  'results' => results
}

puts JSON.pretty_generate(data)