require 'sinatra'
require 'line/bot'
require 'dotenv/load'

richmenu_sushi = 'richmenu-ac64968c50dd58d0b72cea8b30cdf3c0'
richmenu_soycas = 'richmenu-9747b9b96f824442f0bea147d9bd3817'
richmenu_valifoi = 'richmenu-f73bacb4b9b10905e65def3527f35533'

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
          client.link_user_rich_menu(event['source']['userId'], richmenu_sushi)
        elsif text_from == 'ソイカス'
          text_to = 'ソイチューバーカスタムを選択しました'
          client.link_user_rich_menu(event['source']['userId'], richmenu_soycas)
        elsif text_from == 'ヴァリフォイ'
          text_to = 'ヴァリアブルローラーフォイルを選択しました'
          client.link_user_rich_menu(event['source']['userId'], richmenu_valifoi)
        elsif text_from == 'ランダム'
          buki_ary = [
            "スプラシューターを使ってみましょう。\n サブはキューバンボム、スペシャルはウルトラショットです。",
            "ソイチューバーカスタムを使ってみましょう。\n サブはタンサンボム、スペシャルはウルトラハンコです。",
            "ヴァリアブルローラーフォイルを使ってみましょう。\n サブはキューバンボム、スペシャルはスミナガシートです。"
          ]
          text_to = buki_ary.shuffle[0]
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
      elsif event['postback']['data'] == 'random'
        richmenu_ary = [
          richmenu_sushi,
          richmenu_soycas,
          richmenu_valifoi
        ]
        client.link_user_rich_menu(event['source']['userId'], richmenu_ary.shuffle[0])
      end
      # message = {
      #     type: 'text',
      #     text: event['postback']['data']
      #   }
      #   client.reply_message(event['replyToken'], message)
    end
  end

  # Don't forget to return a successful response
  "OK"
end