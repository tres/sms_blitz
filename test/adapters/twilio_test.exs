defmodule SmsBlitz.Adapters.TwilioTest do
  use ExUnit.Case
  alias SmsBlitz.Adapters.Twilio
  import Mock
  # This token is taken from the Twilio example documentation.
  @auth_sid "ACd2bd41c5a2524f439f82eea7c5ea5c80"
  @token "123123123123123123123123"

  describe "#authenticate" do
    test "authentication with account_sid" do
      expected = %Twilio.Config{
        uri: "https://api.twilio.com/2010-04-01/Accounts/#{@auth_sid}/Messages.json",
        account_sid: @auth_sid,
        token: @token
      }

      assert Twilio.authenticate({@auth_sid, @token}) == expected
    end
  end

  describe "#send_sms" do
    test "sending an sms successfullly" do
      auth = Twilio.authenticate({@auth_sid, @token})
      sid = "MMabdfcc43604446058f6608b1633cd52f"
      response = %{
        "error_message" => nil,
        "sid" => sid,
        "body" => "testing"
      }
      fake_response = %HTTPoison.Response{status_code: 201, body: Poison.encode!(response)}

      with_mock HTTPoison, [post: fn(_, _, _, _) -> {:ok, fake_response} end] do
        result =
          Twilio.send_sms(auth, from: "+4412345678910", to: "+4423456789101", message: "Testing")

        assert result == {:ok, %{id: sid, result_string: "testing", status_code: 201}}
      end
    end

    test "sending an sms and receiving an error" do
      auth = Twilio.authenticate({@auth_sid, @token})
      sid = "MMabdfcc43604446058f6608b1633cd52f"
      response = %{
        "error_message" => "testing error",
        "sid" => sid
      }

      fake_response = %HTTPoison.Response{status_code: 500, body: Poison.encode!(response)}
      with_mock HTTPoison, [post: fn(_, _, _, _) -> {:ok, fake_response} end] do
        result =
          Twilio.send_sms(auth, from: "+4412345678910", to: "+4423456789101", message: "Testing")

        assert result == {:error, %{id: sid, result_string: "testing error", status_code: 500}}
      end
    end
  end
end
