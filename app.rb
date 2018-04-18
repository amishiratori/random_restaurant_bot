require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'cgi'
require 'json'
require 'line/bot'


def client 
    @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = "0303e7c0bb92312850a7dc0d5dc0399d"
        config.channel_token = "Om1erElbI3CnOZO6VHux6P7FzOKza4a1JireDCTqleHIN5Wi/zgmqeO0v9cVEq7mPPzqMsu9YbY1Y24EeJe3ngGo5qTOOg5Iyi0lo9SjWbfQ1oZWQhfFOLT0XCMwcYo7Il8Ewp5GZX9kN+UkYSDfMwdB04t89/1O/w1cDnyilFU="
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
                                keyid: '833331ed51f16c521649f7a051db7332',
                                format: 'json',
                                latitude: latitude,
                                longitude: longitude
                            })
                            res = Net::HTTP.get_response(uri)
                            returned_json = JSON.parse(res.body)
                            response_stores =  returned_json["rest"]
                            selected_store = response_stores[rand(response_stores.length)]
                            
                            response_message = "チーズが選んだお店はこれ！\n" + selected_store["name"] + "\n" + selected_store["address"] + "\n" + selected_store["url_mobile"] 
                            
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