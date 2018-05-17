class BaseController < ApplicationController
  include Weather
  skip_before_action :verify_authenticity_token, only: [:incoming]

  def incoming
    @ws = drive_session
      .spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE")
      .worksheets[5]
    from_number = params['From'].downcase.tr("+", '')
    message_body = params['Body'].downcase
    response_body = ""

    guest_cell = @ws.cells.select { |key, value| value == from_number }
    if !guest_cell.blank?
      row = guest_cell.keys.first[0]
      Rails.logger.info "Found in #{guest_cell} - #{guest_cell.keys.first[0]}"

      if message_body.include?("yes")
        update_cell(row, 4, "yes")
        response_body = "🎉🎉 Thanks for confirming, we'll be in touch! 🎉🎉"
      elsif message_body.include?("no")
        update_cell(row, 4, "no")
        response_body = "Sorry to hear that, we still love you though! ❤️👫"
      elsif message_body == "numbers"
        @stats_ws = drive_session
          .spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE")
          .worksheets[7]
        confirmed_guests = @stats_ws['A2']
        declined_guests = @stats_ws['B2']
        no_response_guests = @stats_ws['C2']
        acceptance_rate = @stats_ws['D2']

        response_body = "R.S.V.P update:"
        response_body += "\n\nTotal accepted: #{confirmed_guests} ✅"
        response_body += "\nTotal declined: #{declined_guests} 🚫"
        response_body += "\nTotal no response: #{no_response_guests} 🤷‍♀️🤷‍♂️"
        response_body += "\nAcceptance rate: #{acceptance_rate} 🎉"
      elsif message_body == "weather"
        response_body = weather_forecast
      else
        Rails.logger.warn "Guest responded with: #{message_body}"
      end
      add_to_inbox!(from_number, message_body)
    else
      Rails.logger.info "Guest not found with number: #{from_number}"
    end

    if !response_body.blank?
      automated_response.message(body: response_body)
      render xml: automated_response.to_xml
    end
  end

  private

  def automated_response
    @automated_response ||= Twilio::TwiML::MessagingResponse.new
  end

  def drive_session
    @drive_session ||= GoogleDrive.saved_session(
      "./config/google_config_new.json",
      nil,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"]
    )
  end

  def update_cell(row, col, data)
    @ws[row, col] = data
    @ws.save
    @ws.reload
  end

  def add_to_inbox!(from_number, message_body)
    inbox = drive_session.spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE").worksheets[6]
    row = (inbox.num_rows + 1)
    Rails.logger.info "#{row} - #{message_body} - #{from_number}"
    inbox[row, 1] = message_body
    inbox[row, 2] = from_number
    inbox[row, 4] = Time.now
    inbox.save
    inbox.reload
  end
end
