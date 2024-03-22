require 'sinatra'
require 'line/bot'
require 'dotenv/load'

get '/' do
  'Choo Choo! Welcome to your Sinatra server 🚅'
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
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
      when Line::Bot::Event::MessageType::Text
        puts event
        text_from = event.message['text']
        text_to = text_from
        if text_from == 'スシ'
          text_to = "スプラシューターを選択しました"
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-2ae9ed24b7e47100a20a3cbe2db76db4')
        elsif text_from == 'ソイカス'
          text_to = 'ソイチューバーカスタムを選択しました'
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-b6143e6e08b9c3974583207969c10c26')
        elsif text_from == 'ヴァリフォイ'
          text_to = 'ヴァリアブルローラーフォイルを選択しました'
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-dcd8f5f536793e5aac8688d0d7896e8f')
        end
        message = {
          type: 'text',
          text: text_to
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  end

  # Don't forget to return a successful response
  "OK"
end