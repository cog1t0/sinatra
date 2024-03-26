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
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-415ab9dd80d1d227cf4bd3da80b5cac3')
        elsif text_from == 'ソイカス'
          text_to = 'ソイチューバーカスタムを選択しました'
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-8e0cbf7a321ea3d76735d4027d48adc1')
        elsif text_from == 'ヴァリフォイ'
          text_to = 'ヴァリアブルローラーフォイルを選択しました'
          client.link_user_rich_menu(event['source']['userId'], 'richmenu-e98175308059225f4e439d161254e5b0')
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
    when Line::Bot::Event::Postback
      if event['postback']['data'] == 'reset'
        client.unlink_user_rich_menu(event['source']['userId'])
      end
      message = {
          type: 'text',
          text: event['postback']['data']
        }
        client.reply_message(event['replyToken'], message)
    end
  end

  # Don't forget to return a successful response
  "OK"
end