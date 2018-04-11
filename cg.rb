
# based on Sam Ruby's https://gist.github.com/rubys/81f7246ff5e96b504643

require 'open-uri'
require 'nokogumbo'
require 'date'
require 'json'
require 'uri'
require 'net/http'


def main(lookback)

  results = {}
  index = URI.parse('http://www.w3.org/community/groups/')
  groups_page = Nokogiri::HTML5.get(index)
  groups_page.css('.maincolumn .cg').each do |group_div|
    group = {}
    group['name'] = group_div.css(".group-title")[0].text.strip
    participants_str = group_div.css(".group-meta .participants")[0]['data-participants']
    group['participants'] = participants_str.to_i
    group['home'] = index + group_div.css(".group-title a")[0]['href']
    group['id'] = group_div.css(".group-title a")[0]['id'].sub(/^#/, '')
    group['messages'] = fetch_list_messages(group['id'], lookback)
#    group['github_link'] = fetch_github_link(group['home'])
#    group['github_stats'] = fetch_github_stats(group['github_link']) if group['github_link']

    # Sumarise
    group['cluster'] = case group['name']
      when /semantic/i then 'semantic Web'
      when /rdf/i then 'semantic Web'
      when /ontology/i then 'semantic Web'
      when /schema/i then 'semantic Web'
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
      when /xpath/i then 'XML'
      when /mobile/i then 'mobile'
      when /open data/i then 'open data'
      when /w3c/i then 'W3C'
      when /process/i then 'process'
      when /voting/i then 'process'
      when /hydra/i then 'semantic Web'
      when /sparql/i then 'semantic Web'
      when /svg/i then 'SVG'
      when /gov/i then 'egov'
      when /media/i then 'media'
      when /audio/i then 'media'
      when /video/i then 'media'
      when /payment/i then 'payments'
    end
    results[group['id']] = group
  end

  data = {
    'date_gathered' => Date.today,
    'results' => results
  }
  return JSON.pretty_generate(data)
end

def fetch_list_messages(id, start)
  list = "http://lists.w3.org/Archives/Public/public-#{id}"
  messages = 0
  begin
    list_doc = Nokogiri::HTML5.get(list)
    list_doc.search('tbody tr').each do |tr|
      next if tr.at('td').text == 'n/a'
      date=Date.parse(tr.at('td').text)
      messages += tr.search('td').last.text.to_i if date > start
    end
  rescue
    warn "Problem checking mailing list for #{id}"
    messages = nil
  end
  return messages
end

def fetch_github_link(cg_home)
  begin
    cg_doc = Nokogiri::HTML5.get(cg_home)
  rescue
    warn "Problem checking home page <#{id}>"
  end
  issuetrack_icon = cg_doc.css('.issuetracking_icon')[0]
  github_link = nil
  if issuetrack_icon
    github_link = issuetrack_icon.css('a')[0]['href']
  end
  return github_link
end

def fetch_github_stats(github_link)
  begin
    github_uri = URI.parse(github_link)
  rescue
    warn "#{github_uri} is not a URI."
    return nil
  end
  if github_uri.hostname != "github.com"
    warn "#{github_link} is not a Github URI."
    return nil
  end
  segments = github_uri.path.split("/")
  while segments[0] == ""
    segments.shift
  end
  org = segments.shift
  is_org = true
  repo = nil
  if segments.length > 0
    is_org = false
    repo = segments.shift
  end
  if is_org
    api_path = "orgs/#{org}/repos"
  else
    api_path = "repos/#{org}/#{repo}"
  end
  begin
    api_uri = URI("https://api.github.com/#{api_path}")
    api_response = Net::HTTP.get(api_uri)
    api_json = JSON.parse(api_response)
  rescue
    warn "Problem with github API request for #{api_path}"
    return nil
  end
  if is_org
    api_json.sort_by! do |item|
        item['watchers_count'].to_i
    end 
    repo = api_json.last
  else
    repo = api_json
  end
  
  github_stats = {
    'repo_name' => repo['name'],
    'stargazers' => repo['stargazers_count'].to_i,
    'watchers' => repo['watchers_count'].to_i,
    'subscribers' => repo['subscribers_count'].to_i,
    'forks' => repo['forks_count'].to_i
  }
  return github_stats
end

#puts fetch_github_stats(fetch_github_link("https://www.w3.org/community/webassembly/"))
start = Date.today - 105
puts main(start)
