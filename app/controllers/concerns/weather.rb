module Weather
  extend ActiveSupport::Concern

  def weather_forecast
    weather = get_weather
    forecast = "Weather forecast for the big day… 🥁"
    forecast += "\n\n#{weather[:summary]} #{weather[:icon]}"
    forecast += "\nMax temp: #{weather[:max_temp]}C"
    forecast += "\nMin temp: #{weather[:min_temp]}C"

    return forecast
  end

  def get_weather
    url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_WEATHER_SECRET_KEY"]}/51.5012661,-1.0004566000000068,1537016400?exclude=currently,minutely,hourly,flags&units=auto"
    response = HTTParty.get(url)
    weather = {
      summary: response.parsed_response["daily"]["data"][0]["summary"],
      max_temp: response.parsed_response["daily"]["data"][0]["temperatureHigh"],
      min_temp: response.parsed_response["daily"]["data"][0]["temperatureLow"],
      icon: weather_icon(response.parsed_response["daily"]["data"][0]["icon"])
    }
    return weather
  end

  def weather_icon(icon)
    weather = {
      "clear-day" => "☀️",
      "clear-night" => "🌚",
      "rain" => "☔️",
      "snow" => "🌨",
      "sleet" => "💦",
      "wind" => "💨",
      "fog" => "🌁",
      "cloudy" => "☁️",
      "partly-cloudy-day" => "🌥",
      "partly-cloudy-night" => "🌑",
      "hail" => "🌧",
      "thunderstorm" => "⛈",
      "tornado" => "🌪",
    }
    return weather[icon].blank? ? "" : weather[icon]
  end
end
