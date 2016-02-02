require 'bundler/setup'
require 'json'
require 'httpclient'
require './constants.rb'
require './models'

module FindApi
  CLIENT_ID = ENV['GITHUB_API_CLIENT_ID']
  CLIENT_SECRET = ENV['GITHUB_API_CLIENT_SECRET']

  def find_github_repository_by_lang (lang,page=1,per_page=100)
    response = find_get_json (sprintf(GITHUB::REPOSITORY_URL, lang, page, per_page, CLIENT_ID, CLIENT_SECRET))

    if HTTP_STATUS::OK == response.status
      (JSON.parse response.body).each do |key,value|
        if 'items' == key
          value.each_with_index do |json,i|

            user_info = find_get_json sprintf(GITHUB::USER_URL, json['owner']['login'], CLIENT_ID, CLIENT_SECRET)
            if HTTP_STATUS::OK == user_info.status
                          ClawlGithubRepository.new.register(json, lang, (JSON.parse user_info.body), i+=1)
            else
              p "error: #{user_info.status}, #{user_info.body}"
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

  def argv_run
    argv = ARGV
    p "language: #{argv[0]}"
    p "page: #{argv[1]}"
    p "per_page: #{argv[2]}"
    run(argv[0],argv[1],argv[2])
    #find_stackoverflow_questions_by_tag argv[0]
  end

  def run(language, page, per_page)
    find_github_repository_by_lang(language,page,per_page)
  end
end

# Requesu.new.argv_run
