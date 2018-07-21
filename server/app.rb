require "json"
require "net/http"
require "sinatra"

API_KEY = ENV.fetch "AIRTABLE_API_KEY"
TABLE_URL = URI("https://api.airtable.com/v0/appOOHY2yfP6zFXzf/Webhook")

def on_sale
  payload = JSON.parse(request.body.read)
  yield payload["resource"] if payload["event_type"] == "PAYMENT.SALE.COMPLETED"
end

post "/webhook" do
  on_sale do |resource|
    custom = JSON.parse resource["custom"]
    record = {
      "fields" => {
        "Transaction ID" => resource["id"],
        "Start" => resource["create_time"],
        "Room" => custom.first,
        "Art" => custom.last.to_s,
      }
    }
    Net::HTTP.start(TABLE_URL.hostname, TABLE_URL.port, use_ssl: true) do |http|
      response = http.post(
        TABLE_URL.path,
        record.to_json,
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{API_KEY}")
    end
  end
end
