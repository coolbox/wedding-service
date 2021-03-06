desc 'set of console tasks for ops team'
namespace :sms do
  desc 'Send an SMS to all guests to save the date'
  task :save_the_date => [:environment] do |t|
    session = GoogleDrive.saved_session(
      "./config/google_config_new.json",
      nil,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"]
    )

    ws = session.spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE").worksheets[5]

    guests = []
    (2..ws.rows.length).each do |row|
      person = {
        number: ws[row, 1],
        name: ws[row, 2],
        message_count: ws[row, 3],
      }

      guests << person if person[:message_count].to_i < 1
    end

    @twilio = Twilio::REST::Client.new(ENV["TWILIO_SID"], ENV["TWILIO_TOKEN"])
    guests.each_with_index do |guest, index|
      row = (index + 1) + 1 # Headings are on row 1

      message =
      <<~EOS
        🌺🍃🌺👰🤵🌺🍃🌺

        Dear #{guest[:name]},

        💌 Save the date!

        Jenny Baskerville and Peter Roome are delighted to invite you to their wedding.

        Saturday 15th September, 2018.

        The Copse, Mill Lane, Kidmore End, Oxon, RG4 9HA. Map 🗺 -> https://goo.gl/vZdmsp.

        The ceremony will begin at 2pm. We are sorry we are unable to accommodate children.

        Please reply YES if you are saving the date and can join us.

        Reply NO if sadly you have something better to do 😉.

        #roomerville

        🌺🍃🌺👰🤵🌺🍃🌺
      EOS

      begin
        @twilio.api.account.messages.create(
          from: '+441915803991',
          to: guest[:number],
          body: message
        )

        ws[row, 3] = ws[row, 3].blank? ? 1 : ws[row, 3].to_i + 1
        ws.save
        ws.reload
        p "Sent: #{guest[:name]} - #{guest[:number]}"
      rescue => e
        Rails.logger.error(
          "name=#{guest[:name]}" +
          "number=#{guest[:number]}" +
          "error=#{e.message}"
        )
      end
    end
  end
end
