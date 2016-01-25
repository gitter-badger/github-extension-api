require 'bundler/setup'
require 'json'
require 'httpclient'
require 'active_record'
require 'yaml'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class ClawlGithubRepository < ActiveRecord::Base
  def self.update_duplicate
    create_table :on_duplicates do |t|
    end
  end
end

class HTTP_STATUS
  OK = 200
end

module FindApi
  def find_github_repository_by_lang lang
    response = find_get_json "https://api.github.com/search/repositories?q=language:#{lang}&sort=stars&order=desc"

    if HTTP_STATUS::OK == response.status
      json_arr = JSON.parse response.body
      json_arr.each do |key,value|
        if 'items' == key
          value.each_with_index do |json,i|
	          ct = ClawlGithubRepository.where(
	            github_id: json['id'],
	            language: lang).take
            i+=1
	          if ct.nil?
	            ct = ClawlGithubRepository.create(
	            github_id: json['id'],
	            language: lang,
	            response: json)
              p "success: No.#{i} insert github_id=#{json['id']}"
	          else
              ct.response = json
	            ct.save
              p "success: No.#{i} update github_id=#{json['id']}"
            end
	        end
        end
      end
    else
      p "error: #{response.status}, #{response.body}"
    end
  end

  def find_stackoverflow_questions_by_tag tag
    response = find_get_json "https://api.stackexchange.com/2.2/questions?page=1&pagesize=100&order=desc&sort=votes&tagged=#{tag}&site=ja.stackoverflow&filter=withbody"

    if HTTP_STATUS::OK == response.status
      json_arr = JSON.parse(response.body, quirks_mode: true)
      p json_arr
    else
      p "error: #{response.status}, #{response.body}"
    end
  end

  def find_get_json uri
    http = HTTPClient.new
    http.get uri
  end
end

class Request
  include FindApi

  def main
    argv = ARGV
    find_github_repository_by_lang argv[0]
    #find_stackoverflow_questions_by_tag argv[0]
  end
end

Request.new.main