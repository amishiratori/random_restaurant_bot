require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'cgi'
require 'json'
require 'line/bot'


def client 
    @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV['LINE_CHANNEL_SECRET']
        config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
end

post '/callback' do
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each do |event|
        case event
            when Line::Bot::Event::Message
                case event.type
                    when Line::Bot::Event::MessageType::Location
                            latitude = event.message["latitude"]
                            longitude = event.message["longitude"]
                            uri = URI('http://api.gnavi.co.jp/RestSearchAPI/20150630/')
                            uri.query = URI.encode_www_form({
                                keyid: ENV['GNAVI_KEY'],
                                format: 'json',
                                latitude: latitude,
                                longitude: longitude
                            })
                            res = Net::HTTP.get_response(uri)
                            returned_json = JSON.parse(res.body)
                            response_stores =  returned_json["rest"]
                            if respose_stores = ""
                                response_message = "近くにお店が見つかりませんでした..."
                            else
                                selected_store = response_stores[rand(response_stores.length)]
                                response_message = "チーズが選んだお店はこれ！\n" + selected_store["name"] + "\n" + selected_store["address"] + "\n" + selected_store["url_mobile"] 
                            end

                            message = {
                              type: 'text',
                              text: response_message
                            }
                            
                            client.reply_message(event['replyToken'], message)
                            
                            img = {
                                type: 'image',
                                originalContentUrl: selected_store["img_url"]["shop_image1"],
                                previewImageUrl: selected_store["img_url"]["shop_image1"]
                            }
                            
                            client.reply_message(event['replyToken'], img)
                    else
                        message = {
                              type: 'text',
                              text: '位置情報を送信してね！'
                            }
                            client.reply_message(event['replyToken'], message)
                end
        end
    end
end