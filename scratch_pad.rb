require "google_drive"
require 'twilio-ruby'

session = GoogleDrive.saved_session(
  "./config/google_config_new.json",
  nil,
  ENV["GOOGLE_CLIENT_ID"],
  ENV["GOOGLE_CLIENT_SECRET"]
)

ws = session.spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE").worksheets[6]

guests = []

(2..3).each do |row|
  person = {
    number: ws[row, 1]
    name: ws[row, 2],
  }
  p "#{person[:name]} - #{person[:number]}"
  guests << person
end

@twilio = Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])
message = "❤️⭐️❤️⭐️❤️⭐️❤️⭐️

💌 Save the date!

Jen & Pete are delighted to invite you to their wedding

September 15th, 2018.

The Copse, Mill Lane, Kidmore End, Oxon, RG4 9HA.
Map 🗺 -> https://goo.gl/vZdmsp

The ceremony will begin at 2pm.

More details about accommodation and food will follow shortly!

Please text YES if you are saving the date and can join us. Text NO if sadly, you won't be able to be with us.

❤️⭐️❤️⭐️❤️⭐️❤️⭐️"

guests.each_with_index do |guest, index|
  row = (index + 1) + 1 # Headings are on row 1

  @twilio.api.account.messages.create(
    from: '+441915803991',
    to: guest[:number],
    body: message
  )

  ws[row, 3] = ws[row, 3].blank? ? 1 : ws[row, 3].to_i + 1
  ws.save
  ws.reload
end
