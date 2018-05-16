class BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:incoming]

  def incoming
    @ws = drive_session.spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE").worksheets[6]
    from_number = params['From'].downcase.tr("+", '')
    message_body = params['Body'].downcase

    guest_cell = @ws.cells.select { |key, value| value == from_number }
    if !guest_cell.blank?
      row = guest_cell.keys.first[0]
      Rails.logger.info "Found in #{guest_cell} - #{guest_cell.keys.first[0]}"

      if message_body.include?("yes")
        update_cell(row, 4, "yes")
        automated_response.message(body: "🎉🎉 Thanks for confirming, we'll be in touch! 🎉🎉")
      elsif message_body.include?("no")
        update_cell(row, 4, "no")
        automated_response.message(body: "🎉🎉 Sorry to hear that, we still love you though! ❤️👫")
      else
        Rails.logger.warn "Guest responded with: #{message_body}"
      end
      add_to_inbox!(from_number, message_body)
    else
      Rails.logger.info "Guest not found with number: #{from_number}"
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
    inbox = drive_session.spreadsheet_by_key("1-DVANo0uHCxvv8CBpXY-DsbKvQhSbS9_jaUkmlASfEE").worksheets[7]
    row = (inbox.num_rows + 1)
    Rails.logger.info "#{row} - #{message_body} - #{from_number}"
    inbox[row, 1] = message_body
    inbox[row, 2] = from_number
    inbox[row, 4] = Time.now
    inbox.save
    inbox.reload
  end
end
